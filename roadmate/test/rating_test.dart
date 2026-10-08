import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/config/firebase_state.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/models/rating_summary.dart';
import 'package:roadmate/models/service_request.dart';
import 'package:roadmate/screens/job_details_screen.dart';
import 'package:roadmate/screens/mechanic_dashboard_screen.dart';
import 'package:roadmate/screens/payment_review_screen.dart';
import 'package:roadmate/screens/rate_request_screen.dart';
import 'package:roadmate/screens/request_history_screen.dart';
import 'package:roadmate/screens/request_success_screen.dart';
import 'package:roadmate/services/assistance_service.dart';
import 'package:roadmate/services/notification_service.dart';
import 'package:roadmate/services/payment_service.dart';
import 'package:roadmate/services/vehicle_service.dart';
import 'package:roadmate/widgets/rating_widgets.dart';
import 'package:roadmate/widgets/request_history_widgets.dart';

const _uid = 'd1';

const _driver = AppUser(
  uid: _uid,
  name: 'Kasun Perera',
  email: 'kasun@example.com',
  phone: '',
  role: AppRole.driver,
);

void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 2800);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Future<void> _tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

ServiceRequest _req({
  String id = 'r1',
  RequestStatus status = RequestStatus.completed,
  int rating = 0,
  DateTime? ratedAt,
  String mechanicName = 'Nimal Perera',
}) =>
    ServiceRequest(
      id: id,
      driverUid: _uid,
      driverName: 'Kasun',
      type: AssistanceType.towing,
      status: status,
      mechanicUid: 'm1',
      mechanicName: mechanicName,
      totalFee: 8500,
      rating: rating,
      ratedAt: ratedAt,
      refCode: '#RM1058',
    );

