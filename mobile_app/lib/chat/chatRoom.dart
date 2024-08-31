import 'dart:convert';

import 'package:chat_app/Firebase/firebaseFunction.dart';
import 'package:chat_app/preprocessing/embeddingBuilder.dart';
import 'package:chat_app/preprocessing/natural_language_processing.dart';
import 'package:chat_app/security/e2ee.dart';
import 'package:chat_app/service/report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webcrypto/webcrypto.dart';
import 'package:sizer/sizer.dart';

class ChatRoom extends StatefulWidget {
  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  dynamic messages;
  TextEditingController textMessage = TextEditingController();
  dynamic data = {};
  List<String> decryptedMessages = [];
  late bool blockedStatus;
  Map<bool, String> map = {true: 'On', false: 'Off'};

  late List<dynamic> safeModeList;

  String lastSeenDate(DateTime dateTime) {
    if (DateTime.now().difference(dateTime).inDays >= 1) {
      return 'Last seen on ${DateFormat('dd-MM-yyyy').format(dateTime)}';
    }

    return 'Last Seen at ${DateFormat.jm().format(dateTime)}';
  }

  Widget dateIndication(index, messages) {
    if (index == 0) {
      if (DateTime.now()
              .difference(DateTime.fromMillisecondsSinceEpoch(
                  int.parse(messages[index].get('timestamp'))))
              .inDays ==
          0) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
          ),
          child: Padding(
            padding: EdgeInsets.all(2.w),
            child: Text(
              'Today',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      } else if (DateTime.now()
              .difference(DateTime.fromMillisecondsSinceEpoch(
                  int.parse(messages[index].get('timestamp'))))
              .inDays >
          0) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
          ),
          child: Padding(
            padding: EdgeInsets.all(2.w),
            child: Text(
              DateFormat('dd-MM-yyyy').format(
                  DateTime.fromMillisecondsSinceEpoch(
                      int.parse(messages[index].get('timestamp')))),
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } else if (index > 0) {
      var sucessiveMsgDateDiff = DateTime.fromMillisecondsSinceEpoch(
              int.parse(messages[index].get('timestamp')))
          .difference(DateTime.fromMillisecondsSinceEpoch(
              int.parse(messages[index - 1].get('timestamp'))))
          .inDays;
      var comparisonWithToday = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(
              int.parse(messages[index].get('timestamp'))))
          .inDays;
      if (sucessiveMsgDateDiff >= 1 && comparisonWithToday > 0) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
          ),
          child: Padding(
            padding: EdgeInsets.all(2.w),
            child: Text(
              DateFormat('dd-MM-yyyy').format(
                  DateTime.fromMillisecondsSinceEpoch(
                      int.parse(messages[index].get('timestamp')))),
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      } else if (sucessiveMsgDateDiff >= 1 && comparisonWithToday == 0) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
          ),
          child: Padding(
            padding: EdgeInsets.all(2.w),
            child: Text(
              'Today',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }

    return Container();
  }

  blockMechanism() async {
    data['blockedByYou'] =
        await Provider.of<FireBaseFunction>(context, listen: false)
            .onBlockOrUnblock(data['id'], data['peerID'], data['blockedByYou'],
                context, data['blockedStatus']);
    data['blockedStatus'] = !data['blockedStatus'];
  }

  Color safeModeColor(List<dynamic> ids, String uid, String peerID) {
    if (ids.contains(uid)) {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  List<TextButton> getActions(bool second, BuildContext context, Widget content,
      String message, void Function(void Function()) stateChange) {
    if (!second) {
      return [
        TextButton(
            onPressed: () {
              stateChange(() {
                second = true;
                content = Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10.w),
                      child: Text(message,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text(
                        'Are you sure you want to report this message as NOT TOXIC?'),
                  ],
                );
              });
            },
            child: Text('Report')),
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Exit'))
      ];
    } else {
      return [
        TextButton(
            onPressed: () async {
              stateChange(() {
                second = false;
                content = CircularProgressIndicator();
              });
              await ReportMessage.reportMessage(message, '0',
                  (String response) {
                Fluttertoast.showToast(msg: 'Message Reported');
              });
              Navigator.pop(context);
            },
            child: Text('Yes')),
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('No'))
      ];
    }
  }

