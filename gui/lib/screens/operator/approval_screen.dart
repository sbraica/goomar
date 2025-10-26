import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/reservation_card.dart';
import '../../providers/approval_ui_provider.dart';

class ApprovalScreen extends StatelessWidget {
  const ApprovalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reservationProvider = Provider.of<ReservationProvider>(context);

    return Scaffold(
        appBar: AppBar(title: const Text('Reservation Management'), actions: [
          Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                  child: Chip(
                      avatar: const Icon(Icons.person, size: 16, color: Colors.white),
                      label: Text(authProvider.currentUser?.username ?? 'Operator', style: const TextStyle(color: Colors.white)),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8)))),
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                _showConfirmDialog(context, 'Logout', 'Are you sure you want to logout?', () {
                  authProvider.logout();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                });
              })
        ]),
        body: Column(children: [
          Container(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(children: [
                Expanded(child: _buildTabButton(context, 'Pending', 0, reservationProvider.pendingReservations.length)),
                Expanded(child: _buildTabButton(context, 'Approved', 1, reservationProvider.approvedReservations.length))
              ])),
          Expanded(child: Provider.of<ApprovalUiProvider>(context).selectedIndex == 0 ? _buildPendingList(reservationProvider) : _buildApprovedList(reservationProvider))
        ]));
  }

  Widget _buildTabButton(BuildContext context, String title, int index, int count) {
    final ui = Provider.of<ApprovalUiProvider>(context);
    final isSelected = ui.selectedIndex == index;
    return InkWell(
        onTap: () => ui.selectTab(index),
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, width: 3))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(title,
                  style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Theme.of(context).primaryColor : Colors.grey)),
              const SizedBox(width: 8),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: isSelected ? Theme.of(context).primaryColor : Colors.grey, borderRadius: BorderRadius.circular(12)),
                  child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))
            ])));
  }

  Widget _buildPendingList(ReservationProvider provider) {
    final pending = provider.pendingReservations;

    if (pending.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        Text('No pending reservations', style: TextStyle(fontSize: 18, color: Colors.grey))
      ]));
    }

    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pending.length,
        itemBuilder: (context, index) {
          final reservation = pending[index];
          return ReservationCard(
              reservation: reservation,
              onApprove: () {
                _showConfirmDialog(context, 'Approve Reservation', 'Are you sure you want to approve this reservation?', () {
                  provider.approveReservation(reservation.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reservation for ${reservation.name} approved'), backgroundColor: Colors.green));
                });
              },
              onReject: () {
                _showConfirmDialog(context, 'Reject Reservation', 'Are you sure you want to reject this reservation?', () {
                  provider.rejectReservation(reservation.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reservation for ${reservation.name} rejected'), backgroundColor: Colors.red));
                });
              });
        });
  }

  Widget _buildApprovedList(ReservationProvider provider) {
    final approved = provider.approvedReservations;

    if (approved.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        Text('No approved reservations yet', style: TextStyle(fontSize: 18, color: Colors.grey))
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: approved.length,
      itemBuilder: (context, index) {
        final reservation = approved[index];
        return ReservationCard(reservation: reservation, isApproved: true);
      },
    );
  }

  void _showConfirmDialog(BuildContext context, String title, String message, VoidCallback onConfirm) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(title: Text(title), content: Text(message), actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onConfirm();
                  },
                  child: const Text('Confirm'))
            ]));
  }
}
