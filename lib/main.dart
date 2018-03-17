import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'RSS Feed',
      theme: new ThemeData(
        primarySwatch: Colors.red,
      ),
      home: new RSSHomePage(title: 'RSS Feed'),
    );
  }
}

class RSSFeed extends StatefulWidget {
  RSSFeed({Key key, this.title, this.rssOutput}) : super(key: key);

  final String title;
  final String rssOutput;

  @override
  _RSSFeedState createState() => new _RSSFeedState();
}

class _RSSFeedState extends State<RSSFeed> {

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new Text(widget.rssOutput,
            textAlign: TextAlign.center,
        ),
    );
  }
}

class RSSHomePage extends StatefulWidget {
  RSSHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _RSSHomePageState createState() => new _RSSHomePageState();
}

class _RSSHomePageState extends State<RSSHomePage> {
  var feeds = [];

  getFeed(String feed) async {
    var httpClient = new HttpClient();
    String result;
    try {
      var request = await httpClient.getUrl(Uri.parse(feed));
      var response = await request.close();
      if (response.statusCode == HttpStatus.OK) {
        result = await response.transform(UTF8.decoder).join();
      } else {
        result = 'Error getting URL:\nHttp status ${response.statusCode}';
      }
    } catch (exception) {
      result = 'Failed getting URL';
    }

    Navigator.push(context, new MaterialPageRoute(
      builder: (BuildContext context) => new RSSFeed(title: 'RSS Output', rssOutput: result),
    ));

    if (!mounted) return;
  }

  void _addFeedDialog() async {
    await showDialog<String>(
      context: context,
      child: new _SystemPadding(child: new AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        content: new Row(
          children: <Widget>[
            new Expanded(
              child: new TextField(
                autofocus: true,
                onSubmitted: (submitted) {setState(() {
                  feeds.add(submitted);
                  Navigator.pop(context);
                });},
                decoration: new InputDecoration(
                    labelText: 'RSS Feed to add', hintText: 'eg. mysite.com/rss.xml'),
              ),
            )
          ],
        ),
      ),),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new ListView.builder(
        itemCount: feeds.length,
        itemBuilder: (context, index) {
          return new ListTile(
            title: new Text('${feeds[index]}'),
            onLongPress: () {
              setState(() {
                feeds.removeAt(index);
              });
            },
            onTap: () {
              getFeed(feeds[index]);
            }
          );
        },
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _addFeedDialog,
        tooltip: 'Add new RSS feed',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class _SystemPadding extends StatelessWidget {
  final Widget child;

  _SystemPadding({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return new AnimatedContainer(
        padding: mediaQuery.padding,
        duration: const Duration(milliseconds: 300),
        child: child);
  }
}