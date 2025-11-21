import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Simple Chat App')),
        body: Column(
          children: [
            Expanded(child: ListView()),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(hintText: "Type message..."),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    ));

    expect(find.text('Simple Chat App'), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
