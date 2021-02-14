import 'package:flutter/material.dart';
import 'package:review_prompt/review_prompt.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Review Prompt Example'),
        ),
        body: SafeArea(
          child: ReviewPromptListener(
            minDaysSinceInstall: 0,
            minLaunchCount: 3,
            listener: (context, reviewInApp, openStoreListing) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: Text('Wanna review?'),
                    actions: [
                      TextButton(
                        child: Text('No Thanks'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: Text('Sure'),
                        onPressed: () async {
                          debugPrint('Review!');
                          await reviewInApp();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Center(
              child: Text('Review prompt example'),
            ),
          ),
        ),
      ),
    );
  }
}
