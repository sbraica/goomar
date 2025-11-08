import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isApproved;

  const ReservationCard({Key? key, required this.reservation, this.onApprove, this.onReject, this.isApproved = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isApproved ? Colors.green : Colors.orange, width: 2)),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                    backgroundColor: isApproved ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    child: Icon(isApproved ? Icons.check_circle : Icons.pending, color: isApproved ? Colors.green : Colors.orange)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(reservation.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(isApproved ? 'Approved' : 'Pending Approval', style: TextStyle(fontSize: 12, color: isApproved ? Colors.green : Colors.orange, fontWeight: FontWeight.w500))
                ])),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration:
                        BoxDecoration(color: reservation.long ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(reservation.long ? "Dugi" : "Kratki",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: reservation.long ? Colors.blue : Colors.purple)))
              ]),
              const Divider(height: 24),
              _buildInfoRow(Icons.email, 'Email', reservation.email),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, 'Phone', reservation.phone),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.calendar_today, 'Appointment', '${DateFormat('d. MMMM y.', 'hr').format(reservation.date_time)}'),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.access_time,
                'Submitted',
                DateFormat('d. MMM y. - HH:mm', 'hr').format(reservation.date_time),
              ),
              if (!isApproved && (onApprove != null || onReject != null)) ...[
                const Divider(height: 24),
                Row(children: [
                  if (onReject != null)
                    Expanded(
                        child: OutlinedButton.icon(
                            onPressed: onReject,
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
                  if (onReject != null && onApprove != null) const SizedBox(width: 12),
                  if (onApprove != null)
                    Expanded(
                        child: ElevatedButton.icon(
                            onPressed: onApprove,
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))))
                ])
              ]
            ])));
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.grey),
      const SizedBox(width: 8),
      Text('$label: ', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)))
    ]);
  }
}
