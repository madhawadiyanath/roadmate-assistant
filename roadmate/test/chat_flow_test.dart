import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/service_request.dart';
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

  test('own message can be edited and deleted', () async {
    final db = FakeFirebaseFirestore();
    final chat = ChatService(db: db);
    const reqId = 'req1';

    await chat.send(
      requestId: reqId,
      senderUid: 'driver1',
      senderName: 'Kasun',
      senderRole: 'driver',
      text: 'Hello',
    );
    var msgs = await chat.watch(reqId).first;
    expect(msgs, hasLength(1));
    final id = msgs.first.id;

    // Edit marks the message edited with new text.
    await chat.edit(requestId: reqId, messageId: id, newText: 'Hello!!');
    msgs = await chat.watch(reqId).first;
    expect(msgs.first.text, 'Hello!!');
    expect(msgs.first.edited, isTrue);

    // Blank edits are ignored.
    await chat.edit(requestId: reqId, messageId: id, newText: '   ');
    msgs = await chat.watch(reqId).first;
    expect(msgs.first.text, 'Hello!!');

    // Delete removes it.
    await chat.remove(requestId: reqId, messageId: id);
    msgs = await chat.watch(reqId).first;
    expect(msgs, isEmpty);
  });

  test('send stamps thread preview; seen tracking drives hasUnread',
      () async {
    final db = FakeFirebaseFirestore();
    final chat = ChatService(db: db);
    const reqId = 'req1';
    await db.collection('requests').doc(reqId).set({
      'driverUid': 'driver1',
      'driverName': 'Kasun',
      'mechanicUid': 'mech1',
      'mechanicName': 'Nimal',
      'status': 'accepted',
      'type': 'flatTyre',
      'refCode': '#RM1058',
      'createdAt': DateTime(2026, 9, 28, 18, 40),
    });
    await db.collection('users').doc('driver1').set({
      'name': 'Kasun',
      'email': 'kasun@example.com',
      'phone': '',
      'role': 'driver',
    });

    await chat.send(
      requestId: reqId,
      senderUid: 'mech1',
      senderName: 'Nimal',
      senderRole: 'mechanic',
      text: 'On my way, 10 mins',
    );

    final parent =
        (await db.collection('requests').doc(reqId).get()).data()!;
    expect(parent['lastMessageText'], 'On my way, 10 mins');
    expect(parent['lastMessageSenderUid'], 'mech1');
    expect(parent['lastMessageAt'], isNotNull);

    ServiceRequest thread() => ServiceRequest(
          id: reqId,
          driverUid: 'driver1',
          driverName: 'Kasun',
          type: AssistanceType.flatTyre,
          status: RequestStatus.accepted,
          lastMessageText: 'On my way, 10 mins',
          lastMessageAt: DateTime(2026, 10, 1, 10, 0),
          lastMessageSenderUid: 'mech1',
        );

    // Nobody has seen it yet: unread for the driver, not for Nimal.
    var seen = await chat.watchSeen('driver1').first;
    expect(seen, isEmpty);
    expect(thread().hasUnread('driver1', seen), isTrue);
    expect(thread().hasUnread('mech1', seen), isFalse);

    // Driver opens the thread → badge clears.
    await chat.markSeen(uid: 'driver1', requestId: reqId);
    seen = await chat.watchSeen('driver1').first;
    expect(seen[reqId], isNotNull);
    expect(thread().hasUnread('driver1', seen), isFalse);

    // A thread with no messages is never unread.
    const quiet = ServiceRequest(
      id: 'req2',
      driverUid: 'driver1',
      driverName: 'Kasun',
      type: AssistanceType.flatTyre,
      status: RequestStatus.accepted,
    );
    expect(quiet.hasUnread('driver1', seen), isFalse);
  });
}
