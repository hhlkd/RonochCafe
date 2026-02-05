import 'package:flutter/material.dart';
import 'package:ronoch_coffee/services/mockapi_service.dart';
import 'package:ronoch_coffee/services/user_session.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Information')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getDebugInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDebugCard('User Session', data['session']),
                const SizedBox(height: 20),
                _buildDebugCard('MockAPI Users', data['users']),
                const SizedBox(height: 20),
                _buildDebugCard('Orders', data['orders']),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDebugCard(String title, String content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SelectableText(
              content,
              style: const TextStyle(fontFamily: 'Monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getDebugInfo() async {
    // Get session info
    final session = await UserSession.getUser();

    // Get all users
    final users = await MockApiService.getUsers();

    // Get orders for current user
    final orders =
        session['userId'] != null
            ? await MockApiService.getUserOrders(session['userId']!)
            : [];

    return {
      'session':
          'User ID: ${session['userId']}\n'
          'Username: ${session['userName']}\n'
          'Email: ${session['userEmail']}',

      'users': users
          .map(
            (user) =>
                'ID: ${user.id} | Username: ${user.username} | Email: ${user.email} | Points: ${user.point}',
          )
          .join('\n'),

      'orders':
          orders.isEmpty
              ? 'No orders found for user ${session['userId']}'
              : orders
                  .map(
                    (order) =>
                        'Order ID: ${order.id}\n'
                        'User ID: ${order.userId}\n'
                        'Items: ${order.items.length}\n'
                        'Total: \$${order.total}\n'
                        'Status: ${order.status}\n'
                        'Created: ${order.createdAt}\n'
                        '---',
                  )
                  .join('\n'),
    };
  }
}
