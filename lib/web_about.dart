// Note: future display of information window using a webview
// Not yet finished for now
//
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String kNavigationExamplePage = '''
<!DOCTYPE html><html>
<meta name="viewport" content="width=device-width; minimum-scale=1.0; maximum-scale=1.0; user-scalable=no">
<head><title>Qui est Ouvert?</title></head>
<body>
<p>
Cette application affiche les commerces ouverts pendant le confinement, et utilise les donees Open Source 
obtenue sur le site du gouv:

<a href=https://www.data.gouv.fr/fr/datasets/lieux-ouverts-ou-fermes-pendant-le-confinement-covid-19/#_>https://www.data.gouv.fr/fr/datasets/lieux-ouverts-ou-fermes-pendant-le-confinement-covid-19/#_</a></p>
<ul>
<ul><a href="https://www.youtube.com/">https://www.youtube.com/</a></ul>
<ul><a href="https://www.google.com/">https://www.google.com/</a></ul>
</ul>
</body>
</html>
''';

class WebAbout extends StatefulWidget {
  @override
  _WebAboutState createState() => _WebAboutState();
}

class _WebAboutState extends State<WebAbout> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A propos'),
        // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
      ),
      // We're using a Builder here so we have a context that is below the Scaffold
      // to allow calling Scaffold.of(context) so we can show a snackbar.
      body: Builder(builder: (BuildContext context) {
    return WebView(
          initialUrl: 'https://flutter.dev',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);

               final String contentBase64 =
        base64Encode(const Utf8Encoder().convert(kNavigationExamplePage));
            webViewController.loadUrl('data:text/html;base64,$contentBase64');
          },

          navigationDelegate: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              print('blocking navigation to $request}');
              return NavigationDecision.prevent;
            }
            print('allowing navigation to $request');
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
          },
          gestureNavigationEnabled: true,
        );
      })
    );
  }
}
