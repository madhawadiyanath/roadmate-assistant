import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/services/chat_service.dart';

/// Driver ↔ mechanic chat on one request: both sides send, both see all.
void main() {
  test('chat messages flow both ways in order', () async {
    final db = FakeFirebaseFirestore();
    final chat = ChatService(db: db);
    const reqId = 'req1';

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
  });
}
