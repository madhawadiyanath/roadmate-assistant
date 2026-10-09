import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/config/firebase_state.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/models/service_request.dart';
import 'package:roadmate/screens/driver_dashboard_screen.dart';
import 'package:roadmate/screens/request_history_screen.dart';
import 'package:roadmate/services/assistance_service.dart';
import 'package:roadmate/services/notification_service.dart';
import 'package:roadmate/services/vehicle_service.dart';
import 'package:roadmate/widgets/request_history_widgets.dart';

const _uid = 'd1';

const _user = AppUser(
  uid: _uid,
  name: 'Kasun Perera',
  email: 'kasun@example.com',
  phone: '+94771234567',
  role: AppRole.driver,
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(920, 3200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home) => MaterialApp(home: home);

Future<void> _seed(
  FakeFirebaseFirestore db,
  String id, {
  required AssistanceType type,
  required RequestStatus status,
  required DateTime at,
  double fee = 0,
  String ref = '',
}) {
  return db.collection('requests').doc(id).set({
    'driverUid': _uid,
    'driverName': 'Kasun',
    'type': type.name,
    'status': status.name,
    'totalFee': fee,
    'refCode': ref,
    'createdAt': at,
  });
}

/// Same shape as the Figma frame: 5 requests, 3 completed, 1 cancelled.
Future<void> _seedFigma(FakeFirebaseFirestore db) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 9, 12);
  await _seed(db, 'a',
      type: AssistanceType.general,
      status: RequestStatus.accepted,
      at: today,
      fee: 4200,
      ref: '#RM1074');
  await _seed(db, 'b',
      type: AssistanceType.towing,
      status: RequestStatus.completed,
      at: DateTime(2026, 9, 28, 18, 40),
      fee: 3500,
      ref: '#RM1058');
  await _seed(db, 'c',
      type: AssistanceType.jumpStart,
      status: RequestStatus.completed,
      at: DateTime(2026, 9, 14, 8, 5),
      fee: 2200,
      ref: '#RM1031');
  await _seed(db, 'd',
      type: AssistanceType.flatTyre,
      status: RequestStatus.cancelled,
      at: DateTime(2026, 9, 2, 16, 30),
      ref: '#RM1019');
  await _seed(db, 'e',
      type: AssistanceType.general,
      status: RequestStatus.completed,
      at: DateTime(2026, 8, 19, 11, 20),
      fee: 6750,
      ref: '#RM0987');
}

