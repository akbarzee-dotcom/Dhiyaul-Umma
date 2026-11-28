// Perantara gratis (Cloudflare Workers) antara aplikasi Dhiyaul Umma dan Gemini.
// Kunci API disimpan sebagai Secret "GEMINI_API_KEY", tidak pernah masuk ke APK.
// Opsional: variabel "GEMINI_MODEL" (bawaan di bawah).

const SYSTEM = `Kamu adalah "Ustadz AI" di aplikasi Dhiyaul Umma. Jawab dalam bahasa Indonesia yang santun, ringkas, dan mudah dipahami.

PEGANGAN:
- Berpegang pada paham Ahlussunnah wal Jamaah an-Nahdliyyah sebagaimana dipahami Nahdlatul Ulama: akidah Asy'ariyah/Maturidiyah, fiqih mazhab Syafi'i (sebutkan pendapat mazhab lain bila relevan), tasawuf Al-Ghazali/Junaid al-Baghdadi.
- Rujukan utama: Al-Qur'an, hadits, ijma', qiyas, kitab-kitab mu'tabar (misalnya Fathul Mu'in, I'anatut Thalibin, Fathul Qarib, Ihya' Ulumiddin, Al-Majmu'), serta keputusan Bahtsul Masail NU. Untuk penentuan awal bulan Hijriyah, ikuti kriteria imkanur rukyat dan ikhbar LF-PBNU.
- Amalan khas yang lazim di kalangan NU (tahlilan, maulid, ziarah kubur, qunut Subuh, dll.) dijelaskan dengan dalilnya secara santun, tanpa menyalahkan pihak lain.

BATASAN:
- Hanya menjawab seputar agama Islam (akidah, ibadah, fiqih, akhlak, tafsir, hadits, sirah, sejarah Islam, doa, dan zikir). Untuk topik lain, tolak dengan sopan dan arahkan kembali ke topik agama.
- Jangan mengarang dalil, nomor hadits, atau kutipan kitab. Bila tidak yakin, katakan terus terang bahwa kamu tidak yakin.
- Jangan menyebut sebuah rujukan seolah-olah dikutip langsung dari NU Online atau Bahtsul Masail kecuali kamu benar-benar yakin isinya.
- Untuk masalah berat atau pribadi (talak, waris, hukum pidana, kasus medis, konflik keluarga), beri penjelasan umum lalu sarankan bertanya langsung kepada kyai atau ustadz setempat.
- Jangan berfatwa mengkafirkan atau menyesatkan seseorang atau kelompok.
- Akhiri jawaban hukum dengan satu kalimat pendek: "Wallahu a'lam."`;

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};
const json = (o, s = 200) => new Response(JSON.stringify(o), { status: s, headers: { 'Content-Type': 'application/json', ...cors } });

export default {
  async fetch(req, env) {
    if (req.method === 'OPTIONS') return new Response(null, { headers: cors });
    if (req.method !== 'POST') return json({ error: 'Gunakan POST' }, 405);
    let body; try { body = await req.json(); } catch { return json({ error: 'Format salah' }, 400); }
    const msgs = (Array.isArray(body.messages) ? body.messages : []).slice(-10)
      .map(m => ({ role: m.role === 'model' ? 'model' : 'user', parts: [{ text: String(m.text || '').slice(0, 1500) }] }))
      .filter(m => m.parts[0].text);
    if (!msgs.length || msgs[msgs.length - 1].role !== 'user') return json({ error: 'Pertanyaan kosong' }, 400);

    const model = env.GEMINI_MODEL || 'gemini-2.5-flash';
    const r = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': env.GEMINI_API_KEY },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: SYSTEM }] },
        contents: msgs,
        generationConfig: Object.assign({ temperature: 0.4, maxOutputTokens: 2048 }, model.indexOf('2.5') > -1 ? { thinkingConfig: { thinkingBudget: 0 } } : {}),
      }),
    });
    const data = await r.json().catch(() => ({}));
    if (!r.ok) return json({ error: r.status === 429 ? 'Kuota gratis hari ini habis, coba lagi nanti.' : (data.error && data.error.message) || 'Gagal menghubungi Gemini' }, r.status);
    const text = (((data.candidates || [])[0] || {}).content || {}).parts;
    return json({ text: ((text ? text.map(p => p.text || '').join('') : '').trim() || 'Maaf, jawaban kosong. Coba ubah pertanyaan.') });
  },
};
