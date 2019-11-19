import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:auto_size_text/auto_size_text.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pennmate Notify',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        buttonColor: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  final _messaging = FirebaseMessaging();
  final _regExp = new RegExp(
      r'^([A-Z]{2,4})\s*-?((?!000)\d{3}|(?!00)\d{2})-?(?!000)(\d{3})$',
      caseSensitive: false);
  final _pref = SharedPreferences.getInstance();
  final _courses = <Map<String, dynamic>>[];
  Timer _timer;
  List<String> _children = [];

  void _timerAction() {
    _timer?.cancel();
    _timer = Timer(const Duration(minutes: 1), _timerAction);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messaging.configure(onMessage: (m) {
      _showNormalAlert(m['notification']['title'], m['notification']['body']);
      _timerAction();
      return;
    });
    _pref.then((pref) {
      final clist = _getList(pref);
      _updateList(clist);
      clist.map(_sanitizeToTopic).forEach(_addTopic);
    });
    http.get('https://pennmate.com/courses.php').then((resp) {
      jsonDecode(resp.body).forEach((c) => _courses.add(c));
    });
    _timer = Timer(const Duration(minutes: 1), _timerAction);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _updateList(List<String> list) {
    _children = list;
    _timerAction();
  }

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
    final clist = _getList(pref)..remove(ch);
    pref.setStringList("clist", clist);
    _updateList(clist);
    _deleteTopic(_sanitizeToTopic(ch));
  }

  _showDialog() async {
    final key = GlobalKey<FormState>();
    final controller = TextEditingController();
    Match match;
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Add Course"),
              content: Form(
                  key: key,
                  child: TypeAheadFormField(
                    getImmediateSuggestions: true,
                    hideOnEmpty: true,
                    hideSuggestionsOnKeyboardHide: false,
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: controller,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Course & Section ID',
                        hintText: 'e.g. NETS-212-001',
                      ),
                      onEditingComplete: () {
                        if (key.currentState.validate()) {
                          _addChannel(match);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    validator: (s) {
                      match = _regExp.firstMatch(s);
                      return match == null ? 'Invalid ID' : null;
                    },
                    suggestionsCallback: (pattern) {
                      pattern =
                          pattern.replaceAll(RegExp(r'-|\s'), '').toUpperCase();
                      return pattern.isEmpty
                          ? const <void>[]
                          : _courses
                              .where((c) => c['id'].startsWith(pattern))
                              .take(6)
                              .toList();
                    },
                    itemBuilder: (context, suggestion) => ListTile(
                      leading: Text(suggestion['id'].splitMapJoin(_regExp,
                          onMatch: (Match m) =>
                              m.groups([1, 2, 3]).join('\n'))),
                      title: Text(suggestion['title']),
                      subtitle: AutoSizeText(
                        suggestion['inst'].join(', '),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(suggestion['act']),
                      dense: true,
                      selected: controller.text
                              .replaceAll(RegExp(r'-|\s'), '')
                              .toUpperCase() ==
                          suggestion['id'],
                    ),
                    onSuggestionSelected: (suggestion) {
                      controller.text = suggestion['id'].splitMapJoin(_regExp,
                          onMatch: (Match m) => m.groups([1, 2, 3]).join('-'));
                    },
                  )),
              actions: [
                FlatButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context)),
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
              content: Row(
                children: [
                  Expanded(
                    child: Text('Do you really want to delete course ' +
                        s.replaceAll(' ', '') +
                        '?'),
                  )
                ],
              ),
              actions: [
                FlatButton(
                    child: const Text('No'),
                    onPressed: () => Navigator.pop(context)),
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

  _showNormalAlert(title, body) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(title),
              content: Row(
                children: [Expanded(child: Text(body))],
              ),
              actions: [
                FlatButton(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context)),
              ],
            ));
  }

  final _formatter = new DateFormat('MMM d, h:mm a');

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _timer.cancel();
        break;
      case AppLifecycleState.resumed:
        if (!_timer.isActive) {
          _timerAction();
        }
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pennmate Notify'),
      ),
      body: Scrollbar(
          child: Container(
        padding: EdgeInsets.all(16.0),
        child: () {
          if (_children.isEmpty) {
            return const Text(
              'No courses added for now...',
              style: TextStyle(fontSize: 20.0),
            );
          }
          return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 60.0),
              child: Column(
                  children: _children
                      .map((s) => Row(
                            children: [
                              Expanded(
                                  flex: 4,
                                  child: AutoSizeText(s.replaceAll(' ', ''),
                                      maxLines: 1,
                                      style: const TextStyle(fontSize: 25.0))),
                              Expanded(
                                flex: 3,
                                child: FutureBuilder<http.Response>(
                                    future: http.get(
                                        'https://pennmate.com/last_opened.php?course=' +
                                            s),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<http.Response> snapshot) {
                                      switch (snapshot.connectionState) {
                                        case ConnectionState.done:
                                          if (snapshot.hasError ||
                                              snapshot.data.body.isEmpty) break;
                                          final intData =
                                              int.tryParse(snapshot.data.body);
                                          if (intData == null) break;
                                          final wid = [
                                            AutoSizeText(
                                              intData == -1
                                                  ? 'Course available.'
                                                  : 'Last opened at:',
                                              maxLines: 1,
                                              style: TextStyle(
                                                  color: Colors.blue[600]),
                                            )
                                          ];

                                          if (intData != -1) {
                                            wid.add(AutoSizeText(
                                              _formatter.format(DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      intData * 1000)),
                                              maxLines: 1,
                                              style: TextStyle(
                                                  color: Colors.blue[300]),
                                            ));
                                          }
                                          return Column(children: wid);
                                        default:
                                      }
                                      return Container();
                                    }),
                              ),
                              Expanded(
                                child: Ink(
                                  width: 40,
                                  height: 40,
                                  decoration: ShapeDecoration(
                                    color: Colors.lightBlue,
                                    shape: CircleBorder(),
                                  ),
                                  child: IconButton(
                                    iconSize: 25,
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _showDeleteAlert(s),
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            ],
                          ))
                      .fold(<Widget>[
                const Text('Course List', style: TextStyle(fontSize: 40.0))
              ], (l, row) {
                return l..add(const Divider())..add(row);
              })));
        }(),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: _showDialog,
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }
}
