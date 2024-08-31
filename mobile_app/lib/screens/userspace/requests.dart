import 'dart:convert';

import 'package:chat_app/Firebase/firebaseFunction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class Requests extends StatefulWidget {
  final dynamic users;
  final dynamic you;
  Requests({Key? key, this.users, this.you}) : super(key: key);

  @override
  _RequestsState createState() => _RequestsState();
}

class _RequestsState extends State<Requests> {
  dynamic requests = [];
  @override
  Widget build(BuildContext context) {
    requests = [];
    widget.users.forEach((element) {
      if (widget.you.get('requestRecieved').contains(element.get('id'))) {
        requests.add(element);
      }
    });
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.w)),
          child: Padding(
            padding: EdgeInsets.all(3.h),
            child: ListTile(
              title: Center(
                child: Text(
                  requests[index].get('name'),
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              subtitle: Center(
                child: Text(
                  requests[index].get('user_ID'),
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
              leading: requests[index].get('image').length == 0
                  ? CircleAvatar(
                     radius: 10.w,
                      child: Icon(
                      Icons.account_circle,
                      color: Colors.blue[800],
                     
                    ))
                  : CircleAvatar(
                     radius: 10.w,
                      backgroundImage: Image.memory(
                              base64Decode(requests[index].get('image')))
                          .image,
                    ),
              trailing: Column(
                children: [
                  Expanded(
                    child: ButtonTheme(
                      height: 10.h,
                      child: TextButton(
                          onPressed: () {
                            Provider.of<FireBaseFunction>(context,
                                    listen: false)
                                .acceptRequest(
                                    widget.you.get('requestAccepted'),
                                    widget.you.get('requestRecieved'),
                                    requests[index].get('requestAccepted'),
                                    requests[index].get('requestSent'),
                                    requests[index].get('id'),
                                    widget.you.get('id'));
                          },
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.green),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                      side: BorderSide(color: Colors.red)))),
                          child: FittedBox(
                              fit: BoxFit.fitHeight,
                              child: Text(
                                'ACCEPT',
                                style: TextStyle(color: Colors.white),
                              ))),
                    ),
                  ),
                  SizedBox(
                    height: 0.5.h,
                  ),
                  Expanded(
                    child: ButtonTheme(
                      height: 10.h,
                      child: TextButton(
                          onPressed: () {},
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.red),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                      side: BorderSide(color: Colors.red)))),
                          child: FittedBox(
                              fit: BoxFit.fitHeight,
                              child: Text(
                                'DENY',
                                style: TextStyle(color: Colors.white),
                              ))),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
