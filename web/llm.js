import { CreateMLCEngine } from "https://esm.run/@mlc-ai/web-llm";

let engine = null;
let loadingCallback = null;

// =======================
// 🔒 LOCKS
// =======================
let initializing = false;
let initialized = false;
let progressFrozen = false;

// =======================
// 💬 MEMORY
// =======================
let systemPrompt = null;
let messages = [];

// =======================
// 🎎 MAID VOICE CONFIG (JP ONLY)
// =======================
const MAID_VOICE_LANG = "ja-JP";

let voiceConfig = {
  lang: MAID_VOICE_LANG, // 🔒 ALWAYS JAPANESE
  rate: 1.05,
  pitch: 1.3,
  volume: 1.0,
};

// =======================
// 🌍 LANGUAGE DETECTION (TEXT ONLY)
// =======================
function detectLanguage(text) {
  // Japanese
  if (/[\u3040-\u30FF\u4E00-\u9FAF]/.test(text)) {
    return "ja";
  }

  // Indonesian
  if (/\b(apa|siapa|kamu|tentang|cerita|tolong|jelaskan|buatkan|bagaimana)\b/i.test(text)) {
    return "id";
  }

  // Default English
  return "en";
}

// =======================
// 🎤 SPEECH RECOGNITION
// =======================
let recognition = null;
let listening = false;

if ("webkitSpeechRecognition" in window) {
  recognition = new webkitSpeechRecognition();
  recognition.continuous = false;
  recognition.interimResults = false;

  recognition.onresult = (event) => {
    const transcript = event.results[0][0].transcript;
    globalThis.onSpeechResult?.(transcript);
  };

  recognition.onend = () => {
    listening = false;
  };
}

// =======================
// 🔊 TEXT TO SPEECH (JP MAID)
// =======================
function speak(text, emotion = "neutral") {
  if (!("speechSynthesis" in window)) return;

  window.speechSynthesis.cancel();

  const utterance = new SpeechSynthesisUtterance(text);

  const emotionPitchMap = {
    happy: 1.45,
    excited: 1.55,
    neutral: 1.3,
    calm: 1.15,
    serious: 1.0,
  };

  utterance.lang = MAID_VOICE_LANG; // 🔒 FORCE JP
  utterance.rate = voiceConfig.rate;
  utterance.pitch = emotionPitchMap[emotion] ?? voiceConfig.pitch;
  utterance.volume = voiceConfig.volume;

  window.speechSynthesis.speak(utterance);
}

// =======================
// 🌍 GLOBAL API
// =======================
globalThis.setLLMLoadingCallback = (cb) => {
  loadingCallback = cb;
};

globalThis.startListening = () => {
  if (!recognition || listening) return;
  listening = true;

  // Let browser auto-detect speech language
  recognition.lang = ""; 
  recognition.start();
};

globalThis.stopListening = () => {
  recognition?.stop();
};

globalThis.stopSpeaking = () => {
  window.speechSynthesis.cancel();
};

// =======================
// 🚀 INIT LLM
// =======================
globalThis.initLLM = async (resumeContext) => {
  if (initialized || initializing) return;

  initializing = true;

  engine = await CreateMLCEngine(
    "Llama-3.2-1B-Instruct-q4f16_1-MLC",
    {
      cache: true,
      initProgressCallback: (report) => {
        if (progressFrozen) return;

        const percent = Math.round(report.progress * 100);
        loadingCallback?.(percent);

        if (percent >= 100) {
          progressFrozen = true;
          console.log("✅ WebLLM READY");
        }
      },
    }
  );

  systemPrompt = resumeContext;
  messages = [];

  initialized = true;
  initializing = false;
  globalThis.__LLM_READY__ = true;
};

// =======================
// 💬 ASK SAKURA
// =======================
globalThis.askLLM = async (prompt, options = {}) => {
  if (!engine) throw new Error("LLM not ready");

  // 🔍 Detect language (TEXT ONLY)
  const detectedLang = detectLanguage(prompt);

  // (Optional) hint model by prepending language intent
  let finalPrompt = prompt;
  if (detectedLang === "id") {
    finalPrompt = "Jawab dalam Bahasa Indonesia:\n" + prompt;
  } else if (detectedLang === "en") {
    finalPrompt = "Answer in English:\n" + prompt;
  }
  // Japanese → no hint needed

  messages.push({ role: "user", content: finalPrompt });

  const res = await engine.chat.completions.create({
    messages: [
      { role: "system", content: systemPrompt },
      ...messages,
    ],
  });

  const reply = res.choices[0].message.content;

  messages.push({ role: "assistant", content: reply });

  // 🔊 ALWAYS SPEAK IN JAPANESE MAID VOICE
  if (options.speak !== false) {
    speak(reply, options.emotion ?? "neutral");
  }

  return reply;
};