void main() {
  late FakeFirebaseFirestore db;
  late AssistanceService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = AssistanceService(db: db);
  });

  test('amount, date and cost formatting', () {
    expect(formatAmount(3500), '3,500.00');
    expect(formatAmount(1234567.5), '1,234,567.50');
    expect(formatAmount(4200, decimals: 0), '4,200');
    expect(formatAmount(0), '0.00');

    final now = DateTime(2026, 10, 7, 12);
    expect(requestDateTimeLabel(DateTime(2026, 10, 7, 9, 12), now: now),
        'Today · 9:12 AM');
    expect(requestDateTimeLabel(DateTime(2026, 9, 28, 18, 40), now: now),
        '28 Sep 2026 · 6:40 PM');
    expect(requestDateTimeLabel(DateTime(2026, 9, 28, 0, 0), now: now),
        '28 Sep 2026 · 12:00 AM');
    expect(requestDateTimeLabel(null, now: now), 'Just now');

    ServiceRequest r(RequestStatus s, double fee) => ServiceRequest(
        id: 'x', driverUid: _uid, driverName: 'K', type: AssistanceType.towing,
        status: s, totalFee: fee);
    expect(requestCostLabel(r(RequestStatus.completed, 3500)), 'Rs. 3,500.00');
    expect(requestCostLabel(r(RequestStatus.cancelled, 3500)), 'No charge');
    expect(requestCostLabel(r(RequestStatus.accepted, 4200)), 'Est. Rs. 4,200');
    expect(requestCostLabel(r(RequestStatus.pending, 0)), 'Fee on completion');
  });

  testWidgets('Firebase not connected', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const RequestHistoryScreen(uid: _uid)));
    await tester.pumpAndSettle();
    expect(find.text('Request History'), findsOneWidget);
    expect(find.text('Firebase not connected'), findsOneWidget);
  });

  testWidgets('empty state', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
        _app(RequestHistoryScreen(uid: _uid, service: service)));
    await tester.pumpAndSettle();
    expect(find.text('No requests yet'), findsOneWidget);
    expect(find.text('All'), findsNothing);
  });

  testWidgets('filters with counts, cards, badges and costs', (tester) async {
    _phone(tester);
    await _seedFigma(db);
    await tester.pumpWidget(
        _app(RequestHistoryScreen(uid: _uid, service: service)));
    await tester.pumpAndSettle();

    // Tabs + counts (All 5 / Completed 3 / Cancelled 1).
    Finder tab(String label, int n) => find.descendant(
        of: find.ancestor(
            of: find.text(label), matching: find.byType(RequestFilterTab)),
        matching: find.text('$n'));
    expect(tab('All', 5), findsOneWidget);
    expect(tab('Completed', 3), findsOneWidget);
    expect(tab('Cancelled', 1), findsOneWidget);

    // Cards (newest first) with date/time, id, badge, cost.
    expect(find.byType(RequestHistoryCard), findsNWidgets(5));
    expect(find.text('Today · 9:12 AM'), findsOneWidget);
    expect(find.text('#RM1074'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Est. Rs. 4,200'), findsOneWidget);
    expect(find.text('Towing Service'), findsOneWidget);
    expect(find.text('28 Sep 2026 · 6:40 PM'), findsOneWidget);
    expect(find.text('Rs. 3,500.00'), findsOneWidget);
    expect(find.text('Completed'), findsNWidgets(4)); // 3 badges + the tab
    expect(find.text('Cancelled'), findsNWidgets(2)); // badge + the tab
    expect(find.text('No charge'), findsOneWidget);
    // Newest first.
    expect(tester.getTopLeft(find.text('#RM1074')).dy,
        lessThan(tester.getTopLeft(find.text('#RM1058')).dy));

    // Completed filter.
    await tester.tap(find.text('Completed').first);
    await tester.pumpAndSettle();
    expect(find.byType(RequestHistoryCard), findsNWidgets(3));
    expect(find.text('#RM1074'), findsNothing);
    expect(find.text('No charge'), findsNothing);

    // Cancelled filter.
    await tester.tap(find.text('Cancelled').first);
    await tester.pumpAndSettle();
    expect(find.byType(RequestHistoryCard), findsOneWidget);
    expect(find.text('#RM1019'), findsOneWidget);
    expect(find.text('No charge'), findsOneWidget);

    // Back to All.
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.byType(RequestHistoryCard), findsNWidgets(5));
  });

  testWidgets('a filter with no matches says so', (tester) async {
    _phone(tester);
    await _seed(db, 'a',
        type: AssistanceType.towing,
        status: RequestStatus.completed,
        at: DateTime(2026, 9, 28, 18, 40),
        fee: 3500,
        ref: '#RM1058');
    await tester.pumpWidget(
        _app(RequestHistoryScreen(uid: _uid, service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelled'));
    await tester.pumpAndSettle();
    expect(find.text('No cancelled requests'), findsOneWidget);
  });

  testWidgets('only this driver\'s requests; new ones appear live',
      (tester) async {
    _phone(tester);
    await db.collection('requests').doc('other').set({
      'driverUid': 'someone-else',
      'type': 'towing',
      'status': 'completed',
      'refCode': '#RM9999',
      'createdAt': DateTime(2026, 9, 1),
    });
    await tester.pumpWidget(
        _app(RequestHistoryScreen(uid: _uid, service: service)));
    await tester.pumpAndSettle();
    expect(find.text('#RM9999'), findsNothing);

    await service.createRequest(
      driverUid: _uid,
      driverName: 'Kasun',
      type: AssistanceType.flatTyre,
      refCode: '#RM2222',
    );
    await tester.pumpAndSettle();
    expect(find.text('#RM2222'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('cards open via onOpen', (tester) async {
    _phone(tester);
    await _seed(db, 'a',
        type: AssistanceType.towing,
        status: RequestStatus.accepted,
        at: DateTime(2026, 9, 28, 18, 40),
        ref: '#RM1058');
    ServiceRequest? opened;
    await tester.pumpWidget(_app(RequestHistoryScreen(
      uid: _uid,
      service: service,
      onOpen: (_, r) => opened = r,
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Towing Service'));
    expect(opened?.refCode, '#RM1058');
  });

  testWidgets('Requests tab links to the history page', (tester) async {
    _phone(tester);
    await _seedFigma(db);
    firebaseReady = true;
    addTearDown(() => firebaseReady = false);

    await tester.pumpWidget(_app(DriverDashboardScreen(
      user: _user,
      assistanceService: service,
      vehicleService: VehicleService(db: db),
      notificationService: NotificationService(db: db),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Request History'), findsOneWidget);
    expect(find.byType(RequestHistoryCard), findsNWidgets(5));

    // Tapping a finished request goes through the dashboard's tracking
    // handler, which explains its status. (Active ones open live tracking,
    // which needs a real Firebase.)
    await tester.tap(find.text('#RM1058'));
    await tester.pump();
    expect(find.text('Request completed.'), findsOneWidget);
  });
}
