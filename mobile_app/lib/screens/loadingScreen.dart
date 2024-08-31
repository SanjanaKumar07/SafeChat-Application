import 'package:chat_app/preprocessing/embeddingBuilder.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late dynamic id;
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
          content: ListTile(
        leading: Icon(
          Icons.settings,
          size: 10.w,
          color: Colors.white,
        ),
        title: Text('Setting up resources. Please wait...',
            style: TextStyle(
              color: Colors.white,
            )),
      )));
    });
  }

  @override
  void dispose(){
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    id = '';
    id = id.isEmpty ? ModalRoute.of(context)!.settings.arguments : id;
    EmbeddingBuilder.fetchJson(context);
    return Scaffold(
      body: Container(
          color: Colors.white,
          child: Column(
            
            children: [
              SizedBox(height: 25.h),
              Image.asset('assets/images/splash.png'),
              Text(
                'Powered by T.R.O.Y',
                style: TextStyle(
                  fontSize: 14.sp,
                ),
                )
            ],
          )
    ));
  }
}
