import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:power_app/src/notification_provider.dart';
import 'package:power_app/src/notification_view.dart';
import 'package:provider/provider.dart';
import 'sample_item.dart';
import 'sample_item_details_view.dart';

class SampleItemListView extends StatefulWidget {
  const SampleItemListView({
    super.key,
    this.items = const [SampleItem(1), SampleItem(2), SampleItem(3)],
  });

  static const routeName = '/';

  final List<SampleItem> items;

  @override
  State<SampleItemListView> createState() => _SampleItemListViewState();
}

class _SampleItemListViewState extends State<SampleItemListView> {
  @override
  void initState() {
    super.initState();
  }

  void _navigateToNotifications() async {
    // Reset notification count when navigating to notification view
    Provider.of<NotificationProvider>(context, listen: false).resetCount();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current notification count
    final notificationCount = context.watch<NotificationProvider>().notificationCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Items'),
        actions: [
          IconButton(
            icon: badges.Badge(
              position: badges.BadgePosition.topEnd(top: -10, end: -6),
              badgeStyle: badges.BadgeStyle(
                badgeColor: Colors.red,
                padding: const EdgeInsets.all(6),
              ),
              badgeContent: notificationCount > 0
                  ? Text(
                      '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    )
                  : null, // Display null if notification count is 0
              child: const Icon(Icons.notifications, size: 28),
            ),
            onPressed: _navigateToNotifications,
          ),
        ],
      ),
      body: ListView.builder(
        restorationId: 'sampleItemListView',
        itemCount: widget.items.length,
        itemBuilder: (BuildContext context, int index) {
          final item = widget.items[index];

          return ListTile(
            title: Text('SampleItem ${item.id}'),
            leading: const CircleAvatar(
              foregroundImage: AssetImage('assets/images/flutter_logo.png'),
            ),
            onTap: () {
              Navigator.restorablePushNamed(
                context,
                SampleItemDetailsView.routeName,
              );
            },
          );
        },
      ),
    );
  }
}
