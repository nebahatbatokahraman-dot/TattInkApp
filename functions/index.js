/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest, onCall} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {GoogleGenerativeAI} = require("@google/generative-ai");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Gemini AI Configuration
// NOT: Flutter paketi v1beta API kullanıyor, bu yüzden gemini-pro kullanıyoruz
// Cloud Functions'da @google/generative-ai paketi v1 API kullanabilir
const GEMINI_MODEL_NAME = "gemini-pro"; // v1beta uyumluluğu için
// Alternatif: Eğer Cloud Functions v1 API kullanıyorsa "gemini-1.5-flash" kullanılabilir

/**
 * Chat mesajını Gemini AI ile analiz et
 * Bu fonksiyon chat mesajlarını moderasyon için analiz eder
 */
exports.analyzeChatMessage = onCall(async (request) => {
  try {
    const {message, apiKey} = request.data;
    
    if (!message) {
      throw new Error("Mesaj içeriği gerekli");
    }
    
    if (!apiKey) {
      throw new Error("Gemini API anahtarı gerekli");
    }

    // GoogleGenerativeAI instance oluştur
    const genAI = new GoogleGenerativeAI(apiKey);
    
    // Güncellenmiş model adı ile model oluştur
    const model = genAI.getGenerativeModel({model: GEMINI_MODEL_NAME});

    // Prompt hazırla
    const prompt = `Bu mesajı analiz et ve aşağıdaki kriterlere göre değerlendir:
1. Mesaj uygunsuz içerik (küfür, nefret söylemi, spam) içeriyor mu?
2. Mesaj kişisel bilgi (telefon, email, adres) paylaşıyor mu?
3. Mesaj dış platform linkleri içeriyor mu?

Mesaj: "${message}"

Sadece JSON formatında cevap ver:
{
  "isSafe": true/false,
  "reason": "Neden güvenli/güvensiz olduğu açıklaması",
  "violations": ["ihlal1", "ihlal2"]
}`;

    // İçerik oluştur
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    logger.info("Gemini analiz tamamlandı", {messageLength: message.length});

    return {
      success: true,
      analysis: text,
    };
  } catch (error) {
    logger.error("Gemini API Hatası", {
      error: error.message,
      code: error.code,
      model: GEMINI_MODEL_NAME,
    });

    // 404 hatası için özel mesaj
    if (error.code === 404 || error.message.includes("NOT_FOUND")) {
      throw new Error(
        `Gemini modeli bulunamadı. Model: ${GEMINI_MODEL_NAME}. ` +
        `Lütfen API anahtarınızın geçerli olduğundan ve model adının doğru olduğundan emin olun.`
      );
    }

    throw new Error(`Gemini API çağrısı başarısız: ${error.message}`);
  }
});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
