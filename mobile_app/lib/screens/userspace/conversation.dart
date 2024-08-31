import 'dart:convert';
import 'package:chat_app/Firebase/firebaseFunction.dart';
import 'package:chat_app/security/e2ee.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class Conversation extends StatefulWidget {
  final dynamic users;
  final dynamic you;
  Conversation({Key? key, this.users, this.you}) : super(key: key);

  @override
  _ConversationState createState() => _ConversationState();
}

class _ConversationState extends State<Conversation> {
  dynamic conversations = [];
  List<int> dynamic2Uint8ListConvert(List<dynamic> list) {
    var intList = <int>[];
    list.forEach((element) {
      intList.add(element as int);
    });

    return intList;
  }

  @override
  Widget build(BuildContext context) {
    conversations = [];
    widget.users.forEach((element) {
      if (widget.you.get('requestAccepted').contains(element.get('id'))) {
        conversations.add(element);
      }
    });
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: ListTile(
              title: Center(
                child: Text(
                  conversations[index].get('name'),
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              subtitle: Center(
                child: Text(
                  conversations[index].get('user_ID'),
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
              leading: conversations[index].get('image').length == 0
                  ? CircleAvatar(
                    radius: 10.w,
                      child: Icon(
                      Icons.account_circle,
                      color: Colors.blue[800],
                      
                    ))
                  : CircleAvatar(
                    radius: 10.w,
                      backgroundImage: Image.memory(
                              base64Decode(conversations[index].get('image')))
                          .image,
                    ),
              onTap: () async {
                SharedPreferences pref = await SharedPreferences.getInstance();
                List<dynamic> sortList = [
                  pref.getString('id'),
                  conversations[index].id
                ];
                sortList.sort();
                dynamic finalString = sortList[0] + sortList[1];

                if (!pref
                    .getStringList('securedConvos')!
                    .contains(finalString)) {
                  var derivedBits = await End2EndEncryption.returnDerivedBits(
                      json.decode(conversations[index].get('publicKey')),
                      json.decode(pref.getString('privateKey')!));
                  var list = pref.getStringList('securedConvos');
                  list!.add(finalString);
                  pref.setStringList('securedConvos', list);
                  var map = json.decode(pref.getString('DerivedBitsMap')!);
                  map[finalString] = derivedBits;

                  await pref.setString('DerivedBitsMap', json.encode(map));
                }
                Provider.of<FireBaseFunction>(context, listen: false)
                    .setSafeMode(finalString, pref.getString('id')!);
                Navigator.pushNamed(context, '/chatRoom', arguments: {
                  'chatID': finalString,
                  'id': pref.getString('id'),
                  'peerID': conversations[index].id,
                  'name': conversations[index].get('name'),
                  'blocked': conversations[index].get('blocked'),
                  'blockedByYou': widget.you.get('blocked'),
                  'blockedStatus': widget.you
                      .get('blocked')
                      .contains(conversations[index].get('id')),
                  //'appStatus': conversations[index].get('appStatus'),'
                  'DerivedBits': dynamic2Uint8ListConvert(json
                      .decode(pref.getString('DerivedBitsMap')!)[finalString]),

                  'image':conversations[index].get('image'),
                 'requestRecieved': conversations[index].get('requestRecieved'),
                 'requestAccepted': conversations[index].get('requestAccepted'),
                 'age':conversations[index].get('age'),
                 'user_ID':conversations[index].get('user_ID'),
                 'yourAge':pref.getInt('age')
                });
              },
            ),
          ),
        );
      },
    );
  }
}
