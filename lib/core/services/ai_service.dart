import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../features/scanner/models/scan_result.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

class AIService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // ✅ FREE model — works without billing
  static const String _model = 'gemini-1.5-flash';

  // API key: loaded from build-time env var, falls back to default
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyCfhZgzhfXEhOv8pWOnmvp_IRS_xtfgZXk',
  );

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
    if (error.contains('403') || error.contains('API_KEY_INVALID')) {
      return '⚠️ API Key Issue: The Gemini API key is invalid.\n\n'
          'Please get a FREE valid key at:\n'
          'https://aistudio.google.com/app/apikey\n\n'
          'Valid keys start with "AIza..."';
    }
    if (error.contains('429')) {
      return '⏳ Rate limit reached. Please wait a minute and try again.';
    }
    return 'Sorry, I encountered an error: $error';
  }

  // ─────────────────────────────────────────────
  // PRIVATE: Call Gemini — JSON response mode
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>> _callGeminiJson(String prompt) async {
    try {
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 2048,
          'responseMimeType': 'application/json',
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE'
          }
        ],
      });

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
        text = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
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
      } else if (response.statusCode == 400) {
        // Try to extract error message from body
        try {
          final errData = jsonDecode(response.body);
          final msg =
              errData['error']?['message'] as String? ?? 'Bad request (400)';
          throw Exception(msg);
        } catch (parseErr) {
          if (parseErr is Exception) rethrow;
          throw Exception('Bad request (400). Check your API key format.');
        }
      } else if (response.statusCode == 403) {
        throw Exception(
            'API key invalid or access denied (403). '
            'Get a free key at https://aistudio.google.com/app/apikey');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit reached. Please wait and try again.');
      } else {
        throw Exception(
            'AI service error (${response.statusCode}). Please try again.');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
          'Network error: Please check your internet connection.');
    }
  }

  // ─────────────────────────────────────────────
  // PRIVATE: Call Gemini — plain text mode (chat)
  // ─────────────────────────────────────────────
  Future<String> _callGeminiText(String prompt) async {
    try {
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE'
          }
        ],
      });

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      } else if (response.statusCode == 403) {
        throw Exception('403: API key invalid.');
      } else if (response.statusCode == 400) {
        throw Exception('400: Bad request — check API key format.');
      } else if (response.statusCode == 429) {
        throw Exception('429: Rate limit reached.');
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error.');
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
