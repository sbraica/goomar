import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const TireReplacementApp());
}

class TireReplacementApp extends StatelessWidget {
  const TireReplacementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zamjena guma - Rezervacije',
      theme: ThemeData(primarySwatch: Colors.blue),
      supportedLocales: const [
        Locale('hr'),
        Locale('en'),
      ],
      locale: const Locale('hr'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const BookingPage(),
    );
  }
}

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // Normalize a date to year-month-day (no time) for map keys
  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  // Build a compact hours summary for a given day (e.g., "09, 13, 15" or "+N")
  String _hoursSummaryForDay(DateTime day) {
    final slots = _bookings[_dayKey(day)] ?? const <String>[];
    if (slots.isEmpty) return '';
    // Extract start hour (HH) from strings like "09:00 - 10:00"
    final List<String> hours = [];
    for (final s in slots) {
      final parts = s.split('-');
      if (parts.isEmpty) continue;
      final start = parts.first.trim();
      // Use HH from HH:mm
      final hh = start.length >= 2 ? start.substring(0, 2) : start;
      if (!hours.contains(hh)) hours.add(hh);
    }
    const maxShow = 3;
    final show = hours.take(maxShow).toList();
    final remaining = hours.length - show.length;
    return remaining > 0 ? '${show.join(', ')} +$remaining' : show.join(', ');
  }

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedSlot;

  final List<String> _timeSlots = [
    "09:00 - 10:00",
    "10:00 - 11:00",
    "11:00 - 12:00",
    "13:00 - 14:00",
    "14:00 - 15:00",
    "15:00 - 16:00",
  ];

  final Map<DateTime, List<String>> _bookings = {};

  @override
  void initState() {
    super.initState();
    // Seed a demo booking so hours appear on the calendar immediately
    final todayKey = _dayKey(DateTime.now());
    final list = _bookings.putIfAbsent(todayKey, () => <String>[]);
    if (!list.contains("09:00 - 10:00")) {
      list.add("09:00 - 10:00");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rezervacija zamjene guma")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
        children: [
          TableCalendar(
            locale: 'hr_HR',
            focusedDay: _focusedDay,
            firstDay: DateTime.now(),
            lastDay: DateTime.utc(2030, 12, 31),
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: (day) {
              final key = _dayKey(day);
              return _bookings[key] ?? const [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                final summary = _hoursSummaryForDay(date);
                if (summary.isEmpty) return null;
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 52),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          summary,
                          style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.0, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedSlot = null; // reset when day changes
              });
            },
          ),
          const SizedBox(height: 16),
          if (_selectedDay != null) ...[
            Expanded(
              child: LayoutBuilder(
              builder: (context, constraints) {
                // Reduce slot selection width by ~one third on wide screens
                final double parentWidth = constraints.maxWidth;
                // Target 1/2 of available width, capped for readability on large screens
                final double targetWidth = parentWidth.isFinite
                    ? (parentWidth * 0.5).clamp(0.0, 640.0)
                    : 640.0;
                return Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: targetWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Odaberite termin:",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Expanded(
                                child: ListView.builder(
                                  itemCount: _timeSlots.length,
                                  itemBuilder: (context, index) {
                                    final slot = _timeSlots[index];
                                    final dayKey = _dayKey(_selectedDay!);
                                    final isBooked = (_bookings[dayKey] ?? const []).contains(slot);

                                    return ListTile(
                                      title: Text(slot),
                                      trailing: isBooked
                                          ? IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              tooltip: 'Ukloni termin',
                                              onPressed: () {
                                                setState(() {
                                                  final list = _bookings[dayKey];
                                                  if (list != null) {
                                                    list.clear();
                                                    _bookings.remove(dayKey);
                                                  }
                                                  if (_selectedSlot == slot) _selectedSlot = null;
                                                });
                                              },
                                            )
                                          : TextButton.icon(
                                              icon: const Icon(Icons.add_circle_outline),
                                              label: const Text('Dodaj'),
                                              onPressed: () {
                                                setState(() {
                                                  // Enforce single-slot per day: replace any existing with this slot
                                                  _bookings[dayKey] = <String>[slot];
                                                  _selectedSlot = null;
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Odabran termin: $slot')),
                                                );
                                              },
                                            ),
                                      onTap: isBooked
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedSlot = slot;
                                              });
                                            },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _selectedSlot == null
                              ? null
                              : () {
                                  setState(() {
                                    final key = _dayKey(_selectedDay!);
                                    // Enforce single-slot per day: replace any existing with selected
                                    _bookings[key] = <String>[_selectedSlot!];
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "Rezerviran termin ${_selectedSlot!} na datum ${_selectedDay!.toLocal().toString().split(' ')[0]}"),
                                      ),
                                    );
                                  });
                                },
                          child: const Text("Potvrdi rezervaciju"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
              ),
          ] else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Odaberite datum kako biste vidjeli dostupne termine"),
            ),
        ],
            ),
          ),
        ),
      ),
    );
  }
}
