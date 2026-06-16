import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://script.google.com/macros/s/AKfycby9Srklu5Vm75AD2_ovR9ow20yAD4DJRZpem6l9lW-QP2JrWoyIgsIn6FfrsoXUwLdH/exec');
  final body = {'action': 'adminLogin', 'username': 'admin', 'password': '123', 'key': 'KALA_AMS_2026'};
  
  print('Sending POST with followRedirects=false');
  final request = http.Request('POST', url)
    ..headers['Content-Type'] = 'text/plain'
    ..body = jsonEncode(body)
    ..followRedirects = false;

  final responseStream = await request.send();
  var response = await http.Response.fromStream(responseStream);
  
  if (response.statusCode == 302 || response.statusCode == 307 || response.statusCode == 308) {
      final location = response.headers['location'];
      print('Got 302. Redirecting to: $location');
      if (location != null && location.isNotEmpty) {
          response = await http.get(Uri.parse(location)).timeout(const Duration(seconds: 30));
      }
  }
  
  print('Final Status: ${response.statusCode}');
  print('Final Body: ${response.body}');
}