void main() {
  late FakeFirebaseFirestore db;
  late AssistanceService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = AssistanceService(db: db);
    firebaseReady = false;
  });
  tearDown(() => firebaseReady = false);

  Future<String> seed({
    String status = 'completed',
    int rating = 0,
    DateTime? ratedAt,
    String mechanicUid = 'm1',
    DateTime? createdAt,
    String ref = '#RM1058',
  }) async {
    final doc = await db.collection('requests').add({
      'driverUid': _uid,
      'driverName': 'Kasun',
      'type': 'towing',
      'status': status,
      'mechanicUid': mechanicUid,
      'mechanicName': 'Nimal Perera',
      'totalFee': 8500.0,
      'rating': rating,
      'feedback': '',
      'tags': <String>[],
      'refCode': ref,
      'createdAt': createdAt ?? DateTime(2026, 9, 28, 18, 40),
      'ratedAt': ?ratedAt,
    });
    return doc.id;
  }

  Future<Map<String, dynamic>> doc(String id) async =>
      (await db.collection('requests').doc(id).get()).data()!;

  group('AssistanceService.rateRequest', () {
    test('writes rating, trimmed feedback, tags and ratedAt', () async {
      final id = await seed();
      await service.rateRequest(
        requestId: id,
        rating: 4,
        feedback: '  Quick and polite  ',
        tags: const ['Fast Arrival', 'Polite'],
      );
      final d = await doc(id);
      expect(d['rating'], 4);
      expect(d['feedback'], 'Quick and polite');
      expect(d['tags'], ['Fast Arrival', 'Polite']);
      expect(d['ratedAt'], isA<Timestamp>());
      // Nothing else was touched.
      expect(d['status'], 'completed');
      expect(d['driverUid'], _uid);

      final r = (await service.watchDriverRequests(_uid).first).single;
      expect(r.isRated, isTrue);
      expect(r.tags, ['Fast Arrival', 'Polite']);
    });

    test('rating must be 1–5 and nothing is written otherwise', () async {
      final id = await seed();
      for (final bad in [0, -1, 6]) {
        expect(() => service.rateRequest(requestId: id, rating: bad),
            throwsArgumentError);
      }
      expect((await doc(id))['rating'], 0);
      expect((await doc(id)).containsKey('ratedAt'), isFalse);
    });

    test('a default rating without ratedAt is NOT a rating', () async {
      // Requests made before this screen existed carry rating 4.
      await seed(rating: 4);
      final r = (await service.watchDriverRequests(_uid).first).single;
      expect(r.rating, 4);
      expect(r.isRated, isFalse);
    });
  });

  group('Firestore rules contract', () {
    test('rules allow exactly the fields rateRequest writes', () async {
      final rules = File('../firestore.rules').readAsStringSync();
      final start = rules.indexOf('// Driver rates their own completed');
      expect(start, greaterThan(0));
      final clause = rules.substring(start, rules.indexOf('// Assigned mechanic'));

      expect(clause, contains("resource.data.status == 'completed'"));
      expect(clause, contains("resource.data.driverUid == request.auth.uid"));
      expect(clause, contains("!('ratedAt' in resource.data)")); // once only
      expect(clause, contains('request.resource.data.rating >= 1'));
      expect(clause, contains('request.resource.data.rating <= 5'));

      final allowed = RegExp(r"hasOnly\(\[(.*?)\]\)")
          .firstMatch(clause)!
          .group(1)!
          .split(',')
          .map((e) => e.trim().replaceAll("'", ''))
          .toSet();

      final id = await seed();
      final before = await doc(id);
      await service.rateRequest(requestId: id, rating: 5, tags: const ['Polite']);
      final after = await doc(id);
      final changed = {
        for (final k in after.keys)
          if (!before.containsKey(k) || before[k] != after[k]) k
      };
      expect(allowed, {'rating', 'feedback', 'tags', 'ratedAt'});
      expect(changed.difference(allowed), isEmpty,
          reason: 'service writes a field the rules would reject');
    });
  });

  group('RatingSummary', () {
    test('averages only completed, genuinely rated requests', () {
      final t = DateTime(2026, 10, 1);
      final s = RatingSummary.from([
        _req(rating: 5, ratedAt: t),
        _req(rating: 4, ratedAt: t),
        _req(rating: 4), // legacy default, no ratedAt
        _req(rating: 1, ratedAt: t, status: RequestStatus.cancelled),
        _req(), // not rated
      ]);
      expect(s.count, 2);
      expect(s.average, 4.5);
      expect(s.averageText, '4.5');
      expect(s.label, '4.5 (2 reviews)');
      expect(RatingSummary.from([_req(rating: 3, ratedAt: t)]).label,
          '3.0 (1 review)');
    });

    test('nobody rated yet', () {
      final s = RatingSummary.from([_req(), _req(rating: 4)]);
      expect(s.hasRatings, isFalse);
      expect(s.averageText, '—');
      expect(s.label, 'No ratings yet');
      expect(RatingSummary.from(const []).label, 'No ratings yet');
    });
  });

  group('Payment screen no longer rates', () {
    Future<void> pumpPayment(WidgetTester tester) async {
      _tallPhone(tester);
      firebaseReady = true;
      await tester.pumpWidget(MaterialApp(
        home: PaymentReviewScreen(
          user: _driver,
          serviceType: AssistanceType.flatTyre,
          address: 'No. 25, Galle Road',
          assistanceService: service,
          vehicleService: VehicleService(db: db),
          paymentService: PaymentService(db: db),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('no stars, feedback or tags — payment parts untouched',
        (tester) async {
      await pumpPayment(tester);
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Rate Your Experience'), findsNothing);
      expect(find.text('Tap star to rate'), findsNothing);
      expect(find.text('Fast Arrival'), findsNothing);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Payment Summary'), findsOneWidget);
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('Complete & Submit'), findsOneWidget);
    });

    testWidgets('the request is created unrated', (tester) async {
      await pumpPayment(tester);
      await _tapVisible(tester, find.text('Complete & Submit'));

      expect(find.byType(RequestSuccessScreen), findsOneWidget);
      final d = (await db.collection('requests').get()).docs.single.data();
      expect(d['rating'], 0);
      expect(d['feedback'], '');
      expect(d['tags'], isEmpty);
      expect(d.containsKey('ratedAt'), isFalse);
    });
  });

  group('Rate screen', () {
    Future<String> open(WidgetTester tester, {bool connected = true}) async {
      _tallPhone(tester);
      final id = await seed();
      final r = (await service.watchDriverRequests(_uid).first).single;
      await tester.pumpWidget(MaterialApp(
        home: RateRequestScreen(
            request: r, service: connected ? service : null),
      ));
      await tester.pumpAndSettle();
      return id;
    }

    testWidgets('shows the job and a receipt, with no star pre-selected',
        (tester) async {
      await open(tester);

      expect(find.text('Rate Your Experience'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('Nimal Perera'), findsOneWidget);
      expect(find.text('#RM1058'), findsOneWidget);
      expect(find.text('Payment Summary'), findsOneWidget);
      expect(find.text('Receipt'), findsOneWidget);
      expect(find.text('Rs. 8,500.00'), findsOneWidget);
      expect(find.text('Submit Rating'), findsOneWidget);

      // Nothing chosen: 5 empty stars, neutral label, no tag selected.
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(5));
      expect(find.text('How was the service?'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('submitting without stars is blocked', (tester) async {
      final id = await open(tester);
      await _tapVisible(tester, find.text('Submit Rating'));

      expect(find.text('Please select a star rating'), findsOneWidget);
      expect((await doc(id))['rating'], 0);
      expect(find.byType(RateRequestScreen), findsOneWidget);

      // Picking a star clears the message.
      await tester.tap(find.byKey(const Key('star-1')));
      await tester.pump();
      expect(find.text('Please select a star rating'), findsNothing);
      expect(find.text('Poor Service (1.0)'), findsOneWidget);
    });

    testWidgets('stars, label, multi-select tags', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('star-4')));
      await tester.pump();
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
      expect(find.text('Great Service! (4.0)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('star-5')));
      await tester.pump();
      expect(find.text('Excellent Service! (5.0)'), findsOneWidget);

      await tester.tap(find.text('Polite'));
      await tester.tap(find.text('Fast Arrival'));
      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
      await tester.tap(find.text('Polite')); // deselect
      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('submit saves the rating and goes back', (tester) async {
      final id = await open(tester);
      await tester.tap(find.byKey(const Key('star-4')));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Great help');
      await tester.tap(find.text('Professional'));
      await tester.tap(find.text('Fast Arrival'));
      await tester.pump();
      await _tapVisible(tester, find.text('Submit Rating'));

      final d = await doc(id);
      expect(d['rating'], 4);
      expect(d['feedback'], 'Great help');
      expect(d['tags'], ['Fast Arrival', 'Professional']); // on-screen order
      expect(d['ratedAt'], isA<Timestamp>());
      expect(find.byType(RateRequestScreen), findsNothing);
    });

    testWidgets('without Firebase: hint, nothing saved', (tester) async {
      final id = await open(tester, connected: false);
      await tester.tap(find.byKey(const Key('star-3')));
      await tester.pump();
      await _tapVisible(tester, find.text('Submit Rating'));
      expect(find.textContaining('Firebase not connected'), findsOneWidget);
      expect((await doc(id))['rating'], 0);
    });
  });

  group('Request History entry point', () {
    Future<void> pumpHistory(WidgetTester tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(MaterialApp(
        home: RequestHistoryScreen(uid: _uid, service: service),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('only completed + unrated requests offer "Rate"',
        (tester) async {
      await seed(ref: '#RM1'); // completed, unrated
      await seed(
          ref: '#RM2', rating: 5, ratedAt: DateTime(2026, 10, 1)); // rated
      await seed(ref: '#RM3', status: 'cancelled');
      await seed(ref: '#RM4', status: 'accepted');
      await seed(ref: '#RM5', rating: 4); // legacy fake rating → still rateable
      await pumpHistory(tester);

      expect(find.text('Rate this service'), findsNWidgets(2)); // RM1 + RM5
      expect(find.text('Your rating'), findsOneWidget); // RM2
      expect(find.byType(RequestHistoryCard), findsNWidgets(5));
    });

    testWidgets('Rate → submit → the card shows the stars', (tester) async {
      await seed();
      await pumpHistory(tester);
      await _tapVisible(tester, find.text('Rate this service'));
      expect(find.byType(RateRequestScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('star-5')));
      await tester.pump();
      await _tapVisible(tester, find.text('Submit Rating'));

      expect(find.byType(RateRequestScreen), findsNothing);
      expect(find.text('Request History'), findsOneWidget);
      expect(find.text('Rate this service'), findsNothing);
      expect(find.text('Your rating'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    });

    test('StarRow is read-only without a callback', () {
      expect(const StarRow(rating: 3).onChanged, isNull);
    });
  });

  group('Mechanic dashboard rating tile', () {
    const mech = AppUser(
      uid: 'm1',
      name: 'Nimal Perera',
      email: 'n@e.com',
      phone: '',
      role: AppRole.mechanic,
    );

    Future<void> pumpMech(WidgetTester tester) async {
      _tallPhone(tester);
      firebaseReady = true;
      await tester.pumpWidget(MaterialApp(
        home: MechanicDashboardScreen(
          user: mech,
          assistanceService: service,
          notificationService: NotificationService(db: db),
          paymentService: PaymentService(db: db),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('real average from rated completed jobs', (tester) async {
      final t = DateTime(2026, 10, 1);
      await seed(rating: 5, ratedAt: t);
      await seed(rating: 4, ratedAt: t);
      await seed(rating: 4); // legacy default: ignored
      await pumpMech(tester);

      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('Rating (2)'), findsOneWidget);
      expect(find.text('4.8'), findsNothing); // the old hardcoded value
    });

    testWidgets('"No ratings yet" when nobody rated', (tester) async {
      await seed();
      await pumpMech(tester);
      expect(find.text('No ratings yet'), findsOneWidget);
      expect(find.text('4.8'), findsNothing);
    });

    testWidgets('offline preview invents no rating', (tester) async {
      _tallPhone(tester);
      await tester.pumpWidget(const MaterialApp(
        home: MechanicDashboardScreen(user: mech),
      ));
      await tester.pumpAndSettle();
      expect(find.text('4.8'), findsNothing);
      expect(find.text('No ratings yet'), findsOneWidget);
    });
  });

  testWidgets('Job details no longer shows a made-up customer rating',
      (tester) async {
    _tallPhone(tester);
    await tester.pumpWidget(MaterialApp(
      home: JobDetailsScreen(
        request: _req(status: RequestStatus.pending),
        mechanicUid: 'm1',
        mechanicName: 'Nimal',
        assistanceService: service,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('4.8 (12 reviews)'), findsNothing);
    expect(find.text('Customer'), findsOneWidget);
  });
}
