import { CreateMLCEngine } from "https://esm.run/@mlc-ai/web-llm";

let engine = null;
let loadingCallback = null;

// Locks
let initializing = false;
let initialized = false;
let progressFrozen = false;

// Conversation memory
let systemPrompt = null;
let messages = [];

// Set loading callback (for Flutter to show progress)
globalThis.setLLMLoadingCallback = (cb) => {
  loadingCallback = cb;
};

// Initialize LLM with optional system prompt
globalThis.initLLM = async (resumeContext) => {
  if (initialized || initializing) return;

  initializing = true;

  // Create engine with cache enabled
  engine = await CreateMLCEngine("Llama-3.2-1B-Instruct-q4f16_1-MLC", {
    cache: true, // store in IndexedDB
    initProgressCallback: (report) => {
      if (progressFrozen) return;

      const percent = Math.round(report.progress * 100);
      loadingCallback?.(percent);

      if (percent >= 100) {
        progressFrozen = true;
        console.log("✅ Progress frozen at 100%");
      }
    },
  });

  // Store system prompt
  systemPrompt = resumeContext;
  messages = []; // reset chat memory

  initialized = true;
  initializing = false;
  globalThis.__LLM_READY__ = true;

  console.log("🟢 WebLLM READY");
};

// Ask the LLM a question
globalThis.askLLM = async (prompt) => {
  if (!engine) throw new Error("LLM not ready");

  // Optional: auto language detection
  const isIndo = /[\u0400-\u04FF]|(apa|siapa|kamu|tentang|cerita)/i.test(prompt);

  const userMessage = {
    role: "user",
    content: prompt,
  };

  messages.push(userMessage);

  const res = await engine.chat.completions.create({
    messages: [
      { role: "system", content: systemPrompt },
      ...messages,
    ],
  });

  const reply = res.choices[0].message.content;

  messages.push({
    role: "assistant",
    content: reply,
  });

  return reply;
};
