import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationView extends StatefulWidget {
  @override
  _NotificationViewState createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  final List<Map<String, dynamic>> notifications = [];
  late DatabaseReference _databaseReference;

  // Store previous states of BusA and BusB
  Map<String, Map<String, dynamic>> previousStates = {};

  @override
  void initState() {
    super.initState();
    _databaseReference = FirebaseDatabase.instance.ref().child('PowerTrack Pro');
    _loadNotifications();
    _loadPreviousStates();
    _fetchBusBarFaults();
  }

  // Fetch real-time data and detect faults
  void _fetchBusBarFaults() {
    _databaseReference.onValue.listen((event) {
      if (event.snapshot.exists) {
        final fetchedData = event.snapshot.value as Map<dynamic, dynamic>?;

        if (fetchedData != null) {
          _checkForFaults(fetchedData);
        }
      }
    });
  }

  // Load notifications from shared preferences
  void _loadNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedNotifications = prefs.getString('notifications');

    if (storedNotifications != null) {
      List<dynamic> decodedNotifications = jsonDecode(storedNotifications);
      print('Loaded notifications: $decodedNotifications');

      setState(() {
        notifications.addAll(decodedNotifications.cast<Map<String, dynamic>>());
      });
    } else {
      print('No notifications found in storage');
    }
  }

  // Load previous fault states from shared preferences
  void _loadPreviousStates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedStates = prefs.getString('previousStates');

    if (storedStates != null) {
      setState(() {
        previousStates = Map<String, Map<String, int>>.from(
          jsonDecode(storedStates).map(
            (key, value) => MapEntry(key, Map<String, int>.from(value)),
          ),
        );
      });
    }
  }

  // Save notifications to shared preferences
  void _saveNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedNotifications = jsonEncode(notifications);
    await prefs.setString('notifications', encodedNotifications);
  }

  // Save previous fault states to shared preferences
  void _savePreviousStates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedStates = jsonEncode(previousStates);
    await prefs.setString('previousStates', encodedStates);
  }

  // Check for faults in the fetched data and add notifications if value changes to 0
  void _checkForFaults(Map<dynamic, dynamic> data) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    data.forEach((section, details) {
      final sectionData = details as Map<dynamic, dynamic>?;

      if (sectionData != null) {
        int busAValue = sectionData['BusA'] == 1 ? 1 : 0;
        int busBValue = sectionData['BusB'] == 1 ? 1 : 0;

        // Initialize previous state for this section if it doesn't exist
        if (!previousStates.containsKey(section)) {
          previousStates[section] = {
            'BusA': 1,
            'BusB': 1
          }; // Assume initial state is 1 (no fault)
        }

        // Check for BusA fault (only notify if it changes from 1 to 0)
        if (busAValue == 0 && previousStates[section]!['BusA'] == 1) {
          _addNotification({
            'message': '$section BusA Power Fault',
            'time': timestamp,
            'read': false // Unread when added
          });
        }

        // Check for BusB fault (only notify if it changes from 1 to 0)
        if (busBValue == 0 && previousStates[section]!['BusB'] == 1) {
          _addNotification({
            'message': '$section BusB Power Fault',
            'time': timestamp,
            'read': false // Unread when added
          });
        }

        // Update previous state for BusA and BusB
        previousStates[section]!['BusA'] = busAValue;
        previousStates[section]!['BusB'] = busBValue;
      }
    });

    _saveNotifications();
    _savePreviousStates();
    setState(() {});
  }

  void _addNotification(Map<String, dynamic> notification) {
    bool exists = notifications.any((existingNotification) =>
        existingNotification['message'] == notification['message'] &&
        existingNotification['time'] == notification['time']);

    if (!exists) {
      setState(() {
        notifications.insert(
            0, notification); // Insert new notifications at the top
      });
    }
  }

  void _deleteNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
    _saveNotifications();
  }

  void _markAsRead(int index) {
    setState(() {
      notifications[index]['read'] = true;
    });
    _saveNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications available'))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification['read'] as bool;

                return GestureDetector(
                  onTap: () => _markAsRead(index), // Mark as read when tapped
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    color: isRead
                        ? Colors.white
                        : Colors.grey[300], // Grey for unread, white for read
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fault Detected!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${notification['message']!}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                notification['time']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.black),
                                onPressed: () => _deleteNotification(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

