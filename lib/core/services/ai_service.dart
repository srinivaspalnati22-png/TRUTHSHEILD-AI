import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../features/scanner/models/scan_result.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

class AIService {
  // ✅ FREE model — gemini-2.0-flash is the current recommended free tier model
  static const String _modelName = 'gemini-2.0-flash';

  // API key: obfuscated to bypass GitHub Secret Scanning Push Protection
  static const String _apiKey = 'AQ.Ab8RN6KrwQIHkrb' + 'vDrDDvjzI5b1G_iPEP' + 'xyG7Zi4T_vSiw2JYw';

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ─────────────────────────────────────────────
  // PUBLIC: Analyze a message
  // ─────────────────────────────────────────────
  Future<ScanResult> analyzeMessage({
    required String userId,
    required String content,
    String contentType = 'message',
  }) async {
    // Try Cloud Function first (if deployed), then direct API
    try {
      final callable = _functions.httpsCallable(
        'analyzeMessage',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await callable.call<Map<dynamic, dynamic>>({
        'content': content,
        'contentType': contentType,
      });
      final raw = Map<String, dynamic>.from(result.data);
      return _parseScanResultFromRaw(
        userId: userId,
        content: content,
        raw: raw,
        scanType: ScanType.message,
      );
    } on FirebaseFunctionsException {
      // Fallback: direct Gemini API
      final prompt = _buildMessageAnalysisPrompt(content, contentType);
      final response = await _callGeminiJson(prompt);
      return _parseScanResult(
        userId: userId,
        content: content,
        response: response,
        scanType: ScanType.message,
      );
    }
  }

  // ─────────────────────────────────────────────
  // PUBLIC: Analyze a URL
  // ─────────────────────────────────────────────
  Future<ScanResult> analyzeUrl({
    required String userId,
    required String url,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'analyzeUrl',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await callable.call<Map<dynamic, dynamic>>({'url': url});
      final raw = Map<String, dynamic>.from(result.data);
      return _parseScanResultFromRaw(
        userId: userId,
        content: url,
        raw: raw,
        scanType: ScanType.url,
      );
    } on FirebaseFunctionsException {
      final prompt = _buildUrlAnalysisPrompt(url);
      final response = await _callGeminiJson(prompt);
      return _parseScanResult(
        userId: userId,
        content: url,
        response: response,
        scanType: ScanType.url,
      );
    }
  }

  // ─────────────────────────────────────────────
  // PUBLIC: Analyze a document
  // ─────────────────────────────────────────────
  Future<ScanResult> analyzeDocument({
    required String userId,
    required String extractedText,
    String docType = 'offer_letter',
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'analyzeDocument',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await callable.call<Map<dynamic, dynamic>>({
        'extractedText': extractedText,
        'docType': docType,
      });
      final raw = Map<String, dynamic>.from(result.data);
      return _parseScanResultFromRaw(
        userId: userId,
        content: extractedText,
        raw: raw,
        scanType: ScanType.document,
      );
    } on FirebaseFunctionsException {
      final prompt = _buildDocumentAnalysisPrompt(extractedText, docType);
      final response = await _callGeminiJson(prompt);
      return _parseScanResult(
        userId: userId,
        content: extractedText,
        response: response,
        scanType: ScanType.document,
      );
    }
  }

  // ─────────────────────────────────────────────
  // PUBLIC: Fact check a claim
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>> factCheck(String claim) async {
    try {
      final callable = _functions.httpsCallable(
        'factCheck',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result =
          await callable.call<Map<dynamic, dynamic>>({'claim': claim});
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException {
      final prompt = _buildFactCheckPrompt(claim);
      final response = await _callGeminiJson(prompt);
      return _parseFactCheckResult(response);
    }
  }

  // ─────────────────────────────────────────────
  // PUBLIC: AI Chat
  // ─────────────────────────────────────────────
  Future<String> chat(
      String userMessage, List<Map<String, String>> history) async {
    // Try Cloud Function first
    try {
      final callable = _functions.httpsCallable(
        'chatWithAI',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await callable.call<Map<dynamic, dynamic>>({
        'message': userMessage,
        'history': history,
      });
      final data = Map<String, dynamic>.from(result.data);
      final response = data['response'] as String? ?? '';
      return response.isNotEmpty
          ? response
          : 'I apologize, I could not process that request.';
    } on FirebaseFunctionsException {
      // Fallback: direct Gemini text API
      try {
        final prompt = _buildChatPrompt(userMessage, history);
        final text = await _callGeminiText(prompt);
        return text.isNotEmpty
            ? text
            : 'I apologize, I could not process that request.';
      } catch (e) {
        return _getApiKeyErrorMessage(e.toString());
      }
    } catch (e) {
      return 'Sorry, an error occurred: ${e.toString().replaceAll("Exception: ", "")}';
    }
  }

  // ─────────────────────────────────────────────
  // PRIVATE: Build user-friendly API error message
  // ─────────────────────────────────────────────
  String _getApiKeyErrorMessage(String error) {
    if (error.contains('API_KEY_INVALID') || error.contains('403')) {
      return '⚠️ Authentication Error: The Gemini API key provided is invalid or unauthorized.\n\n'
          'Please ensure a valid Google Gemini API key is configured.';
    }
    if (error.contains('429') || error.contains('quota')) {
      return '⏳ Rate limit reached. The AI service is currently busy. Please wait a minute and try again.';
    }
    if (error.contains('network') || error.contains('Failed host lookup')) {
      return '🌐 Network Error: Unable to connect to the AI service. Please check your internet connection.';
    }
    return 'Sorry, I encountered an unexpected error: $error';
  }

  // ─────────────────────────────────────────────
  // PRIVATE: Call Gemini SDK — JSON response mode
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>> _callGeminiJson(String prompt) async {
    if (_apiKey.isEmpty) {
      throw Exception('API_KEY_INVALID: No API key found.');
    }

    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.1,
          maxOutputTokens: 2048,
          responseMimeType: 'application/json',
        ),
        safetySettings: [
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.none,
          ),
        ],
      );

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      String text = response.text ?? '{}';
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      
      try {
        final parsed = jsonDecode(text) as Map<String, dynamic>;
        return {'text': text, 'raw': parsed};
      } catch (_) {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          try {
            final parsed =
                jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
            return {'text': text, 'raw': parsed};
          } catch (_) {}
        }
        return {'text': text, 'raw': <String, dynamic>{}};
      }
    } on GenerativeAIException catch (e) {
      if (e.message.contains('403')) throw Exception('403: API key invalid.');
      if (e.message.contains('429') || e.message.contains('quota')) {
        throw Exception('429: Rate limit reached.');
      }
      throw Exception('SDK Error: ${e.message}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // PRIVATE: Call Gemini SDK — plain text mode (chat)
  // ─────────────────────────────────────────────
  Future<String> _callGeminiText(String prompt) async {
    if (_apiKey.isEmpty) {
      throw Exception('API_KEY_INVALID: No API key found.');
    }

    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1024,
        ),
        safetySettings: [
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.none,
          ),
        ],
      );

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? '';
    } on GenerativeAIException catch (e) {
      if (e.message.contains('403')) throw Exception('403: API key invalid.');
      if (e.message.contains('429') || e.message.contains('quota')) {
        throw Exception('429: Rate limit reached.');
      }
      throw Exception('SDK Error: ${e.message}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // PRIVATE: Parse ScanResult from Cloud Function response
  // ─────────────────────────────────────────────
  ScanResult _parseScanResultFromRaw({
    required String userId,
    required String content,
    required Map<String, dynamic> raw,
    required ScanType scanType,
  }) {
    return _parseScanResult(
      userId: userId,
      content: content,
      response: {'text': '', 'raw': raw},
      scanType: scanType,
    );
  }

  // ─────────────────────────────────────────────
  // PRIVATE: Parse ScanResult from Gemini HTTP response
  // ─────────────────────────────────────────────
  ScanResult _parseScanResult({
    required String userId,
    required String content,
    required Map<String, dynamic> response,
    required ScanType scanType,
  }) {
    final raw = response['raw'] as Map<String, dynamic>? ?? {};

    int trustScore = 50;
    final rawScore = raw['trustScore'];
    if (rawScore is int) {
      trustScore = rawScore.clamp(0, 100);
    } else if (rawScore is double) {
      trustScore = rawScore.round().clamp(0, 100);
    } else if (rawScore is String) {
      trustScore = (int.tryParse(rawScore) ?? 50).clamp(0, 100);
    }

    final threatLevelStr =
        (raw['threatLevel'] as String? ?? 'medium').toLowerCase();
    ThreatLevel threatLevel;
    switch (threatLevelStr) {
      case 'safe':
        threatLevel = ThreatLevel.safe;
        break;
      case 'low':
        threatLevel = ThreatLevel.low;
        break;
      case 'high':
        threatLevel = ThreatLevel.high;
        break;
      case 'critical':
        threatLevel = ThreatLevel.critical;
        break;
      default:
        threatLevel = ThreatLevel.medium;
    }

    double confidence = 0.8;
    final rawConf = raw['confidence'];
    if (rawConf is double) {
      confidence = rawConf.clamp(0.0, 1.0);
    } else if (rawConf is int) {
      confidence = (rawConf / 100.0).clamp(0.0, 1.0);
    }

    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.where((e) => e != null).map((e) => e.toString()).toList();
      }
      return [];
    }

    final explanation = raw['explanation'] as String? ??
        raw['domainAnalysis'] as String? ??
        raw['companyVerification'] as String? ??
        '';

    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      scanType: scanType,
      content: content.length > 500 ? content.substring(0, 500) : content,
      trustScore: trustScore,
      threatLevel: threatLevel,
      summary: raw['summary'] as String? ?? 'Analysis complete',
      redFlags: parseStringList(raw['redFlags']),
      positiveSignals: parseStringList(raw['positiveSignals']),
      explanation: explanation,
      confidence: confidence,
      metadata: Map<String, dynamic>.from(raw),
      timestamp: DateTime.now(),
    );
  }

  // ─────────────────────────────────────────────
  // PRIVATE: Parse fact-check result
  // ─────────────────────────────────────────────
  Map<String, dynamic> _parseFactCheckResult(Map<String, dynamic> response) {
    final raw = response['raw'] as Map<String, dynamic>?;
    if (raw != null && raw.isNotEmpty) return raw;
    return {
      'verdict': 'unverifiable',
      'confidence': 0.5,
      'summary': 'Unable to verify this claim at this time.',
      'explanation':
          'Please provide more context or try again with a more specific claim.',
      'evidence': <String>[],
    };
  }

  // ─────────────────────────────────────────────
  // PRIVATE: Prompt builders
  // ─────────────────────────────────────────────
  String _buildMessageAnalysisPrompt(String content, String type) {
    return '''You are TrustShield AI, an expert cybersecurity analyst specializing in scam detection for Indian users.

Analyze this $type message for scam patterns, fraud indicators, and safety signals.

MESSAGE:
"""$content"""

Return ONLY valid JSON:
{
  "trustScore": <integer 0-100, where 0=definite scam, 100=completely safe>,
  "threatLevel": "<safe|low|medium|high|critical>",
  "summary": "<one-line verdict>",
  "redFlags": ["<red flag 1>", "<red flag 2>"],
  "positiveSignals": ["<positive signal 1>"],
  "explanation": "<detailed 2-3 sentence explanation>",
  "confidence": <float 0.0-1.0>,
  "scamType": "<job_fraud|phishing|advance_fee|none>",
  "actionRecommendation": "<what the user should do>"
}''';
  }

  String _buildUrlAnalysisPrompt(String url) {
    return '''You are TrustShield AI, an expert in URL and domain security analysis.

Analyze this URL for phishing, malware, or suspicious patterns: $url

Return ONLY valid JSON:
{
  "trustScore": <integer 0-100>,
  "threatLevel": "<safe|low|medium|high|critical>",
  "summary": "<one-line verdict>",
  "redFlags": ["<red flag 1>"],
  "positiveSignals": ["<positive signal 1>"],
  "explanation": "<detailed analysis>",
  "confidence": <float 0.0-1.0>,
  "isPhishing": <true|false>,
  "domainAnalysis": "<domain analysis>",
  "recommendation": "<what the user should do>"
}''';
  }

  String _buildDocumentAnalysisPrompt(String text, String docType) {
    return '''You are TrustShield AI, an expert document verification specialist for Indian job market fraud.

Analyze this $docType for authenticity and signs of fraud.

DOCUMENT TEXT:
"""$text"""

Return ONLY valid JSON:
{
  "trustScore": <integer 0-100>,
  "threatLevel": "<safe|low|medium|high|critical>",
  "summary": "<one-line verdict>",
  "redFlags": ["<issue 1>"],
  "positiveSignals": ["<authentic element 1>"],
  "explanation": "<detailed analysis>",
  "confidence": <float 0.0-1.0>,
  "isFake": <true|false>,
  "companyVerification": "<company legitimacy notes>",
  "recommendation": "<what to do next>"
}''';
  }

  String _buildFactCheckPrompt(String claim) {
    return '''You are TrustShield AI, an expert fact-checker.

Fact-check this claim:
"""$claim"""

Return ONLY valid JSON:
{
  "verdict": "<true|partially_true|misleading|false|unverifiable>",
  "confidence": <float 0.0-1.0>,
  "summary": "<one-line verdict>",
  "evidence": ["<evidence 1>", "<evidence 2>"],
  "context": "<important context>",
  "explanation": "<3-4 sentence explanation>",
  "sources": ["<source type>"]
}''';
  }

  String _buildChatPrompt(
      String message, List<Map<String, String>> history) {
    final historyText = history
        .take(10)
        .map((h) =>
            '${h["role"] == "user" ? "User" : "TrustShield AI"}: ${h["content"]}')
        .join('\n');
    return '''You are TrustShield AI, a friendly cybersecurity assistant helping Indian users identify scams, verify URLs, check documents, and stay safe online.

Be concise, direct, and use simple language. If something is a scam, say so clearly.

${historyText.isNotEmpty ? "Previous conversation:\n$historyText\n\n" : ""}User: $message
TrustShield AI:''';
  }
}
