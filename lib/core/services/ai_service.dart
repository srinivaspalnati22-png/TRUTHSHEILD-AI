import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../features/scanner/models/scan_result.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

class AIService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-2.0-flash';
  // NOTE: In production, proxy through Firebase Cloud Functions
  static const String _apiKey = 'AIzaSyDprILzSUz3ZqcA8SRrE5iD6tk2OCzFwM0';

  Future<ScanResult> analyzeMessage({
    required String userId,
    required String content,
    String contentType = 'message',
  }) async {
    final prompt = _buildMessageAnalysisPrompt(content, contentType);
    final response = await _callGeminiJson(prompt);
    return _parseScanResult(
      userId: userId,
      content: content,
      response: response,
      scanType: ScanType.message,
    );
  }

  Future<ScanResult> analyzeUrl({
    required String userId,
    required String url,
  }) async {
    final prompt = _buildUrlAnalysisPrompt(url);
    final response = await _callGeminiJson(prompt);
    return _parseScanResult(
      userId: userId,
      content: url,
      response: response,
      scanType: ScanType.url,
    );
  }

  Future<ScanResult> analyzeDocument({
    required String userId,
    required String extractedText,
    String docType = 'offer_letter',
  }) async {
    final prompt = _buildDocumentAnalysisPrompt(extractedText, docType);
    final response = await _callGeminiJson(prompt);
    return _parseScanResult(
      userId: userId,
      content: extractedText,
      response: response,
      scanType: ScanType.document,
    );
  }

  Future<Map<String, dynamic>> factCheck(String claim) async {
    final prompt = _buildFactCheckPrompt(claim);
    final response = await _callGeminiJson(prompt);
    return _parseFactCheckResult(response);
  }

  Future<String> chat(
      String userMessage, List<Map<String, String>> history) async {
    final prompt = _buildChatPrompt(userMessage, history);
    // Use plain text mode for chat — NOT JSON mode
    final text = await _callGeminiText(prompt);
    return text.isNotEmpty
        ? text
        : 'I apologize, I could not process that request.';
  }

  /// Calls Gemini requesting JSON response (for scan/analysis features)
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

        // Clean up markdown code fences if present
        text = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        // Safely parse JSON with fallback regex extraction
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
      } else if (response.statusCode == 429) {
        throw Exception(
            'Rate limit reached. Please wait a moment and try again.');
      } else if (response.statusCode == 400) {
        throw Exception(
            'Invalid request. Please check your input and try again.');
      } else {
        throw Exception(
            'AI service error (${response.statusCode}). Please try again.');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
          'Network error: Please check your internet connection and try again.');
    }
  }

  /// Calls Gemini and returns plain text (for chat — no JSON mode)
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
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            '';
      } else if (response.statusCode == 429) {
        throw Exception(
            'Rate limit reached. Please wait a moment and try again.');
      } else {
        throw Exception(
            'AI service error (${response.statusCode}). Please try again.');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
          'Network error: Please check your internet connection and try again.');
    }
  }

  ScanResult _parseScanResult({
    required String userId,
    required String content,
    required Map<String, dynamic> response,
    required ScanType scanType,
  }) {
    final raw = response['raw'] as Map<String, dynamic>? ?? {};

    // Safely parse trust score (0-100)
    int trustScore = 50;
    final rawScore = raw['trustScore'];
    if (rawScore is int) {
      trustScore = rawScore.clamp(0, 100);
    } else if (rawScore is double) {
      trustScore = rawScore.round().clamp(0, 100);
    } else if (rawScore is String) {
      trustScore = (int.tryParse(rawScore) ?? 50).clamp(0, 100);
    }

    // Parse threat level
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

    // Parse confidence
    double confidence = 0.8;
    final rawConf = raw['confidence'];
    if (rawConf is double) {
      confidence = rawConf.clamp(0.0, 1.0);
    } else if (rawConf is int) {
      confidence = (rawConf / 100.0).clamp(0.0, 1.0);
    }

    // Parse lists safely
    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList();
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

  Map<String, dynamic> _parseFactCheckResult(
      Map<String, dynamic> response) {
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

  String _buildMessageAnalysisPrompt(String content, String type) {
    return '''You are TrustShield AI, an expert cybersecurity analyst specializing in scam detection for Indian users.

Analyze this $type message for scam patterns, fraud indicators, and safety signals.

MESSAGE:
"""$content"""

Provide a thorough analysis. Return ONLY valid JSON:
{
  "trustScore": <integer 0-100, where 0=definite scam, 100=completely safe>,
  "threatLevel": "<safe|low|medium|high|critical>",
  "summary": "<one-line verdict>",
  "redFlags": ["<specific red flag 1>", "<specific red flag 2>"],
  "positiveSignals": ["<positive signal 1>", "<positive signal 2>"],
  "explanation": "<detailed 2-3 sentence explanation>",
  "confidence": <float 0.0-1.0>,
  "scamType": "<type of scam if detected, e.g. job_fraud|phishing|advance_fee|none>",
  "actionRecommendation": "<specific action the user should take>"
}''';
  }

  String _buildUrlAnalysisPrompt(String url) {
    return '''You are TrustShield AI, an expert in URL and domain security analysis.

Analyze this URL for phishing, malware, or suspicious patterns: $url

Consider: typosquatting, suspicious TLDs, URL shorteners, HTTP vs HTTPS, brand impersonation, known scam patterns.

Return ONLY valid JSON:
{
  "trustScore": <integer 0-100>,
  "threatLevel": "<safe|low|medium|high|critical>",
  "summary": "<one-line verdict about this URL>",
  "redFlags": ["<red flag 1>", "<red flag 2>"],
  "positiveSignals": ["<positive signal 1>"],
  "explanation": "<detailed analysis of why this URL is safe or dangerous>",
  "confidence": <float 0.0-1.0>,
  "isPhishing": <true|false>,
  "domainAnalysis": "<analysis of the domain name and structure>",
  "recommendation": "<what the user should do>"
}''';
  }

  String _buildDocumentAnalysisPrompt(String text, String docType) {
    return '''You are TrustShield AI, an expert document verification specialist for Indian job market fraud.

Analyze this $docType for authenticity and signs of fraud.

DOCUMENT TEXT:
"""$text"""

Check for: unrealistic salary/benefits, unprofessional language, spelling errors, missing company details, suspicious payment requests, fake company names, and fraud indicators.

Return ONLY valid JSON:
{
  "trustScore": <integer 0-100>,
  "threatLevel": "<safe|low|medium|high|critical>",
  "summary": "<one-line verdict about document authenticity>",
  "redFlags": ["<issue 1>", "<issue 2>"],
  "positiveSignals": ["<authentic element 1>"],
  "explanation": "<detailed analysis of document authenticity>",
  "confidence": <float 0.0-1.0>,
  "isFake": <true|false>,
  "companyVerification": "<notes on company legitimacy>",
  "recommendation": "<what the user should do next>"
}''';
  }

  String _buildFactCheckPrompt(String claim) {
    return '''You are TrustShield AI, an expert fact-checker and misinformation analyst.

Fact-check this claim:
"""$claim"""

Analyze based on your knowledge. Be precise about what is known vs. uncertain.

Return ONLY valid JSON:
{
  "verdict": "<true|partially_true|misleading|false|unverifiable>",
  "confidence": <float 0.0-1.0>,
  "summary": "<one-line verdict>",
  "evidence": ["<evidence point 1>", "<evidence point 2>", "<evidence point 3>"],
  "context": "<important context or nuance>",
  "explanation": "<detailed 3-4 sentence explanation>",
  "sources": ["<type of source that would verify this>"]
}''';
  }

  String _buildChatPrompt(
      String message, List<Map<String, String>> history) {
    final historyText = history
        .take(10)
        .map((h) =>
            '${h["role"] == "user" ? "User" : "TrustShield AI"}: ${h["content"]}')
        .join('\n');
    return '''You are TrustShield AI, a friendly and expert cybersecurity assistant helping Indian users identify scams, verify URLs, check documents, and stay safe online. You know about Indian job scams, fake internship frauds, phishing attacks, and digital fraud patterns.

Be concise, direct, and use simple language. If something is a scam, say so clearly.

${historyText.isNotEmpty ? "Previous conversation:\n$historyText\n\n" : ""}User: $message
TrustShield AI:''';
  }
}
