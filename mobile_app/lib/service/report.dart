

import 'package:http/http.dart' as http;

class ReportMessage {
  static const String URL =
      'https://script.google.com/macros/s/AKfycbxOUNeGL_A3Aj19_G4-k3Y-KXk45cCyKLjSxx_zNxwJ084cn5RGuUMq9q4Gn8ginbCy/exec';
  static Future<void> reportMessage(
      String message, String toxicity,void Function(String) callback) async {
    try {
      await http.post(Uri.parse(URL), body: {'message':message,'toxicity':toxicity}).then((response) async {
        
        if (response.statusCode == 302) {
          var url = response.headers['location'];
          await http.get(Uri.parse(url!)).then((response) {
            
            callback(response.body);
          });
        } else {
         
          callback(response.body);
        }
      });
    } catch (e) {
      print('EXCEPTIONNNNN $e');
    }
  }
}
