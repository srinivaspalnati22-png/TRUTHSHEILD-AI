const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();
const db = admin.firestore();

// Initialize Gemini AI
const genAI = new GoogleGenerativeAI(functions.config().gemini.api_key);

// ============================================
// RATE LIMITING HELPER
// ============================================
async function checkRateLimit(userId, action, maxRequests = 20, windowMinutes = 60) {
  const rateLimitRef = db.collection("rate_limits").doc(`${userId}_${action}`);
  const now = admin.firestore.Timestamp.now();
  const windowStart = new admin.firestore.Timestamp(
    now.seconds - windowMinutes * 60, 0
  );

  const doc = await rateLimitRef.get();
  if (doc.exists) {
    const data = doc.data();
    const recentRequests = data.requests.filter(
      (t) => t.seconds > windowStart.seconds
    );
    if (recentRequests.length >= maxRequests) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Rate limit exceeded. Please wait before making more requests."
      );
    }
    await rateLimitRef.update({
      requests: [...recentRequests, now],
    });
  } else {
    await rateLimitRef.set({ requests: [now] });
  }
}

// ============================================
// AI MESSAGE ANALYSIS
// ============================================
exports.analyzeMessage = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required.");
  }

  const { content, contentType = "message" } = data;

  if (!content || content.trim().length < 10) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Message content too short."
    );
  }

  if (content.length > 5000) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Message too long. Max 5000 characters."
    );
  }

  // Rate limiting: 20 analyses per hour
  await checkRateLimit(context.auth.uid, "analyzeMessage", 20, 60);

  try {
    const model = genAI.getGenerativeModel({
      model: "gemini-2.0-flash",
      generationConfig: { temperature: 0.2, maxOutputTokens: 1024 },
    });

    const prompt = `
You are TrustShield AI, a cybersecurity expert. Analyze this ${contentType} for scams.

MESSAGE: """${content}"""

Return ONLY this JSON:
{
  "trustScore": 0-100,
  "threatLevel": "safe|low|medium|high|critical",
  "summary": "one sentence verdict",
  "redFlags": ["flag1", "flag2"],
  "positiveSignals": ["signal1"],
  "explanation": "2-3 paragraph detailed explanation",
  "confidence": 0.0-1.0,
  "scamType": "fake_job|fake_internship|phishing|registration_fee|bank_alert|none",
  "actionRecommendation": "what user should do"
}`;

    const result = await model.generateContent(prompt);
    const text = result.response.text();
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    const analysis = JSON.parse(jsonMatch ? jsonMatch[0] : text);

    // Log scan metadata (NOT the content)
    await db
      .collection("scan_history")
      .doc(context.auth.uid)
      .collection("scans")
      .add({
        userId: context.auth.uid,
        scanType: "message",
        contentPreview: content.substring(0, 100),
        trustScore: analysis.trustScore,
        threatLevel: analysis.threatLevel,
        summary: analysis.summary,
        confidence: analysis.confidence,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isDeleted: false,
      });

    // Update user stats
    await db
      .collection("users")
      .doc(context.auth.uid)
      .update({
        totalScans: admin.firestore.FieldValue.increment(1),
        threatsDetected:
          analysis.threatLevel === "high" || analysis.threatLevel === "critical"
            ? admin.firestore.FieldValue.increment(1)
            : admin.firestore.FieldValue.increment(0),
        lastSeen: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Content is NOT stored - privacy first
    return analysis;
  } catch (error) {
    functions.logger.error("AI analysis failed:", error);
    throw new functions.https.HttpsError("internal", "AI analysis failed.");
  }
});

