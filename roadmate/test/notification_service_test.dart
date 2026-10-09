import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/notification_item.dart';
import 'package:roadmate/services/notification_service.dart';

void main() {
  test('type parsing handles new, legacy and unknown values', () {
    expect(NotificationType.fromString('arriving'), NotificationType.arriving);
    expect(NotificationType.fromString('request_accepted'),
        NotificationType.accepted);
    expect(NotificationType.fromString('chat_message'), NotificationType.message);
    expect(NotificationType.fromString('general'), NotificationType.message);
    expect(NotificationType.fromString(null), NotificationType.message);
  });

  test('legacy AppNotificationItem name is the same model', () {
    const AppNotificationItem n = AppNotification(
        id: '1', type: NotificationType.receipt, title: 't', body: 'b');
    expect(n, isA<AppNotification>());
  });

  test('send stamps senderUid, lands unread in the recipient inbox', () async {
    final db = FakeFirebaseFirestore();
    final service = NotificationService(db: db);

    final id = await service.send(
      recipientUid: 'driver1',
      senderUid: 'mech1',
      type: NotificationType.arriving,
      title: 'Technician is arriving',
      body: 'Patrol Unit #04 is about 4 minutes away.',
      requestId: 'req1',
    );
    expect(id, isNotNull);

    final inbox = await service.watchUserNotifications('driver1').first;
    expect(inbox, hasLength(1));
    expect(inbox.single.senderUid, 'mech1');
    expect(inbox.single.type, NotificationType.arriving);
    expect(inbox.single.read, isFalse);
    expect(inbox.single.requestId, 'req1');
    // Sender's own inbox is untouched.
    expect(await service.watchUserNotifications('mech1').first, isEmpty);
    // No recipient → nothing written.
    expect(
      await service.send(
          recipientUid: ' ',
          senderUid: 'mech1',
          type: NotificationType.message,
          title: 't',
          body: 'b'),
      isNull,
    );
  });

  test('markRead and markAllRead', () async {
    final db = FakeFirebaseFirestore();
    final service = NotificationService(db: db);
    final ids = <String>[];
    for (final t in [
      NotificationType.accepted,
      NotificationType.message,
      NotificationType.completed,
    ]) {
      ids.add((await service.send(
        recipientUid: 'u1',
        senderUid: 's1',
        type: t,
        title: t.name,
        body: 'x',
      ))!);
    }

    await service.markRead('u1', ids.first);
    var inbox = await service.watchUserNotifications('u1').first;
    expect(inbox.where((n) => n.read), hasLength(1));
    expect(inbox.firstWhere((n) => n.id == ids.first).read, isTrue);

    await service.markAllRead('u1');
    inbox = await service.watchUserNotifications('u1').first;
    expect(inbox.every((n) => n.read), isTrue);

    // Nothing unread → no-op, no error.
    await service.markAllRead('u1');
    await service.markAllRead('nobody');
  });

  test('inbox is newest first', () async {
    final db = FakeFirebaseFirestore();
    final col = db.collection('users').doc('u1').collection('notifications');
    await col.doc('old').set({
      'type': 'receipt',
      'title': 'old',
      'body': '',
      'read': true,
      'senderUid': 's',
      'createdAt': DateTime(2026, 5, 1),
    });
    await col.doc('new').set({
      'type': 'completed',
      'title': 'new',
      'body': '',
      'read': false,
      'senderUid': 's',
      'createdAt': DateTime(2026, 5, 2),
    });
    final inbox =
        await NotificationService(db: db).watchUserNotifications('u1').first;
    expect(inbox.map((n) => n.id), ['new', 'old']);
  });

  test('request accepted / chat helpers write typed, stamped entries',
      () async {
    final db = FakeFirebaseFirestore();
    final service = NotificationService(db: db);

    await service.createRequestAccepted(
      driverUid: 'd1',
      mechanicName: 'Nimal',
      senderUid: 'm1',
      requestId: 'r1',
    );
    await service.createChatMessage(
      recipientUid: 'd1',
      senderName: 'Nimal',
      text: ' On my way ',
      senderUid: 'm1',
      requestId: 'r1',
    );

    final inbox = await service.watchUserNotifications('d1').first;
    expect(inbox, hasLength(2));
    final accepted = inbox.firstWhere((n) => n.type == NotificationType.accepted);
    expect(accepted.title, 'Request accepted');
    expect(accepted.body, contains('Nimal'));
    expect(accepted.senderUid, 'm1');
    final msg = inbox.firstWhere((n) => n.type == NotificationType.message);
    expect(msg.body, 'Nimal: On my way');
  });
}
