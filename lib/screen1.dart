import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:webview_flutter/webview_flutter.dart';

class Screen1 extends StatefulWidget {
  const Screen1({Key? key}) : super(key: key);

  @override
  _Screen1State createState() => _Screen1State();
}

class _Screen1State extends State<Screen1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book Forum App"),
      ),
      body: Center(
          child: WebView(
        javascriptMode: JavascriptMode.unrestricted,
        initialUrl: 'https://www.book-forum.org/',
      )),
    );
  }
}
