import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import flutter_dotenv or your chosen config management package if used
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// Define input types for context-specific analysis
enum ThreatInputType {
  walletAddress,
  transactionHash,
  url,
  contractAddress,
  generalText, // For news snippets, messages, etc.
}

class ThreatAnalysisService {
  // --- API Key Management (IMPORTANT: Load securely!) ---
  // Example using flutter_dotenv (ensure you have setup .env file)
  // final String _apiKey = dotenv.env['GEMINI_API_KEY']!;
  // Or load from a secure config service
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? ''; // <-- Replace with secure loading method

  late final GenerativeModel _model;

  ThreatAnalysisService() {
    if (_apiKey == "YOUR_GEMINI_API_KEY" || _apiKey.isEmpty) {
      // Add more robust error handling or fallback mechanism
      print("ERROR: Gemini API Key not configured securely!");
      // Consider throwing an exception or disabling the service
      throw Exception("Gemini API Key is not configured.");
    }
    _model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);
  }

  /// Analyzes input data for potential cryptocurrency threats using Gemini.
  ///
  /// Returns a Map containing:
  ///   - 'isThreat': bool (true if a potential threat is detected)
  ///   - 'riskLevel': String ('Low', 'Medium', 'High', 'Unknown')
  ///   - 'threatType': String (e.g., 'Phishing', 'Scam Address', 'Malicious Contract', 'None', 'Unknown')
  ///   - 'explanation': String (Details provided by the AI)
  Future<Map<String, dynamic>> analyzeForThreat({
    required String inputData,
    required ThreatInputType inputType,
  }) async {
    final prompt = _buildPrompt(inputData, inputType);
    final content = [Content.text(prompt)];

    // Default response in case of errors
    Map<String, dynamic> defaultResult = {
      'isThreat': false,
      'riskLevel': 'Unknown',
      'threatType': 'Analysis Error',
      'explanation': 'Could not analyze the input due to an error.',
    };

    try {
      print("Sending data to Gemini for analysis...");
      final response = await _model.generateContent(content);

      if (response.text != null) {
        print("Gemini Response: ${response.text}");
        // Attempt to parse the response (assuming Gemini provides structured output as requested)
        return _parseGeminiResponse(response.text!);
      } else {
        print("Gemini response was empty.");
        defaultResult['explanation'] = 'Received an empty response from the analysis service.';
        return defaultResult;
      }
    } catch (e) {
      print("Error calling Gemini API: $e");
      // Consider more specific error handling based on exception type
      if (e is GenerativeAIException) {
         defaultResult['explanation'] = 'Analysis service error: ${e.message}';
      } else {
         defaultResult['explanation'] = 'An unexpected error occurred during analysis: $e';
      }
      return defaultResult;
    }
  }

  /// Builds a specific prompt for Gemini based on the input type.
  String _buildPrompt(String inputData, ThreatInputType inputType) {
    String context = "";
    switch (inputType) {
      case ThreatInputType.walletAddress:
        context = "a cryptocurrency wallet address: $inputData";
        break;
      case ThreatInputType.transactionHash:
        context = "a blockchain transaction hash: $inputData";
        break;
      case ThreatInputType.url:
        context = "a URL: $inputData";
        break;
      case ThreatInputType.contractAddress:
        context = "a smart contract address: $inputData";
        break;
      case ThreatInputType.generalText:
        context = "the following text: \"$inputData\"";
        break;
    }

    // Requesting JSON output makes parsing much easier and reliable
    return """
      You are a cryptocurrency security analyst AI. Your task is to evaluate potential threats.
      Analyze $context.

      Determine if it poses a security risk such as phishing, scam, association with known hacks or illicit activities, malicious smart contract, or other relevant dangers.

      Provide your analysis ONLY in JSON format with the following fields:
      - "isThreat": boolean (true if a potential threat is detected, false otherwise)
      - "riskLevel": string ("Low", "Medium", "High", or "None" if no threat)
      - "threatType": string (e.g., "Phishing URL", "Known Scam Address", "Malicious Contract", "Suspicious Transaction", "None", "Unknown")
      - "explanation": string (Provide a brief reasoning for your assessment. If no threat, state 'No specific threat identified.')

      JSON Response:
    """;
  }

  /// Parses the JSON response from Gemini.
  Map<String, dynamic> _parseGeminiResponse(String responseText) {
    try {
      // Clean up potential markdown formatting around the JSON
      String cleanedText = responseText.trim();
      if (cleanedText.startsWith("```json")) {
        cleanedText = cleanedText.substring(7);
      }
      if (cleanedText.endsWith("```")) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }
      cleanedText = cleanedText.trim();

      final Map<String, dynamic> jsonResponse = jsonDecode(cleanedText);

      // Validate expected fields exist
      bool isThreat = jsonResponse['isThreat'] ?? false;
      String riskLevel = jsonResponse['riskLevel'] ?? 'Unknown';
      String threatType = jsonResponse['threatType'] ?? 'Unknown';
      String explanation = jsonResponse['explanation'] ?? 'No explanation provided.';

      return {
        'isThreat': isThreat,
        'riskLevel': riskLevel,
        'threatType': threatType,
        'explanation': explanation,
      };
    } catch (e) {
      print("Error parsing Gemini JSON response: $e");
      print("Raw Response Text: $responseText");
      // Fallback: Try basic keyword analysis if JSON parsing fails
      bool containsThreatKeywords = responseText.toLowerCase().contains('threat') ||
                                    responseText.toLowerCase().contains('risk') ||
                                    responseText.toLowerCase().contains('scam') ||
                                    responseText.toLowerCase().contains('phishing') ||
                                    responseText.toLowerCase().contains('malicious');
      return {
        'isThreat': containsThreatKeywords, // Best guess
        'riskLevel': containsThreatKeywords ? 'Unknown' : 'None',
        'threatType': containsThreatKeywords ? 'Analysis Error (Parsing Failed)' : 'None',
        'explanation': 'Could not parse the AI response structure. Raw text: $responseText',
      };
    }
  }
}