// ============================================
// URL ANALYSIS
// ============================================
exports.analyzeUrl = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required.");
  }

  const { url } = data;
  if (!url) {
    throw new functions.https.HttpsError("invalid-argument", "URL required.");
  }

  await checkRateLimit(context.auth.uid, "analyzeUrl", 30, 60);

  try {
    const model = genAI.getGenerativeModel({
      model: "gemini-2.0-flash",
      generationConfig: { temperature: 0.1 },
    });

    const prompt = `Analyze this URL for security threats: ${url}
Return JSON: {"trustScore":0-100,"threatLevel":"safe|low|medium|high|critical","summary":"...","redFlags":[],"positiveSignals":[],"explanation":"...","confidence":0.0-1.0,"isPhishing":false,"recommendation":"..."}`;

    const result = await model.generateContent(prompt);
    const text = result.response.text();
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    const analysis = JSON.parse(jsonMatch ? jsonMatch[0] : text);

    // Cache URL results for 24 hours to reduce API calls
    const urlHash = Buffer.from(url).toString("base64").substring(0, 50);
    await db.collection("url_scans").doc(urlHash).set({
      url: url.substring(0, 200),
      trustScore: analysis.trustScore,
      threatLevel: analysis.threatLevel,
      summary: analysis.summary,
      cachedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return analysis;
  } catch (error) {
    throw new functions.https.HttpsError("internal", "URL analysis failed.");
  }
});

// ============================================
// FACT CHECK
// ============================================
exports.factCheck = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required.");
  }

  const { claim } = data;
  if (!claim || claim.length < 20) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Claim too short."
    );
  }

  await checkRateLimit(context.auth.uid, "factCheck", 10, 60);

  try {
    const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
    const prompt = `Fact-check: """${claim}"""
Return JSON: {"verdict":"true|partially_true|misleading|false|unverifiable","confidence":0.0-1.0,"summary":"...","evidence":[],"context":"...","explanation":"..."}`;

    const result = await model.generateContent(prompt);
    const text = result.response.text();
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    return JSON.parse(jsonMatch ? jsonMatch[0] : text);
  } catch (error) {
    throw new functions.https.HttpsError("internal", "Fact check failed.");
  }
});

// ============================================
// COMMUNITY THREAT REPORT
// ============================================
exports.submitThreatReport = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required.");
  }

  const { type, description, evidence } = data;

  if (!type || !description || description.length < 20) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Valid type and description required."
    );
  }

  await checkRateLimit(context.auth.uid, "submitReport", 5, 1440); // 5 per day

  // Input sanitization
  const sanitizedDescription = description
    .replace(/<[^>]*>/g, "") // Remove HTML
    .substring(0, 1000);

  await db.collection("community_threats").add({
    type: type,
    description: sanitizedDescription,
    evidence: evidence ? evidence.substring(0, 500) : "",
    reporterId: context.auth.uid,
    status: "pending",
    reportCount: 1,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, message: "Report submitted successfully." };
});

// ============================================
// ANALYTICS AGGREGATION (SCHEDULED)
// ============================================
exports.aggregateAnalytics = functions.pubsub
  .schedule("every 24 hours")
  .timeZone("Asia/Kolkata")
  .onRun(async (context) => {
    const today = new Date().toISOString().split("T")[0];

    // Count scans by type
    const scansSnapshot = await db.collectionGroup("scans").get();
    const stats = {
      totalScans: scansSnapshot.size,
      byThreatLevel: { safe: 0, low: 0, medium: 0, high: 0, critical: 0 },
      date: today,
    };

    scansSnapshot.docs.forEach((doc) => {
      const level = doc.data().threatLevel;
      if (stats.byThreatLevel[level] !== undefined) {
        stats.byThreatLevel[level]++;
      }
    });

    await db.collection("analytics").doc(today).set(stats);
    functions.logger.info("Analytics aggregated for", today);
    return null;
  });

// ============================================
// USER ROLE MANAGEMENT (ADMIN ONLY)
// ============================================
exports.setUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required.");
  }

  // Verify admin role
  const callerDoc = await db.collection("users").doc(context.auth.uid).get();
  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Admin access required."
    );
  }

  const { targetUid, role } = data;
  if (!["user", "moderator", "admin"].includes(role)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid role.");
  }

  await db.collection("users").doc(targetUid).update({ role });

  // Log admin action
  await db.collection("admin").doc("audit_logs").collection("logs").add({
    action: "set_role",
    adminId: context.auth.uid,
    targetUserId: targetUid,
    newRole: role,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});
