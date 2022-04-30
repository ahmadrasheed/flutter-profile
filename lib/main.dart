import 'dart:ffi';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:book_forum/screen1.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

//this function should be written outside the class, it used to handle fcm when the device
// is terminated or in background state
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

//https://github.com/sbis04/notify/blob/master/lib/main.dart
//https://blog.logrocket.com/flutter-push-notifications-with-firebase-cloud-messaging/
//https://www.youtube.com/watch?v=PpAoCXEnvvM
// we defined this as global to be accessed by all classes
SharedPreferences prefs = null!;

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  late final FirebaseMessaging _messaging;

  void runFirebase() async {
    prefs = await SharedPreferences.getInstance();
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;
    _messaging.subscribeToTopic('all');
    _messaging.getToken().then((token) {
      // global variable
      //saving token into sharedpreferences
      prefs.setString('fcmToken', token!);
    });
  } // End of runFirebase func-----------

  @override
  Widget build(BuildContext context) {
    runFirebase();

    return OverlaySupport(
      child: MaterialApp(
        title: 'شعبة التعليم الالكتروني',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
        ),
        debugShowCheckedModeBanner: false,
        home: AnimatedSplashScreen(
            splashIconSize: 300.0,
            duration: 3000,
            splash: Image.asset(
              'assets/bg.png',
              width: 400,
              height: 400,
            ),
            nextScreen: HomePage(),
            splashTransition: SplashTransition.slideTransition,
            pageTransitionType: null,
            backgroundColor: Colors.white),
      ),
    );
  }
}

///////////////////////////////////////--Second Class --/////////////////////////////////////
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late WebViewController _controller;
  late final FirebaseMessaging _messaging;
  late int _totalNotifications;
  //late String _token;
  PushNotification? _notificationInfo;
  String _url = "http://192.168.0.105/login/";

  // ---------------------------------------------
  void registerNotification() async {
    //await Firebase.initializeApp(); //we did that on the first class
    _messaging = FirebaseMessaging.instance;
    _messaging.subscribeToTopic('all');
    _messaging.getToken().then((token) {
      print("00000000000=from second class registerNotification func 1 " +
          token!);

      print(
          "000000000=from second class registerNotification func 2  " + _url!);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        //this will excuted when the notification arrives and the app is open
        // it will be excuted even with out the click on the notification
        print(
            '000000 Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');

        // Parse the message received
        PushNotification notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
          dataTitle: message.data['title'],
          dataBody: message.data['body'],
        );

        setState(() {
          _notificationInfo = notification;

          print("00000000000 setState called from onMessage");
          //_controller.loadUrl("https://www.youtube.com/");
          _totalNotifications++;
        });

        //this is to show simple notification above the screen when the app is open
        if (_notificationInfo != null) {
          print("000000000 if notificatino is not null show simpleNoti");
          // For displaying the notification as an overlay
          showSimpleNotification(
            Text(_notificationInfo!.title!),
            leading: NotificationBadge(totalNotifications: _totalNotifications),
            subtitle: Text(_notificationInfo!.body!),
            background: Colors.grey.shade700,
            duration: Duration(seconds: 5),
          );
        }
      });
    } else {
      print('00000000 User declined or has not accepted permission');
    }
  } // End of registerNotification func-----------

  // For handling notification when the app is in terminated state
  checkForInitialMessage() async {
    await Firebase.initializeApp();
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      PushNotification notification = PushNotification(
        title: initialMessage.notification?.title,
        body: initialMessage.notification?.body,
        dataTitle: initialMessage.data['title'],
        dataBody: initialMessage.data['body'],
      );

      setState(() {
        _notificationInfo = notification;
        _controller.loadUrl(_url);
        _totalNotifications++;
      });
    }
  } // end of checkForInitialMessage func

  @override
  void initState() {
    //this function will be exceuted before all. note: code line will be exceute faster or before calling function
    print("00000000 initState  0000 ");
    var token = prefs.getString('fcmToken')!;
    var url2 = prefs.getString('url2');
    _url = _url + token;
    print("00000000 url from initState  0000" + _url);

    _totalNotifications = 0;
    registerNotification();

    checkForInitialMessage();

    // For handling notification when the app is in background
    // but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      PushNotification notification = PushNotification(
        title: message.notification?.title,
        body: message.notification?.body,
        dataTitle: message.data['title'],
        dataBody: message.data['body'],
      );

      setState(() {
        _notificationInfo = notification;
        print(
            "kkkkkkkkkk from onMessageOpened in initstate $message.data['url']");
        _controller.loadUrl(message.data['url']);
        print("kkkkkkk222222222" + message.data['url']);
        //_url = "https://www.book-forum.org/";
        _totalNotifications++;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("00000000 will be excuted after initState func 00");
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.brown.shade900),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.brown.shade50,
                        radius: 50,
                        child: (Text('A',
                            style: TextStyle(
                              fontSize: 22.0,
                              shadows: [
                                Shadow(
                                  blurRadius: 0.5,
                                  color: Colors.black,
                                  offset: Offset(0.9, 0.9),
                                )
                              ],
                            ))),
                      ),
                    ],
                  ),
                  SizedBox(height: 60),
                  (Text('شعبة التعليم الالكتروني',
                      style: TextStyle(
                        fontSize: 22.0,
                        color: Colors.brown.shade100,
                        shadows: [
                          Shadow(
                            blurRadius: 0.5,
                            color: Colors.black,
                            offset: Offset(0.9, 0.9),
                          )
                        ],
                      ))),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.brown),
              title: Text("Home"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: Colors.brown,
              ),
              title: Text("Settings"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.contacts, color: Colors.brown),
              title: Text("Contact Us"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: Colors.brown,
              ),
              title: Text("Resources"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: Colors.brown,
              ),
              title: TextField(
                onChanged: (text) {
                  var mytoken = prefs.getString('fcmToken');
                  var url2 = "http://" + text + "/login/" + mytoken!;
                  _controller.loadUrl(url2);

                  print('0000000000000000 textfield changed  =====  : $text');
                  print('0000000000000000 textfield changed  =====++++  :' +
                      url2);
                },
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Container(
              padding: EdgeInsets.all(16.0),
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white12,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                        child: Text(
                          'developed by: Ahamd Algeboory 2022',
                          maxLines: 5,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.brown.shade500,
        title: Text('شعبة التعليم الالكتروني'),
        brightness: Brightness.dark,
      ),
      body: WebView(
        javascriptMode: JavascriptMode.unrestricted,
        initialUrl: _url,
        onWebViewCreated: (controller) {
          _controller = controller;
        },
      ),
    );
  }
}

/*
*
*
*
*
*
*
* */
class NotificationBadge extends StatelessWidget {
  final int totalNotifications;
  const NotificationBadge({required this.totalNotifications});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.0,
      height: 40.0,
      decoration: new BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '$totalNotifications',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }
}

class PushNotification {
  PushNotification({
    this.title,
    this.body,
    this.dataTitle,
    this.dataBody,
  });

  String? title;
  String? body;
  String? dataTitle;
  String? dataBody;
}
