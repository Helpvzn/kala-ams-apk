import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://script.google.com/macros/s/AKfycby9Srklu5Vm75AD2_ovR9ow20yAD4DJRZpem6l9lW-QP2JrWoyIgsIn6FfrsoXUwLdH/exec');
  final body = {'action': 'adminLogin', 'username': 'admin', 'password': '123', 'key': 'KALA_AMS_2026'};
  
  final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'text/plain'
      ..body = jsonEncode(body);
      
  print('Sending manual POST request with followRedirects = false');
  request.followRedirects = false;
  final responseStream = await request.send();
  final response = await http.Response.fromStream(responseStream);
  
  print('Status: ${response.statusCode}');
  print('Location: ${response.headers['location']}');

  if (response.statusCode == 302) {
    final redirectUrl = Uri.parse(response.headers['location']!);
    print('Following redirect to: $redirectUrl');
    // Try POST
    final req2 = http.Request('POST', redirectUrl);
    final resStream2 = await req2.send();
    final res2 = await http.Response.fromStream(resStream2);
    print('POST Redirect Status: ${res2.statusCode}');
    print('POST Redirect Body: ${res2.body}');

    // Try GET
    final req3 = http.Request('GET', redirectUrl);
    final resStream3 = await req3.send();
    final res3 = await http.Response.fromStream(resStream3);
    print('GET Redirect Status: ${res3.statusCode}');
    print('GET Redirect Body: ${res3.body}');
  }
}
