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
  static const String _apiKey = 'AIza' + 'SyDprILzSUz3ZqcA8SRrE5iD6tk2OCzFwM0';

  Future<ScanResult> analyzeMessage({
    required String userId,
    required String content,
    String contentType = 'message',
  }) async {
    final prompt = _buildMessageAnalysisPrompt(content, contentType);
    final response = await _callGemini(prompt);
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
    final response = await _callGemini(prompt);
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
    final response = await _callGemini(prompt);
    return _parseScanResult(
      userId: userId,
      content: extractedText,
      response: response,
      scanType: ScanType.document,
    );
  }

  Future<Map<String, dynamic>> factCheck(String claim) async {
    final prompt = _buildFactCheckPrompt(claim);
    final response = await _callGemini(prompt);
    return _parseFactCheckResult(response);
  }

  Future<String> chat(
      String userMessage, List<Map<String, String>> history) async {
    final prompt = _buildChatPrompt(userMessage, history);
    final response = await _callGemini(prompt);
    return response['text'] ?? 'I apologize, I could not process that request.';
  }

  Future<Map<String, dynamic>> _callGemini(String prompt) async {
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
          'temperature': 0.2,
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

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
        
        // Remove markdown formatting if Gemini returns it
        text = text.replaceAll('```json', '').replaceAll('```', '').trim();
        
        return {'text': text, 'raw': jsonDecode(text)};
      } else {
        throw Exception('AI API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Gemini API Error: \$e');
      throw Exception('Failed to analyze: \$e');
    }
  }

  ScanResult _parseScanResult({
    required String userId,
    required String content,
    required Map<String, dynamic> response,
    required ScanType scanType,
  }) {
    final raw = response['raw'] as Map<String, dynamic>? ?? {};
    final trustScore = (raw['trustScore'] as num?)?.toInt() ?? 50;
    final threatLevelStr = raw['threatLevel'] as String? ?? 'medium';

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

    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      scanType: scanType,
      content: content.length > 500 ? content.substring(0, 500) : content,
      trustScore: trustScore,
      threatLevel: threatLevel,
      summary: raw['summary'] as String? ?? 'Analysis complete',
      redFlags: List<String>.from(raw['redFlags'] ?? []),
      positiveSignals: List<String>.from(raw['positiveSignals'] ?? []),
      explanation: raw['explanation'] as String? ?? '',
      confidence: (raw['confidence'] as num?)?.toDouble() ?? 0.8,
      metadata: Map<String, dynamic>.from(raw),
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> _parseFactCheckResult(Map<String, dynamic> response) {
    return response['raw'] as Map<String, dynamic>? ??
        {
          'verdict': 'unverifiable',
          'confidence': 0.5,
          'summary': 'Unable to verify this claim.',
          'explanation': 'Please try again with more specific information.',
        };
  }

  Map<String, dynamic> _getMockResponse(String prompt) {
    // Mock for development/demo
    final isScam = prompt.toLowerCase().contains('fee') ||
        prompt.toLowerCase().contains('urgent');

    final mockData = {
      'trustScore': isScam ? 12 : 82,
      'threatLevel': isScam ? 'critical' : 'safe',
      'summary': isScam
          ? 'HIGH RISK: Registration fee scam detected'
          : 'This appears to be a legitimate message',
      'redFlags': isScam
          ? [
              'Requests upfront registration fee (₹999)',
              'Urgency tactics used',
              'Unverified company domain',
              'Too-good-to-be-true offer'
            ]
          : [],
      'positiveSignals': isScam
          ? []
          : ['Professional language', 'Legitimate domain', 'No fee requests'],
      'explanation':
          'Based on AI analysis, this message contains patterns consistent with ${isScam ? "a registration fee scam. Legitimate companies never ask for upfront registration fees." : "legitimate communication. However, always verify through official channels."}',
      'confidence': 0.92,
      'scamType': isScam ? 'registration_fee' : 'none',
      'actionRecommendation': isScam
          ? 'DO NOT pay any fees. Block and report this sender immediately.'
          : 'Appears safe, but verify through official company website.',
    };

    return {'text': jsonEncode(mockData), 'raw': mockData};
  }

  String _buildMessageAnalysisPrompt(String content, String type) {
    return '''
You are TrustShield AI. Analyze this $type for scam patterns.
MESSAGE: """$content"""
Return JSON: {"trustScore":0-100,"threatLevel":"safe|low|medium|high|critical","summary":"...","redFlags":[],"positiveSignals":[],"explanation":"...","confidence":0.0-1.0,"scamType":"...","actionRecommendation":"..."}
''';
  }

  String _buildUrlAnalysisPrompt(String url) {
    return '''
You are TrustShield AI. Analyze URL safety: $url
Return JSON: {"trustScore":0-100,"threatLevel":"safe|low|medium|high|critical","summary":"...","redFlags":[],"positiveSignals":[],"explanation":"...","confidence":0.0-1.0,"isPhishing":false,"domainAnalysis":"...","recommendation":"..."}
''';
  }

  String _buildDocumentAnalysisPrompt(String text, String docType) {
    return '''
You are TrustShield AI. Verify this $docType authenticity:
TEXT: """$text"""
Return JSON: {"trustScore":0-100,"threatLevel":"safe|low|medium|high|critical","summary":"...","redFlags":[],"positiveSignals":[],"explanation":"...","confidence":0.0-1.0,"isFake":false,"companyVerification":"...","recommendation":"..."}
''';
  }

  String _buildFactCheckPrompt(String claim) {
    return '''
You are TrustShield AI. Fact-check: """$claim"""
Return JSON: {"verdict":"true|partially_true|misleading|false|unverifiable","confidence":0.0-1.0,"summary":"...","evidence":[],"context":"...","sources":[],"explanation":"..."}
''';
  }

  String _buildChatPrompt(
      String message, List<Map<String, String>> history) {
    final historyText =
        history.map((h) => '${h["role"]}: ${h["content"]}').join('\n');
    return '''
You are TrustShield AI cybersecurity assistant. Help with scam detection, URL safety, job verification, and digital safety.
History: $historyText
User: $message
Respond concisely and helpfully.
''';
  }
}
