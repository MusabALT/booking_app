import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class AdminCalendarScreen extends StatefulWidget {
  const AdminCalendarScreen({Key? key}) : super(key: key);

  @override
  State<AdminCalendarScreen> createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends State<AdminCalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _fetchBookingRequests();
  }

  Future<void> _fetchBookingRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('roomRequests')
          .orderBy('requestTime', descending: true)
          .get();

      Map<DateTime, List<Map<String, dynamic>>> events = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('bookingDate') && data['bookingDate'] != null) {
          final bookingDate = (data['bookingDate'] as Timestamp).toDate();
          final requestTime = (data['requestTime'] as Timestamp).toDate();
          final status = data['status'] as String;

          final event = {
            'roomName': data['roomName'] ?? 'Unknown Room',
            'status': status,
            'bookingTimeString': data['bookingTimeString'] ?? '',
            'floor': data['floor'] ?? '',
            'price': data['price'] ?? '',
            'userId': data['userId'] ?? '',
            'requestTime': requestTime,
            'roomId': data['roomId'] ?? '',
            'docId': doc.id,
          };

          final normalizedDate = DateTime(
            bookingDate.year,
            bookingDate.month,
            bookingDate.day,
          );

          if (events[normalizedDate] == null) {
            events[normalizedDate] = [];
          }
          events[normalizedDate]!.add(event);
        }
      }

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching booking requests: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleBookingAction(
    BuildContext context,
    String requestId,
    String roomId,
    String action,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final requestRef =
          FirebaseFirestore.instance.collection('roomRequests').doc(requestId);
      batch.update(requestRef, {'status': action});

      final roomRef =
          FirebaseFirestore.instance.collection('rooms').doc(roomId);
      batch.update(roomRef, {
        'is_booked': action == 'approved',
      });

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking ${action == 'approved' ? 'approved' : 'rejected'} successfully',
          ),
          backgroundColor: action == 'approved' ? Colors.green : Colors.red,
        ),
      );

      _fetchBookingRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              DateFormat('MMMM yyyy').format(_focusedDay),
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBookingRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                    CalendarFormat.twoWeeks: '2 weeks',
                    CalendarFormat.week: 'Week',
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: const CalendarStyle(
                    markerDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left),
                    rightChevronIcon: const Icon(Icons.chevron_right),
                    titleTextStyle: const TextStyle(fontSize: 17),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isNotEmpty) {
                        final eventList = events.cast<Map<String, dynamic>>();
                        final status = eventList.first['status'] as String;
                        final statusColor = _getStatusColor(status);

                        return Container(
                          margin: const EdgeInsets.all(4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          width: 16,
                          height: 16,
                          child: Center(
                            child: Text(
                              events.length.toString(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _getEventsForDay(_selectedDay).length,
                    itemBuilder: (context, index) {
                      final event = _getEventsForDay(_selectedDay)[index];
                      final status = event['status'] as String;
                      final requestTime = event['requestTime'] as DateTime;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ExpansionTile(
                          title: Text(
                            'Room: ${event['roomName']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDay)}',
                              ),
                              Text(
                                'Time: ${event['bookingTimeString']}',
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Request Details',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Floor: ${event['floor']}'),
                                  Text('Price: \$${event['price']}'),
                                  Text(
                                    'Requested: ${DateFormat('MMM dd, yyyy HH:mm').format(requestTime)}',
                                  ),
                                  Text('User ID: ${event['userId']}'),
                                  const SizedBox(height: 16),
                                  if (status == 'pending')
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _handleBookingAction(
                                            context,
                                            event['docId'],
                                            event['roomId'],
                                            'approved',
                                          ),
                                          icon: const Icon(Icons.check,
                                              color: Colors.white),
                                          label: const Text('Approve'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () => _handleBookingAction(
                                            context,
                                            event['docId'],
                                            event['roomId'],
                                            'rejected',
                                          ),
                                          icon: const Icon(Icons.close,
                                              color: Colors.white),
                                          label: const Text('Reject'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
