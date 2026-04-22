import 'package:http/http.dart' as http;
import 'dart:convert';

class AiService {
  final String _apiKey = const String.fromEnvironment('GROQ_API_KEY');
  final String _url = "https://api.groq.com/openai/v1/chat/completions";

  Future<Map<String, dynamic>> procesarTarea(String texto) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "Eres un asistente de productividad. El usuario te dará una idea de tarea. Responde SOLO en formato JSON con estas llaves: 'titulo', 'prioridad' (Alta/Media/Baja) y 'categoria'."
            },
            {"role": "user", "content": texto}
          ],
          "response_format": {"type": "json_object"}
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(jsonDecode(response.body)['choices'][0]['message']['content']);
      }
      return {"titulo": texto, "prioridad": "Media", "categoria": "General"};
    } catch (e) {
      return {"titulo": texto, "prioridad": "Error", "categoria": "Error"};
    }
  }
}