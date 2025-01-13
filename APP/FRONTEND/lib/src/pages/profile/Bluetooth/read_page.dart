import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BLEService {
  BLEService._privateConstructor();
  static final BLEService instance = BLEService._privateConstructor();

  StreamSubscription<List<int>>? _readSubscription;
  Stream<List<int>>? _broadcastStream;
  final StreamController<String> _dataController = StreamController<String>.broadcast();
  String latestData = "No data read yet";
  String accumulatedData = "";

  Stream<String> get dataStream => _dataController.stream;

  void initializeStream(BluetoothConnection connection) async {
    if (_broadcastStream != null) return;

    // Load previously stored data
    latestData = await getDataFromPreferences("latest_ble_data") ?? "No data read yet";
    _dataController.add(latestData); // Emit the previously stored data

    // Check connection status and input
    if (connection.input != null) {
      print("Initializing input stream...");
      _broadcastStream = connection.input!.asBroadcastStream();
      _startReadingData();
    } else {
      print("Input stream is null, cannot initialize.");
    }

    // Ensure the connection is still alive
    print("Connection status: ${connection.isConnected}");
  }

  void _startReadingData() {
    if (_broadcastStream == null) {
      print("Broadcast stream is not initialized.");
      return;
    }

    _readSubscription?.cancel();

    _readSubscription = _broadcastStream?.listen(
          (event) {
        print("Event received: $event");
        try {
          final String decodedValue = utf8.decode(event).trim();
          accumulatedData += decodedValue;
          print("Accumulated data: $accumulatedData");

          if (_isFullWord(decodedValue)) {
            String completeWord = accumulatedData.trim();
            _processAndSendWord(completeWord);
            accumulatedData = '';
          }
        } catch (e) {
          print("Decoding error: $e");
        }
      },
      onError: (e) => print('Stream error: $e'),
      onDone: () => print('Stream closed.'),
    );
  }

  bool _isFullWord(String decodedValue) {
    return decodedValue.isNotEmpty && decodedValue.length > 1;
  }

  void _processAndSendWord(String word) async {
    print("Finalized word: $word");

    int dataLength = word.length;
    String byteString = word.codeUnits.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    String formattedData = 'Length: $dataLength, Bytes: 0x$byteString, \nValue read from BLE: $word\n';

    _dataController.add(formattedData);
    await saveDataToPreferences("latest_ble_data", formattedData);
  }

  Future<void> saveDataToPreferences(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    print("Data saved to SharedPreferences: Key = $key, Value = $value");
  }

  Future<String?> getDataFromPreferences(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  void stopReading() {
    _readSubscription?.cancel();
    _readSubscription = null;
  }
}

class ClassicReadPage extends StatefulWidget {
  final BluetoothConnection connection;

  const ClassicReadPage({super.key, required this.connection});

  @override
  State<ClassicReadPage> createState() => _ClassicReadPageState();
}

class _ClassicReadPageState extends State<ClassicReadPage> {
  String readdata = "No data read yet";

  @override
  void initState() {
    super.initState();
    print("Initializing BLE stream...");
    _loadStoredData();
    if (widget.connection.isConnected) {
      print("Bluetooth connection is active.");
      BLEService.instance.initializeStream(widget.connection);

      BLEService.instance.dataStream.listen((data) {
        print("Received data: $data");
        setState(() {
          readdata = data;
        });
      });
    } else {
      print("Bluetooth connection is not active. Please ensure it is connected.");
    }
  }

  Future<void> _loadStoredData() async {
    // Fetch stored data from shared preferences
    String? storedData = await BLEService.instance.getDataFromPreferences("latest_ble_data");

    setState(() {
      // If there's stored data, display it, otherwise show a default message
      readdata = storedData ?? "No data read yet";
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        title: Text("Read Operation", style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.05)),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Status: ${widget.connection.isConnected ? 'Connected' : 'Disconnected'}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
              const Divider(),
              Text("CUSTOM CHARACTERISTICS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
              const Divider(),
              Text("Read Value", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
              const SizedBox(height: 18),
              Text("Value:", style: TextStyle(fontWeight: FontWeight.normal, fontSize: screenWidth * 0.04)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(readdata, style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.normal)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
