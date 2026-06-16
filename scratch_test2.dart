import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://script.google.com/macros/s/AKfycby9Srklu5Vm75AD2_ovR9ow20yAD4DJRZpem6l9lW-QP2JrWoyIgsIn6FfrsoXUwLdH/exec');
  final body = {'action': 'adminLogin', 'username': 'admin', 'password': '123', 'key': 'KALA_AMS_2026'};
  
  print('Sending automatic http.post');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'text/plain'},
    body: jsonEncode(body),
  );
  
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
  
  if (response.statusCode == 302) {
      print('Location: ${response.headers['location']}');
  }
}
