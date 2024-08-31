import 'package:cloud_firestore/cloud_firestore.dart';

class Chat{
  late int id;
  late String type;
  late String content;

  Chat({required this.id,required this.type,required this.content});
}

class UserChat {

  String id;
  String aboutMe;
  String name;

  UserChat({required this.id,  required this.name, required this.aboutMe});

  factory UserChat.fromDocument(DocumentSnapshot doc) {
    String aboutMe = "";
    String nickname = "";
    try {
      aboutMe = doc.get('aboutMe');
    } catch (e) {}

    try {
      nickname = doc.get('name');
    } catch (e) {}
    return UserChat(
      id: doc.id,
      name: nickname,
      aboutMe: aboutMe,
    );
  }
}
class You{
  static String id = '';
}