

import 'dart:convert';


import 'package:chat_app/preprocessing/tokenizer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmbeddingBuilder {
  static int maxLength = 20;
  static const List<double> zeroVec = [
    0.05740898,
    0.030532261,
    -0.008809642,
    -0.003009025,
    -0.03963334,
    -0.011783177,
    -0.015926806,
    -0.020860216,
    -0.0061053396,
    0.026439862,
    0.011339709,
    0.009331516,
    -0.002793419,
    0.018202314,
    -0.01938545,
    -0.036871895,
    -0.017111905,
    -0.017899964,
    -0.026630225,
    -0.021746527,
    0.03526734,
    -0.03328146,
    -0.05446625,
    0.0032500373,
    -0.031727884,
    0.03163567,
    0.03771213,
    -0.0035994728,
    -0.024774812,
    0.049946427,
    0.011010163,
    -0.031761967
  ];

   static Map<String,List<dynamic>> embeddingData = {};

  
  static void fetchJson(BuildContext context) async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    var jsonAsString = await rootBundle.loadString('assets/json/FirstLSTM_embedding.json');
    var jsonVar = json.decode(jsonAsString);
    jsonVar.keys.forEach((key){
      embeddingData[key] = jsonVar[key];
    });
  Navigator.pushReplacementNamed(context, '/home', arguments: pref.getString('id'));
  Fluttertoast.showToast(msg: 'Resources Setup Sucessful');
    
    
  }


  static List<double> convertDynamicList2DoubleList(List<dynamic> list){
    List<double> doubleList =[];
    list.forEach((element) {
      doubleList.add(element as double);
    });

    return doubleList;
  }


 
  
  
  static List<List<double>> tokenize(
      String text, Map<String, List<dynamic>> embeddingData, int embeddingDim) {
    var tokens = Tokenizer.getTokens(text);

    List<List<double>> tokenizedMessage = [];
    late List<double> vector;
    for (var part in tokens) {
      if (embeddingData[part] == null) {
        vector = zeroVec;
      } else {
        vector = convertDynamicList2DoubleList(embeddingData[part]!);
      }
      tokenizedMessage.add(vector);
    }
    
    return tokenizedMessage;
  }

  static List<List<double>> padsequence(
      List<List<double>> sequence, int embeddingDim) {
    if (sequence.length > maxLength) {
      return sequence.sublist(0, maxLength);
    } else if (sequence.length < maxLength) {
      List<List<double>> array = [];
      array.addAll(sequence);
      for (var i = array.length; i < maxLength; i++) {
        array.add(zeroVec);
      }

      return array;
    } else {
      return sequence;
    }
  }

  static List<List<double>> preprocess(
      String text, Map<String, List<dynamic>> embeddingData) {
    var tokenizedArray = tokenize(text, embeddingData, 32);
    var paddedArray = padsequence(tokenizedArray, 32);

    return paddedArray;
  }
}
