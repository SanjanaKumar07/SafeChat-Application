import 'dart:convert';
import 'package:sizer/sizer.dart';
import 'package:chat_app/Firebase/firebaseFunction.dart';
import 'package:chat_app/security/e2ee.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsPage extends SearchDelegate {
  dynamic users;
  dynamic you;
  List<String> sent = [];
  List<int> dynamic2Uint8ListConvert(List<dynamic> list) {
    var intList = <int>[];
    list.forEach((element) {
      intList.add(element as int);
    });

    return intList;
  }

  Widget getTrailingWidget(
      requestSent,
      requestRecieved,
      requestAccepted,
      peerID,
      List<dynamic> suggestions,
      int index,
      BuildContext context,
      setState) {
    if (requestSent.contains(peerID)) {
      return Icon(Icons.check);
    } else if (requestRecieved.contains(peerID)) {
      return Column(
        children: [
          Expanded(
            child: ButtonTheme(
              height: 15,
              child: TextButton(
                  onPressed: () {
                    Provider.of<FireBaseFunction>(context, listen: false)
                        .acceptRequest(
                            you.get('requestAccepted'),
                            you.get('requestRecieved'),
                            suggestions[index].get('requestAccepted'),
                            suggestions[index].get('requestSent'),
                            suggestions[index].get('id'),
                            you.get('id'));
                  },
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(color: Colors.red)))),
                  child:
                      FittedBox(fit: BoxFit.fitHeight, child: Text('Accept'))),
            ),
          ),
          SizedBox(
            height: 2.h,
          ),
          Expanded(
            child: ButtonTheme(
              height: 5.h,
              child: TextButton(
                  onPressed: () {},
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(color: Colors.red)))),
                  child: FittedBox(fit: BoxFit.fitHeight, child: Text('Deny'))),
            ),
          )
        ],
      );
    } else if (requestAccepted.contains(peerID)) {
      return SizedBox(
        height: 0,
        width: 0,
      );
    } else {
      return sent.contains(suggestions[index].get('id'))
          ? Icon(Icons.check)
          : TextButton(
              onPressed: () {
                setState(() {
                  Provider.of<FireBaseFunction>(context, listen: false)
                      .sendRequest(
                          you.get('requestSent'),
                          suggestions[index].get('requestRecieved'),
                          suggestions[index].get('id'),
                          you.get('id'));
                  sent.add(suggestions[index].get('id'));
                });
              },
              child: Icon(Icons.add));
    }
  }

  ContactsPage({this.users, this.you});
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
          onPressed: () {
            query = "";
          },
          icon: Icon(Icons.clear))
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () {
          close(context, null);
        },
        icon: AnimatedIcon(
            icon: AnimatedIcons.menu_arrow, progress: transitionAnimation));
  }

  @override
  Widget buildResults(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<dynamic> suggestions = users.where((element) {
      if (element
              .get('user_ID')
              .toLowerCase()
              .startsWith(query.toLowerCase()) ||
          element.get('name').toLowerCase().startsWith(query.toLowerCase())) {
        return true;
      } else {
        return false;
      }
    }).toList();
    return Column(
      children: [
        Padding(
            padding: EdgeInsets.all(4.h),
            child: Row(
              children: [
                Text(
                  'SEARCH',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25.sp,
                      foreground: Paint()
                        ..shader = LinearGradient(colors: <Color>[
                          Colors.blue[900]!,
                          Colors.blue[700]!,
                          Colors.blue[500]!,
                          Colors.blue[300]!,
                        ]).createShader(Rect.fromLTWH(0, 0, 200, 100))),
                ),
              ],
            )),
        Expanded(
          child: StatefulBuilder(builder: (context, setState) {
            return ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.w)),
                    child: Padding(
                      padding: EdgeInsets.all(3.h),
                      child: ListTile(
                        title: Center(
                          child: Text(
                            suggestions[index].get('name'),
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                        subtitle: Center(
                          child: Text(
                            suggestions[index].get('user_ID'),
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ),
                        leading: suggestions[index].get('image').length == 0
                            ? CircleAvatar(
                                radius: 10.w,
                                child: Icon(
                                  Icons.account_circle,
                                  color: Colors.blue[800],
                                ))
                            : CircleAvatar(
                                radius: 10.w,
                                backgroundImage: Image.memory(base64Decode(
                                        suggestions[index].get('image')))
                                    .image,
                              ),
                        onTap: () async {
                          if (you
                              .get('requestAccepted')
                              .contains(suggestions[index].get('id'))) {
                            SharedPreferences pref =
                                await SharedPreferences.getInstance();
                            List<dynamic> sortList = [
                              pref.getString('id'),
                              suggestions[index].id
                            ];
                            sortList.sort();
                            dynamic finalString = sortList[0] + sortList[1];

                            if (!pref
                                .getStringList('securedConvos')!
                                .contains(finalString)) {
                              var derivedBits =
                                  await End2EndEncryption.returnDerivedBits(
                                      json.decode(
                                          suggestions[index].get('publicKey')),
                                      json.decode(
                                          pref.getString('privateKey')!));
                              var list = pref.getStringList('securedConvos');
                              list!.add(finalString);
                              pref.setStringList('securedConvos', list);
                              var map = json
                                  .decode(pref.getString('DerivedBitsMap')!);
                              map[finalString] = derivedBits;

                              await pref.setString(
                                  'DerivedBitsMap', json.encode(map));
                            }

                            Navigator.pushNamed(context, '/chatRoom',
                                arguments: {
                                  'chatID': finalString,
                                  'id': pref.getString('id'),
                                  'peerID': suggestions[index].id,
                                  'name': suggestions[index].get('name'),
                                  'blocked': suggestions[index].get('blocked'),
                                  'blockedByYou': you.get('blocked'),
                                  'blockedStatus': you
                                      .get('blocked')
                                      .contains(suggestions[index].get('id')),
                                  'user_ID': suggestions[index].get('user_ID'),
                                  'DerivedBits': dynamic2Uint8ListConvert(
                                      json.decode(pref.getString(
                                          'DerivedBitsMap')!)[finalString]),
                                  'yourAge': pref.getInt('age'),
                                  'age': suggestions[index].get('age'),
                                  'requestRecieved':
                                      suggestions[index].get('requestRecieved'),
                                  'requestAccepted':
                                      suggestions[index].get('requestAccepted'),
                                });
                          }
                        },
                        trailing: getTrailingWidget(
                            you.get('requestSent'),
                            you.get('requestRecieved'),
                            you.get('requestAccepted'),
                            suggestions[index].get('id'),
                            suggestions,
                            index,
                            context,
                            setState),
                      ),
                    ),
                  );
                });
          }),
        ),
      ],
    );
  }
}
