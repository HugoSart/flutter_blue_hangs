import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Blue - Issue reproduction',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Blue - Issue reproduction'),
    );
  }

}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isScanning = false;
  List<BluetoothDevice> results = [];
  StreamSubscription sub;

  @override
  Widget build(BuildContext context) {
    final text = isScanning ? 'Stop scan' : 'Start scan';
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 90),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: results.map(_mapResult).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleScan,
        tooltip: text,
        child: Icon(isScanning ? Icons.stop : Icons.play_arrow),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> _toggleScan() async {
    final blue = FlutterBlue.instance;
    blue.setLogLevel(LogLevel.debug);

    // Start scan
    if (!isScanning) {
      print('APP -> Starting scan');
      final aux = blue.scanResults.listen((r) {
        setState(() {
          results.forEach((element) {
            print('APP -> Found device $element.}');
          });
          results = r.map((e) => e.device).toList();
        });
      });
      blue.startScan();
      setState(() {
        sub = aux;
        isScanning = true;
      });
    }

    // Stop scan
    else {
      print('APP -> Stopping');
      final aux = await blue.isScanning.first;
      setState(() {
        if (sub != null) sub.cancel();
        if (aux) blue.stopScan();
        setState(() => isScanning = false);
      });
    }
  }

  Widget _mapResult(BluetoothDevice device) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: InkWell(
          onTap: () => _onDeviceTap(device),
          child: Center(
              child: Text(device.name == null || device.name.isEmpty ? device.id.toString() : device.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
    );
  }

  Future<void> _onDeviceTap(BluetoothDevice device) async {
    print('APP -> Connecting to ${device.id}');
    await device.connect(autoConnect: true);
    print('APP -> Successfully connected to ${device.id}!');
    device.disconnect();
  }

}
