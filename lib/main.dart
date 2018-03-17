import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:xml/xml.dart' as xml;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart' as webview;

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
  RSSFeed({Key key, this.title, this.rssOutput, this.error}) : super(key: key);

  final String title;
  final String error;
  List<FeedItem> rssOutput = [];

  @override
  _RSSFeedState createState() => new _RSSFeedState();
}

class _RSSFeedState extends State<RSSFeed> {
  String unpackTitleFeedItem(FeedItem feedItem) {
    return "${feedItem.getTitle()}";
  }

  String unpackSubtitleFeedItem(FeedItem feedItem) {
    return "${feedItem.getDate()}";
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new ListView.builder(
        itemCount: widget.rssOutput.length != 0 ? widget.rssOutput.length : 1,
        itemBuilder: (context, index) {
          return new ListTile(
              title: new Text(widget.rssOutput.length != 0
                  ? '${unpackTitleFeedItem(widget.rssOutput[index])}'
                  : widget.error),
              subtitle: new Text(widget.rssOutput.length != 0
                  ? '${unpackSubtitleFeedItem(widget.rssOutput[index])}'
                  : widget.error),
              onTap: () async {
                final FeedItem feedItem = widget.rssOutput[index];
                var flutterWebviewPlugin = new webview.FlutterWebviewPlugin();

                flutterWebviewPlugin.launch(feedItem.getLink());
                await flutterWebviewPlugin.onDestroy.first;
              });
        },
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
  List<String> feeds = [];

  FeedItem parseItem(xml.XmlElement xml) {
    String title = xml.findElements('title').single.text;
    String link = xml.findElements('link').single.text;
    String date = xml.findElements('pubDate').single.text;
    return new FeedItem(title, link, date);
  }

  getFeed(String feed) async {
    var httpClient = new HttpClient();
    List<FeedItem> result = [];
    String error;
    try {
      var request = await httpClient.getUrl(Uri.parse(feed));
      var response = await request.close();
      if (response.statusCode == HttpStatus.OK) {
        String rawOut = await response.transform(UTF8.decoder).join();
        Iterable xmlOut = xml.parse(rawOut).findAllElements('item');
        xmlOut.map((node) => parseItem(node)).forEach((a) => result.add(a));
      } else {
        error = 'Error getting URL:\nHttp status ${response.statusCode}';
      }
    } catch (exception) {
      error = "Error getting URL: $exception";
    }

    Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) =>
              new RSSFeed(title: 'RSS Output', rssOutput: result, error: error),
        ));

    if (!mounted) return;
  }

  void _addFeedDialog() async {
    await showDialog<String>(
      context: context,
      child: new _SystemPadding(
        child: new AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: new Row(
            children: <Widget>[
              new Expanded(
                child: new TextField(
                  autofocus: true,
                  onSubmitted: (submitted) {
                    setState(() {
                      feeds.add(submitted);
                      Navigator.pop(context);
                    });
                  },
                  decoration: new InputDecoration(
                      labelText: 'RSS Feed to add',
                      hintText: 'eg. http://mysite.com/rss.xml'),
                ),
              )
            ],
          ),
        ),
      ),
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
              });
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

class FeedItem {
  String title;
  String link;
  String date;

  String getTitle() {
    return this.title;
  }

  String getLink() {
    return this.link;
  }

  String getDate() {
    return this.date;
  }

  FeedItem(this.title, this.link, this.date);
}
