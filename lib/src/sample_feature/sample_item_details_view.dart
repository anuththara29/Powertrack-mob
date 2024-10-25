// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SampleItemDetailsView extends StatefulWidget {
  const SampleItemDetailsView({super.key});

  static const routeName = '/sample_item';

  @override
  _SampleItemDetailsViewState createState() => _SampleItemDetailsViewState();
}

class _SampleItemDetailsViewState extends State<SampleItemDetailsView> {
  late DatabaseReference _databaseReference;
  Map<String, dynamic>? hqData;
  Map<String, dynamic>? otsData;
  Map<String, dynamic>? welData;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _databaseReference = FirebaseDatabase.instance.ref();
    _setUpDatabaseListener(); // Set up real-time database listener
  }

  void _setUpDatabaseListener() {
    _databaseReference.onValue.listen((event) {
      if (event.snapshot.exists) {
        final fetchedData = event.snapshot.value as Map<dynamic, dynamic>?;

        if (fetchedData != null) {
          setState(() {
            hqData = fetchedData['HQ']?.cast<String, dynamic>();
            otsData = fetchedData['OTS']?.cast<String, dynamic>();
            welData = fetchedData['WEL']?.cast<String, dynamic>();

            //check for faults
            _checkForFaults(hqData, 'HQ');
            _checkForFaults(otsData, 'OTS');
            _checkForFaults(welData, 'WEL');
          });
        }
      } else {
        print("No data exists at the root node.");
      }
    });
  }

  // Check for faults in BusA or BusB
  void _checkForFaults(Map<String, dynamic>? data, String source) {
    if (data == null) return;

    // Check if BusA or BusB is "0", indicating a fault
    if (data['BusA'] == '0') {
      _showNotification('Fault detected', 'Fault in BusA of $source');
    }
    if (data['BusB'] == '0') {
      _showNotification('Fault detected', 'Fault in BusB of $source');
    }
  }

  // Method to show local notification
  Future<void> _showNotification(String title, String body) async {
    // Get the current time
    String formattedTime = _getCurrentTime();

    // Create a notification body
    String notificationBody = '$body';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('your_channel_id', 'your_channel_name',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            autoCancel: true);

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
        0, title, notificationBody, platformChannelSpecifics,
        payload: 'item id');
  }

  // Method to get the current time as a formatted string
  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    //Get the screen width to make the squares responsive
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Power Data'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: hqData == null && otsData == null && welData == null
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDataContainer(
                            'HQ', hqData, screenWidth, screenHeight),
                        const SizedBox(height: 20),
                        _buildDataContainer(
                            'OTS', otsData, screenWidth, screenHeight),
                        const SizedBox(height: 20),
                        _buildDataContainer(
                            'WELIKADA', welData, screenWidth, screenHeight),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataContainer(String label, Map<String, dynamic>? data,
      double screenWidth, double screenHeight) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 3,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          data == null
              ? Text('No data for $label',
                  style: const TextStyle(color: Colors.black))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusSquare(
                        'BusA', data['BusA'], screenWidth, screenHeight),
                    const SizedBox(width: 20),
                    _buildStatusSquare(
                        'BusB', data['BusB'], screenWidth, screenHeight),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatusSquare(
      String label, dynamic value, double screenWidth, double screenHeight) {
    bool isPowerFailure = value == "0";
    String statusText =
        isPowerFailure ? "$label \nPower Failure" : "$label \nPower OK";

    return Container(
      width: screenWidth * 0.35, // 35% of the screen width for responsiveness
      height: screenHeight * 0.18, // 18% of the screen height for responsiveness
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black12,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          statusText,
          style: TextStyle(
                color: isPowerFailure ? Colors.red : Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
