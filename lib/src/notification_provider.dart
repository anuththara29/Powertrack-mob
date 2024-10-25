import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationProvider with ChangeNotifier {
  int _notificationCount = 0;
  final Map<String, Map<String, int>> _previousStates = {}; // Store previous states for each section

  int get notificationCount => _notificationCount;

  NotificationProvider() {
    _initDatabaseListener();
  }

  void incrementCount() {
    _notificationCount++;
    notifyListeners();
  }

  void resetCount() {
    _notificationCount = 0;
    notifyListeners();
  }

  void _initDatabaseListener() {
    DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('PowerTrack Pro');

    dbRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      _checkForFaults(data);
    });
  }

  void _checkForFaults(Map<dynamic, dynamic> data) {
    data.forEach((section, details) {
      final sectionData = details as Map<dynamic, dynamic>?;

      if (sectionData != null) {
        int busAValue = sectionData['BusA'] == '0' ? 0 : 1;
        int busBValue = sectionData['BusB'] == '0' ? 0 : 1;

        // Initialize previous state for this section if it doesn't exist
        if (!_previousStates.containsKey(section)) {
          _previousStates[section] = {'BusA': 1, 'BusB': 1}; // Assume initial state is 1 (no fault)
        }

        // Check for BusA fault (notify only if it changes from 1 to 0)
        if (busAValue == 0 && _previousStates[section]!['BusA'] == 1) {
          incrementCount(); 
        }

        // Check for BusB fault (notify only if it changes from 1 to 0)
        if (busBValue == 0 && _previousStates[section]!['BusB'] == 1) {
          incrementCount(); 
        }

        // Update previous state for BusA and BusB
        _previousStates[section]!['BusA'] = busAValue;
        _previousStates[section]!['BusB'] = busBValue;
      }
    });

    notifyListeners(); 
  }
}
