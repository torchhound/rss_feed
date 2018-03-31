import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:xml/xml.dart' as xml;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart' as webview;
import 'dart:async';
import 'package:path_provider/path_provider.dart';

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
  final List<FeedItem> rssOutput;

  @override
  _RSSFeedState createState() => new _RSSFeedState();
}

class _RSSFeedState extends State<RSSFeed> {
  final flutterWebviewPlugin = new webview.FlutterWebviewPlugin();
  StreamSubscription _onDestroy;
  bool webviewAlive;

  String unpackTitleFeedItem(FeedItem feedItem) {
    return "${feedItem.getTitle()}";
  }

  String unpackSubtitleFeedItem(FeedItem feedItem) {
    return "${feedItem.getDate()}";
  }

  @override
  initState() {
    super.initState();

    flutterWebviewPlugin.close();

    _onDestroy = flutterWebviewPlugin.onDestroy.listen((_) {
      if (mounted) {
        webviewAlive = false;
      }
    });
  }

  @override
  void dispose() {
    flutterWebviewPlugin.dispose();
    _onDestroy.cancel();
    super.dispose();
  }

  Future<bool> _willPopCallback() async {
    if (webviewAlive == true) {
      flutterWebviewPlugin.close();
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        child: new Scaffold(
          appBar: new AppBar(
            title: new Text(widget.title),
          ),
          body: new ListView.builder(
            itemCount:
                widget.rssOutput.length != 0 ? widget.rssOutput.length : 1,
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
                    webviewAlive = true;
                    flutterWebviewPlugin.launch(feedItem.getLink());
                    await flutterWebviewPlugin.onDestroy.first;
                  });
            },
          ),
        ),
        onWillPop: _willPopCallback);
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

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return new File('$path/feeds.txt');
  }

  void writeFeeds(List<String> feeds) async {
    print("writeFeeds");
    final file = await _localFile;
    var outputStream = file.openWrite();
    for (String feed in feeds) {
      print(feed);
      outputStream.write(feed + "\n");
    }
    outputStream.close();
  }

  Future<bool> readFeeds() async {
    try {
      print("readFeeds");
      final file = await _localFile;
      Stream<List<int>> inputStream = file.openRead();
      inputStream
        .transform(utf8.decoder)
        .transform(new LineSplitter())
        .listen((String line) {
          feeds.add(line);
          print(line);
        },
        onDone: () {
          print('File is now closed.');
          print(feeds);
         },
        onError: (e) {
          print(e.toString());
        });
      return true;
    } catch (e) {
      print("readFeeds failed");
      return false;
    }
  }

  @override
  initState() {
    super.initState();
    if (mounted) {
      setState(() {
        readFeeds();
      });
    }
  }

  @override
  void dispose() {
    writeFeeds(feeds);
    super.dispose();
  }

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
          content: new Row(
            children: <Widget>[
              new Expanded(
                child: new TextField(
                  autofocus: true,
                  onSubmitted: (submitted) {
                    setState(() {
                      feeds.add(submitted);
                      writeFeeds(feeds);
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
                  writeFeeds(feeds);
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
      ),
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
        padding: mediaQuery.viewInsets,
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