  Future<bool> fetchDecryptedMessages(
      List<QueryDocumentSnapshot> encryptedMessages) async {
    var holder = <String>[];
    var aesGcmSecretKey =
        await AesGcmSecretKey.importRawKey(data['DerivedBits']);
    for (var msg in encryptedMessages) {
      holder.add(await End2EndEncryption.decryption(
          aesGcmSecretKey, msg.get('content')));
    }
    decryptedMessages = holder;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    data = data.isEmpty ? ModalRoute.of(context)!.settings.arguments : data;
    Provider.of<FireBaseFunction>(context).blocked = data['blockedStatus'];
    blockedStatus = Provider.of<FireBaseFunction>(context).blocked;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 5.w),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                  ),
                ),
                SizedBox(
                  width: 2,
                ),
                data['image'].length == 0
                    ? CircleAvatar(
                        maxRadius: 5.w,
                        child: Icon(
                          Icons.account_circle,
                          color: Colors.blue[800],
                        ))
                    : CircleAvatar(
                        maxRadius: 5.w,
                        backgroundImage:
                            Image.memory(base64Decode(data['image'])).image,
                      ),
                SizedBox(
                  width: 5.w,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/profile', arguments: {
                        'name': data['name'],
                        'id': data['peerID'],
                        'user_ID': data['user_ID'],
                        'age': data['age'],
                        'requestRecieved': data['requestRecieved'],
                        'requestAccepted': data['requestAccepted'],
                        'image': data['image']
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          data['name'],
                          style: TextStyle(
                              fontSize: 10.sp, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .where('id', isEqualTo: data['peerID'])
                                .snapshots(),
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                    snapshot.data.docs[0].get('appStatus') ==
                                            'Online'
                                        ? 'Online'
                                        : lastSeenDate(DateTime.parse(snapshot
                                            .data.docs[0]
                                            .get('appStatus'))),
                                    style: TextStyle(fontSize: 8.sp));
                              } else {
                                return Container();
                              }
                            })
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: Size(7.w, 7.h)),
              onPressed: () async {
                bool x = await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                            'Are you sure you want to ${blockedStatus ? 'unblock' : 'block'} this conversation ?'),
                        content: Container(
                          width: 5.w,
                          height: 5.h,
                        ),
                        actions: [
                          TextButton(
                              onPressed: () async {
                                await blockMechanism();
                                Navigator.pop(context, !blockedStatus);
                              },
                              child: Text('Yes')),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context, blockedStatus);
                              },
                              child: Text('No'))
                        ],
                      );
                    });

                Provider.of<FireBaseFunction>(context, listen: false)
                    .getCurrentBlockedStatus(x);
                blockedStatus =
                    Provider.of<FireBaseFunction>(context, listen: false)
                        .getBlockedStatus;
              },
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('id', isEqualTo: data['peerID'])
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasData) {
                    data['blocked'] = snapshot.data!.docs[0].get('blocked');
                  }
                  return Icon(blockedStatus ? Icons.undo : Icons.block,
                      size: 7.w);
                },
              )),
          SizedBox(
            height: 0,
          ),
          data['yourAge'] >= 16
              ? TextButton(
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, minimumSize: Size(10.w, 10.h)),
                  onPressed: () async {
                    Provider.of<FireBaseFunction>(context, listen: false)
                        .updateSafeMode(
                            data['chatID'], data['id'], safeModeList);
                  },
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('messages')
                        .doc(data['chatID'])
                        .collection('Status')
                        .doc('Status')
                        .snapshots(),
                    builder:
                        (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.hasData) {
                        safeModeList = snapshot.data!.get('safeMode');
                        return Icon(
                          Icons.health_and_safety_outlined,
                          size: 7.w,
                          color: safeModeColor(snapshot.data!.get('safeMode'),
                              data['id'], data['peerID']),
                        );
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  ))
              : Container(
                  child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .doc(data['chatID'])
                      .collection('Status')
                      .doc('Status')
                      .snapshots(),
                  builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.hasData) {
                      safeModeList = snapshot.data!.get('safeMode');
                      return Container();
                    } else {
                      return Container();
                    }
                  },
                )),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/Space.png'), fit: BoxFit.cover),
        ),
        child: Stack(
          children: <Widget>[
            Column(
              children: [
                Flexible(
                    child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .doc(data['chatID'])
                      .collection(data['chatID'])
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blueGrey)));
                    } else {
                      messages = snapshot.data!.docs;
                      return FutureBuilder(
                          future: fetchDecryptedMessages(snapshot.data!.docs),
                          builder: (context, AsyncSnapshot ss) {
                            if (ss.hasData) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: 10.h),
                                child: ListView.builder(
                                  itemCount: decryptedMessages.length,
                                  scrollDirection: Axis.vertical,
                                  padding: EdgeInsets.only(top: 10, bottom: 10),
                                  itemBuilder: (context, index) {
                                    return Column(
                                      children: [
                                        dateIndication(index, messages),
                                        GestureDetector(
                                          onLongPress: () {
                                            Widget contentWidget = Column(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(10.w),
                                                  child: Text(
                                                    decryptedMessages[index],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                Text(
                                                    'Are you sure you want to report this message as TOXIC?')
                                              ],
                                            );
                                            showDialog(
                                                context: context,
                                                builder: (ctx) {
                                                  int pressed = 0;
                                                  return StatefulBuilder(
                                                      builder:
                                                          (cx, stateChange) {
                                                    return AlertDialog(
                                                      title: Text('REPORT'),
                                                      content: Container(
                                                          height: 30.h,
                                                          width: 70.h,
                                                          child: contentWidget),
                                                      actions: [
                                                        TextButton(
                                                            onPressed:
                                                                () async {
                                                              stateChange(() {
                                                                pressed++;
                                                                contentWidget =
                                                                    Center(
                                                                  child:
                                                                      CircularProgressIndicator(),
                                                                );
                                                              });
                                                              if (pressed ==
                                                                  1) {
                                                                await ReportMessage
                                                                    .reportMessage(
                                                                        decryptedMessages[
                                                                            index],
                                                                        '1',
                                                                        (String
                                                                            response) {
                                                                  Fluttertoast
                                                                      .showToast(
                                                                          msg:
                                                                              'Message Reported');
                                                                });
                                                                Navigator.pop(
                                                                    ctx);
                                                              }
                                                            },
                                                            child: Text('Yes')),
                                                        TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  ctx);
                                                            },
                                                            child: Text('No'))
                                                      ],
                                                    );
                                                  });
                                                });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.only(
                                                left: 14,
                                                right: 14,
                                                top: 10,
                                                bottom: 10),
                                            child: Align(
                                              alignment: (messages[index]
                                                          .get('idFrom') ==
                                                      data['id']
                                                  ? Alignment.topRight
                                                  : Alignment.topLeft),
                                              child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    color: messages[index].get(
                                                                'idFrom') ==
                                                            data['id']
                                                        ? Colors.green[800]
                                                        : Colors.black,
                                                    border: Border.all(
                                                        color: (messages[index].get(
                                                                    'idFrom') ==
                                                                data['id']
                                                            ? Colors.green[800]!
                                                            : Colors.black)),
                                                  ),
                                                  padding: EdgeInsets.all(16),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        decryptedMessages[
                                                            index],
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      Text(
                                                        DateFormat.jm().format(DateTime
                                                            .fromMillisecondsSinceEpoch(
                                                                int.parse(messages[
                                                                        index]
                                                                    .get(
                                                                        'timestamp')))),
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 7),
                                                      )
                                                    ],
                                                  )),
                                            ),
                                          ),
                                        )
                                      ],
                                    );
                                  },
                                ),
                              );
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          });
                    }
                  },
                )),
              ],
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
                height: 60,
                width: double.infinity,
                color: Colors.white,
                child: Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.lightBlue,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Expanded(
                      child: TextField(
                        controller: textMessage,
                        decoration: InputDecoration(
                            hintText: "Write message...",
                            hintStyle: TextStyle(color: Colors.black54),
                            border: InputBorder.none),
                      ),
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    FloatingActionButton(
                      onPressed: () async {
                        if (data['blocked'].contains(data['id'])) {
                          Fluttertoast.showToast(
                              msg: "You have been blocked by this contact");
                        } else if (data['blockedByYou']
                            .contains(data['peerID'])) {
                          Fluttertoast.showToast(
                              msg: "You have blocked this contact");
                        } else {
                         
                          if (!safeModeList.contains(data['peerID']) ||
                              data['age'] < 16) {
                            if (NLP.predict(textMessage.text,
                                    EmbeddingBuilder.embeddingData) >
                                0.5) {
                              bool second = false;
                              Widget content = Text(
                                  'Please refrain from using abusive or disrespectful language');

                              showDialog(
                                  context: context,
                                  builder: (ctx) {
                                    return StatefulBuilder(
                                        builder: (context, stateChange) {
                                      return AlertDialog(
                                          title: Text('WARNING!'),
                                          content: Container(
                                              height: 25.h,
                                              width: 50.w,
                                              child: content),
                                          actions: [
                                            TextButton(
                                                onPressed: () async {
                                                  if (second) {
                                                    stateChange(() {
                                                      second = false;
                                                      content = Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      );
                                                    });
                                                    await ReportMessage
                                                        .reportMessage(
                                                            textMessage.text,
                                                            '0',
                                                            (String response) {
                                                      Fluttertoast.showToast(
                                                          msg:
                                                              'Message Reported');
                                                    });
                                                    Navigator.pop(context);
                                                  }
                                                  stateChange(() {
                                                    second = true;
                                                    content = Column(
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  5.w),
                                                          child: Text(
                                                              textMessage.text,
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        ),
                                                        Text(
                                                            'Are you sure you want to report this message as NOT TOXIC?'),
                                                      ],
                                                    );
                                                  });
                                                },
                                                child: Text('Report')),
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text('Exit'))
                                          ]);
                                    });
                                  });
                            } else {
                              Provider.of<FireBaseFunction>(context,
                                      listen: false)
                                  .onSendMessage(
                                      await End2EndEncryption.encryption(
                                          data['DerivedBits'],
                                          textMessage.text),
                                      data['id'],
                                      data['peerID'],
                                      textMessage,
                                      data['chatID']);
                            }
                          } else {
                            Provider.of<FireBaseFunction>(context,
                                    listen: false)
                                .onSendMessage(
                                    await End2EndEncryption.encryption(
                                        data['DerivedBits'], textMessage.text),
                                    data['id'],
                                    data['peerID'],
                                    textMessage,
                                    data['chatID']);
                          }
                        }
                      },
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                      backgroundColor: Colors.blue,
                      elevation: 0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
