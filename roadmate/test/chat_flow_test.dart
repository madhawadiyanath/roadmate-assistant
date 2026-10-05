import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/services/chat_service.dart';
import 'package:roadmate/services/notification_service.dart';

/// Driver ↔ mechanic chat on one request: both sides send, both see all.
void main() {
  test('chat messages flow both ways in order', () async {
    final db = FakeFirebaseFirestore();
    final chat = ChatService(db: db);
    final notifications = NotificationService(db: db);
    const reqId = 'req1';

    await db.collection('requests').doc(reqId).set({
      'driverUid': 'driver1',
      'driverName': 'Kasun',
      'mechanicUid': 'mech1',
      'mechanicName': 'Nimal',
      'status': 'accepted',
      'type': 'towing',
      'address': 'Mile Post 42',
      'refCode': '#RM1234',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chat.send(
      requestId: reqId,
      senderUid: 'driver1',
      senderName: 'Kasun',
      senderRole: 'driver',
      text: 'Hello, I am near Mile Post 42',
    );
    await chat.send(
      requestId: reqId,
      senderUid: 'mech1',
      senderName: 'Nimal',
      senderRole: 'mechanic',
      text: 'On my way, 10 mins',
    );
    // Empty text is ignored.
    await chat.send(
      requestId: reqId,
      senderUid: 'driver1',
      senderName: 'Kasun',
      senderRole: 'driver',
      text: '   ',
    );

    final msgs = await chat.watch(reqId).first;
    expect(msgs, hasLength(2));
    expect(msgs[0].text, 'Hello, I am near Mile Post 42');
    expect(msgs[0].senderRole, 'driver');
    expect(msgs[1].text, 'On my way, 10 mins');
    expect(msgs[1].senderRole, 'mechanic');

    final mechAlerts = await notifications.watchUserNotifications('mech1').first;
    expect(mechAlerts, isNotEmpty);
    expect(mechAlerts.first.title, 'New chat message');
    expect(mechAlerts.first.body, contains('Kasun'));
  });
}
