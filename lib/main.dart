import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pennmate Notify',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MainPage(title: 'Pennmate Notify'),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _messaging = FirebaseMessaging();
  final _regExp = new RegExp(
      r'^([A-Z]{2,4})\s*-?(?!000?)(\d{2,3})-?(?!000)(\d{3})$',
      caseSensitive: false);
  final _pref = SharedPreferences.getInstance();
  List<String> _children = <String>[];

  @override
  void initState() {
    super.initState();
    _pref.then((pref) {
      final clist = _getList(pref);
      _updateList(clist);
      clist.map(_sanitizeToTopic).forEach(_addTopic);
    });
  }

  void _updateList(List<String> list) => setState(() {
        _children = list;
      });

  List<String> _getList(pref) {
    if (!pref.containsKey("clist")) {
      pref.setStringList("clist", <String>[]);
    }
    return pref.getStringList("clist");
  }

  void _addTopic(String topic) => _messaging.subscribeToTopic(topic);

  void _deleteTopic(String topic) => _messaging.unsubscribeFromTopic(topic);

  String _sanitizeToTopic(s) => s.replaceAll('-', '').replaceAll(' ', '%');

  void _addChannel(Match match) async {
    final category = match.group(1).trim().toUpperCase();
    final course = match.group(2).padLeft(3, '0');
    final section = match.group(3);
    final pref = await _pref;
    final clist = _getList(pref);
    final add = category.padRight(4, ' ') + '-' + course + '-' + section;
    if (clist.contains(add)) {
      return;
    }
    clist.add(add);
    pref.setStringList("clist", clist);
    _updateList(clist);
    _addTopic(_sanitizeToTopic(add));
  }

  void _deleteChannel(String ch) async {
    final pref = await _pref;
    final clist = _getList(pref);
    clist.remove(ch);
    pref.setStringList("clist", clist);
    _updateList(clist);
    _deleteTopic(_sanitizeToTopic(ch));
  }

  _showDialog() async {
    final key = GlobalKey<FormState>();
    Match match;
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Add Course"),
              contentPadding: const EdgeInsets.all(16.0),
              content: Form(
                  key: key,
                  child: TextFormField(
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Course ID',
                      hintText: 'e.g. NETS-212-001',
                    ),
                    validator: (s) {
                      match = _regExp.firstMatch(s);
                      return match == null ? 'invalid course ID' : null;
                    },
                    onEditingComplete: () {
                      if (key.currentState.validate()) {
                        _addChannel(match);
                        Navigator.pop(context);
                      }
                    },
                  )),
              actions: <Widget>[
                FlatButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
                RaisedButton(
                  child: const Text('Confirm'),
                  onPressed: () {
                    if (key.currentState.validate()) {
                      _addChannel(match);
                      Navigator.pop(context);
                    }
                  },
                  textColor: Colors.white,
                )
              ],
            ));
  }

  _showDeleteAlert(s) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Confirm Deletion"),
              contentPadding: const EdgeInsets.all(16.0),
              content: Row(
                children: <Widget>[
                  Expanded(
                      child: Text('Do you really want to delete course\n $s ?'))
                ],
              ),
              actions: <Widget>[
                FlatButton(
                    child: const Text('No'),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
                RaisedButton(
                  child: const Text('Yes'),
                  onPressed: () {
                    _deleteChannel(s);
                    Navigator.pop(context);
                  },
                  textColor: Colors.white,
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Container(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: () {
              if (_children.isEmpty) {
                return const <Widget>[
                  Text(
                    'No courses added for now...',
                    style: TextStyle(fontSize: 20.0),
                  )
                ];
              }
              return _children
                  .map((s) => Row(
                        children: <Widget>[
                          Text(
                            s,
                            style: const TextStyle(fontSize: 30.0),
                          ),
                          IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _showDeleteAlert(s))
                        ],
                      ))
                  .toList();
            }(),
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: _showDialog,
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
