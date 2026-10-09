import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/app_notification.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/models/emergency_contact.dart';
import 'package:roadmate/screens/driver_dashboard_screen.dart';
import 'package:roadmate/screens/emergency_contacts_screen.dart';
import 'package:roadmate/screens/notifications_screen.dart';
import 'package:roadmate/screens/profile_screen.dart';
import 'package:roadmate/services/emergency_contact_service.dart';
import 'package:roadmate/services/notification_service.dart';
import 'package:roadmate/widgets/notification_widgets.dart';

const _uid = 'u1';

const _user = AppUser(
  uid: _uid,
  name: 'Kasun Perera',
  email: 'kasun@example.com',
  phone: '+94771234567',
  role: AppRole.driver,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(920, 1800);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home) => MaterialApp(home: home);

Future<void> _tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _dismissSnackBars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  late FakeFirebaseFirestore db;

  setUp(() {
    db = FakeFirebaseFirestore();
  });

  group('time labels', () {
    final now = DateTime(2026, 10, 7, 15, 30);
    test('today / yesterday / older', () {
      expect(notificationTimeLabel(null, now: now), 'Just now');
      expect(notificationTimeLabel(DateTime(2026, 10, 7, 15, 29, 40), now: now),
          'Just now');
      expect(notificationTimeLabel(DateTime(2026, 10, 7, 15, 28), now: now),
          '2 min ago');
      expect(notificationTimeLabel(DateTime(2026, 10, 7, 12, 30), now: now),
          '3 hr ago');
      expect(notificationTimeLabel(DateTime(2026, 10, 6, 18, 52), now: now),
          'Yesterday · 6:52 PM');
      expect(notificationTimeLabel(DateTime(2026, 3, 12, 0, 5), now: now),
          '12 Mar · 12:05 AM');
    });
  });

  group('Emergency Contacts screen', () {
    late EmergencyContactService service;
    setUp(() => service = EmergencyContactService(db: db));

    testWidgets('Firebase not connected', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(const EmergencyContactsScreen(uid: _uid)));
      await tester.pumpAndSettle();
      expect(find.text('Emergency Contacts'), findsOneWidget);
      expect(find.text('Firebase not connected'), findsOneWidget);
      expect(find.text('Add Emergency Contact'), findsOneWidget);
    });

    testWidgets('empty state', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
          _app(EmergencyContactsScreen(uid: _uid, service: service)));
      await tester.pumpAndSettle();
      expect(find.text('No emergency contacts yet'), findsOneWidget);
    });

    testWidgets('lists contacts with initials and relation', (tester) async {
      _phone(tester);
      await service.addContact(
          _uid,
          const EmergencyContact(
              id: '', name: 'Kamala Perera', phone: '+94 77 234 5678'));
      await service.addContact(
          _uid,
          const EmergencyContact(
              id: '',
              name: 'Ruwan Silva',
              phone: '+94 76 456 7890',
              relation: ContactRelation.friend));
      await tester.pumpWidget(
          _app(EmergencyContactsScreen(uid: _uid, service: service)));
      await tester.pumpAndSettle();

      expect(find.text('People we notify with your live location when you '
          'request urgent help.'), findsOneWidget);
      expect(find.text('Kamala Perera'), findsOneWidget);
      expect(find.text('KP'), findsOneWidget);
      expect(find.text('RS'), findsOneWidget);
      expect(find.text('+94 76 456 7890'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Friend'), findsOneWidget);
    });

    testWidgets('add validates, then saves', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
          _app(EmergencyContactsScreen(uid: _uid, service: service)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Emergency Contact'));
      await tester.pumpAndSettle();
      expect(find.text('Add Contact'), findsOneWidget);

      await _tapVisible(tester, find.text('Save Contact'));
      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.text('Enter a phone number'), findsOneWidget);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Dilini Perera');
      await tester.enterText(fields.at(1), '12');
      await _tapVisible(tester, find.text('Save Contact'));
      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(find.text('Enter a name'), findsNothing);

      await tester.enterText(fields.at(1), '+94 71 345 6789');
      await tester.tap(find.text('Spouse'));
      await tester.pump();
      await _tapVisible(tester, find.text('Save Contact'));

      expect(find.text('Emergency Contacts'), findsOneWidget);
      expect(find.text('Dilini Perera'), findsOneWidget);
      expect(find.text('DP'), findsOneWidget);
      expect(find.text('Spouse'), findsOneWidget);
      final saved = (await service.watchContacts(_uid).first).single;
      expect(saved.relation, ContactRelation.spouse);
      expect(saved.phone, '+94 71 345 6789');
    });

    testWidgets('edit updates in place', (tester) async {
      _phone(tester);
      await service.addContact(
          _uid,
          const EmergencyContact(
              id: '', name: 'Sunil Fernando', phone: '+94705678901'));
      await tester.pumpWidget(
          _app(EmergencyContactsScreen(uid: _uid, service: service)));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Edit Sunil Fernando'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Contact'), findsOneWidget);
      expect(find.text('Sunil Fernando'), findsOneWidget); // prefilled
      await tester.enterText(find.byType(TextField).at(0), 'Sunil F');
      await tester.tap(find.text('Colleague'));
      await tester.pump();
      await _tapVisible(tester, find.text('Save Changes'));

      expect(find.text('Sunil F'), findsOneWidget);
      expect(find.text('SF'), findsOneWidget);
      expect(find.text('Colleague'), findsOneWidget);
      expect(await service.watchContacts(_uid).first, hasLength(1));
    });

    testWidgets('delete asks first', (tester) async {
      _phone(tester);
      await service.addContact(_uid,
          const EmergencyContact(id: '', name: 'Kamala Perera', phone: '0771234567'));
      await tester.pumpWidget(
          _app(EmergencyContactsScreen(uid: _uid, service: service)));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete Kamala Perera'));
      await tester.pumpAndSettle();
      expect(find.text('Delete contact?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Kamala Perera'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete Kamala Perera'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Delete')));
      await tester.pumpAndSettle();
      expect(find.text('Kamala Perera'), findsNothing);
      expect(find.text('No emergency contacts yet'), findsOneWidget);
    });

    testWidgets('Profile links to it for drivers only', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(const ProfileScreen(user: _user)));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Emergency Contacts'));
      expect(find.text('Add Emergency Contact'), findsOneWidget);

      // Fresh app, so the pushed page does not linger in the navigator.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(const ProfileScreen(
          user: AppUser(
              uid: 'm1',
              name: 'Nimal',
              email: 'n@e.com',
              phone: '',
              role: AppRole.mechanic))));
      await tester.pumpAndSettle();
      expect(find.text('Emergency Contacts'), findsNothing);
    });
  });

  group('Notifications screen', () {
    late NotificationService service;
    setUp(() => service = NotificationService(db: db));

    Future<void> seed(String id, NotificationType t, String title,
        {bool read = false, required DateTime at}) {
      return db
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .doc(id)
          .set({
        'type': t.name,
        'title': title,
        'body': 'body of $title',
        'read': read,
        'senderUid': 's1',
        'createdAt': at,
      });
    }

    testWidgets('Firebase not connected', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(const NotificationsScreen(uid: _uid)));
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Firebase not connected'), findsOneWidget);
      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('empty state', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
          _app(NotificationsScreen(uid: _uid, service: service)));
      await tester.pumpAndSettle();
      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('groups Today / Earlier, shows unread count, marks read',
        (tester) async {
      _phone(tester);
      final now = DateTime.now();
      await seed('a', NotificationType.accepted, 'Mechanic accepted',
          at: now.subtract(const Duration(minutes: 2)));
      await seed('b', NotificationType.message, 'New message',
          at: now.subtract(const Duration(minutes: 12)));
      await seed('c', NotificationType.completed, 'Job completed',
          read: true, at: now.subtract(const Duration(days: 3)));
      await tester.pumpWidget(
          _app(NotificationsScreen(uid: _uid, service: service)));
      await tester.pumpAndSettle();

      expect(find.text('2 unread'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('EARLIER'), findsOneWidget);
      expect(find.text('Mechanic accepted'), findsOneWidget);
      expect(find.text('body of Job completed'), findsOneWidget);
      expect(find.text('2 min ago'), findsOneWidget);
      expect(find.byKey(const Key('unread-dot')), findsNWidgets(2));
      expect(find.text('Mark all read'), findsOneWidget);

      // Tapping an unread row marks only that one read.
      await tester.tap(find.text('New message'));
      await tester.pumpAndSettle();
      expect(find.text('1 unread'), findsOneWidget);
      expect(find.byKey(const Key('unread-dot')), findsOneWidget);

      // Tapping a read row changes nothing.
      await tester.tap(find.text('Job completed'));
      await tester.pumpAndSettle();
      expect(find.text('1 unread'), findsOneWidget);

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();
      expect(find.text('You are all caught up'), findsOneWidget);
      expect(find.byKey(const Key('unread-dot')), findsNothing);
      expect(find.text('Mark all read'), findsNothing);
      final inbox = await service.watchUserNotifications(_uid).first;
      expect(inbox.every((n) => n.read), isTrue);
    });

    testWidgets('a new notification appears live', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
          _app(NotificationsScreen(uid: _uid, service: service)));
      await tester.pumpAndSettle();
      expect(find.text('No notifications yet'), findsOneWidget);

      await service.send(
        recipientUid: _uid,
        senderUid: 'mech1',
        type: NotificationType.arriving,
        title: 'Technician is arriving',
        body: 'Patrol Unit #04 is about 4 minutes away.',
      );
      await tester.pumpAndSettle();
      expect(find.text('Technician is arriving'), findsOneWidget);
      expect(find.text('1 unread'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);
    });
  });

  group('driver dashboard bell', () {
    testWidgets('dot shows only with unread; bell opens the page',
        (tester) async {
      _phone(tester);
      final service = NotificationService(db: db);
      await tester.pumpWidget(_app(DriverDashboardScreen(
        user: _user,
        notificationService: service,
      )));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bell-dot')), findsNothing);

      final id = await service.send(
        recipientUid: _uid,
        senderUid: 'mech1',
        type: NotificationType.accepted,
        title: 'Request accepted',
        body: 'Nimal is on the way.',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bell-dot')), findsOneWidget);

      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Request accepted'), findsOneWidget);

      await tester.tap(find.text('Request accepted'));
      await tester.pumpAndSettle();
      expect(id, isNotNull);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bell-dot')), findsNothing);
      await _dismissSnackBars(tester);
    });
  });
}
