import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roadmate/main.dart';
import 'package:roadmate/config/firebase_state.dart';
import 'package:roadmate/models/app_user.dart';
import 'package:roadmate/services/assistance_service.dart';
import 'package:roadmate/services/auth_service.dart';
import 'package:roadmate/services/payment_service.dart';
import 'package:roadmate/models/service_request.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:roadmate/models/payments.dart';
import 'package:roadmate/screens/admin_dashboard_screen.dart';
import 'package:roadmate/screens/digital_receipt_screen.dart';
import 'package:roadmate/screens/payment_history_screen.dart';
import 'package:roadmate/screens/chat_screen.dart';
import 'package:roadmate/screens/profile_screen.dart';
import 'package:roadmate/screens/confirm_request_screen.dart';
import 'package:roadmate/services/chat_service.dart';
import 'package:roadmate/screens/payment_review_screen.dart';
import 'package:roadmate/screens/request_success_screen.dart';
import 'package:roadmate/screens/track_request_screen.dart';
import 'package:roadmate/screens/driver_dashboard_screen.dart';
import 'package:roadmate/screens/location_screen.dart';
import 'package:roadmate/screens/mechanic_dashboard_screen.dart';
import 'package:roadmate/screens/role_home.dart';

void main() {
  testWidgets('Onboarding screen shows on app start', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Help on the road, always with you.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Get Started navigates to Sign In', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Sign In links to Sign Up and back', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Go to Sign Up via link
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Create Account!'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('I am a'), findsOneWidget);
    expect(find.text('Driver'), findsOneWidget);
    expect(find.text('Mechanic'), findsOneWidget);

    // Back to Sign In via AppBar back
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsOneWidget);
  });

  testWidgets('Driver dashboard shows all sections', (
    WidgetTester tester,
  ) async {
    const user = AppUser(
      uid: 'u1',
      name: 'Kasun Perera',
      email: 'kasun@example.com',
      phone: '+94771234567',
      role: AppRole.driver,
    );
    await tester.pumpWidget(
      const MaterialApp(home: DriverDashboardScreen(user: user)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello, Kasun'), findsOneWidget);
    expect(find.text('24/7 Priority Dispatch Active'), findsOneWidget);
    expect(find.text("Stuck on the road? We're here!"), findsOneWidget);
    expect(find.text('Request Assistance'), findsOneWidget);
    expect(find.text('Quick Services'), findsOneWidget);
    expect(find.text('Flat Tyre'), findsOneWidget);
    expect(find.text('Jump Start'), findsOneWidget);
    expect(find.text('Fuel Drop'), findsOneWidget);
    expect(find.text('No vehicle saved — tap to add'), findsOneWidget);
    expect(find.text('Recent Requests'), findsOneWidget);
    expect(find.text('Towing Service'), findsOneWidget);

    // Tapping the recent request opens live tracking.
    await tester.ensureVisible(find.text('Towing Service'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Towing Service'));
    await tester.pumpAndSettle();
    expect(find.text('Sampath Perera'), findsWidgets);
    expect(find.text('Arriving in 8 minutes'), findsOneWidget);
    expect(find.text('Cancel Request'), findsOneWidget);
  });

  testWidgets('Tracking cancel needs Firebase', (
    WidgetTester tester,
  ) async {
    const req = ServiceRequest(
      id: 'demo-track-1',
      driverUid: 'd1',
      driverName: 'Kasun Perera',
      type: AssistanceType.towing,
      status: RequestStatus.accepted,
      address: 'No. 25, Galle Road, Colombo 06',
      mechanicUid: 'm1',
      mechanicName: 'Sampath Perera',
    );
    await tester.pumpWidget(
      const MaterialApp(home: TrackRequestScreen(request: req)),
    );
    await tester.pumpAndSettle();

    expect(find.text('2.4 km'), findsOneWidget);
    expect(find.text('Speed 38'), findsOneWidget);
    expect(find.text('WP CA 5678'), findsOneWidget);

    await tester.ensureVisible(find.text('Cancel Request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel Request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, cancel'));
    await tester.pump();
    expect(find.textContaining('Firebase not connected'), findsOneWidget);
  });

  testWidgets('Select Service opens full service page', (
    WidgetTester tester,
  ) async {
    const user = AppUser(
      uid: 'u1',
      name: 'Kasun Perera',
      email: 'kasun@example.com',
      phone: '',
      role: AppRole.driver,
    );
    await tester.pumpWidget(
      const MaterialApp(home: DriverDashboardScreen(user: user)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Select Service'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select Service'));
    await tester.pumpAndSettle();

    expect(find.text('What do you need help with?'), findsOneWidget);
    expect(find.text('Flat Tyre'), findsWidgets);
    expect(find.text('Battery Jump Start'), findsOneWidget);
    expect(find.text('Fuel Delivery'), findsOneWidget);
    expect(find.text('Towing Service'), findsWidgets);
    expect(find.text('Puncture repair or tyre change'), findsOneWidget);
    expect(find.text('Immediate Dispatch?'), findsOneWidget);
    expect(find.text('LIVE DISPATCH'), findsOneWidget);
  });

  testWidgets('Location page shows map, GPS and address tools', (
    WidgetTester tester,
  ) async {
    const user = AppUser(
      uid: 'u1',
      name: 'Kasun Perera',
      email: 'kasun@example.com',
      phone: '',
      role: AppRole.driver,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: LocationScreen(
          user: user,
          serviceType: AssistanceType.flatTyre,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your Location'), findsOneWidget);
    expect(find.text('Confirm your current location'), findsOneWidget);
    expect(find.text('Use Current Location'), findsOneWidget);
    expect(find.text('RECENT:'), findsOneWidget);
    expect(find.text('Outer Circular Hwy'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tapping Next goes to the Confirm Request page.
    await tester.ensureVisible(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Request'), findsOneWidget);
    expect(find.text('Please review your details'), findsOneWidget);
    expect(find.text('SERVICE TYPE'), findsOneWidget);
    expect(find.text('LOCATION'), findsOneWidget);
    expect(find.text('VEHICLE'), findsOneWidget);
    expect(find.text('CONTACT NUMBER'), findsOneWidget);
    expect(find.text('Continue to Payment'), findsOneWidget);
  });

  testWidgets('Confirm continues to payment page', (
    WidgetTester tester,
  ) async {
    const user = AppUser(
      uid: 'u1',
      name: 'Kasun Perera',
      email: 'kasun@example.com',
      phone: '+94771234567',
      role: AppRole.driver,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: ConfirmRequestScreen(
          user: user,
          serviceType: AssistanceType.flatTyre,
          address: 'No. 25, Galle Road, Colombo 06',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flat Tyre'), findsOneWidget);
    expect(find.text('No. 25, Galle Road, Colombo 06'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('ESTIMATED PATROL ARRIVAL'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue to Payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to Payment'));
    await tester.pumpAndSettle();

    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Rate Your Experience'), findsNothing); // rating is post-job
    expect(find.text('Payment Summary'), findsOneWidget);
    expect(find.text('Payment Method'), findsOneWidget);
    expect(find.text('Rs. 3,500.00'), findsOneWidget);
    expect(find.text('Complete & Submit'), findsOneWidget);
  });

  testWidgets('Payment submit needs Firebase; method selects', (
    WidgetTester tester,
  ) async {
    const user = AppUser(
      uid: 'u1',
      name: 'Kasun Perera',
      email: 'kasun@example.com',
      phone: '',
      role: AppRole.driver,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: PaymentReviewScreen(
          user: user,
          serviceType: AssistanceType.flatTyre,
          address: 'No. 25, Galle Road, Colombo 06',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch payment method to cash.
    await tester.ensureVisible(find.text('Cash on Site'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cash on Site'));
    await tester.pumpAndSettle();

    // Complete without Firebase shows the setup hint.
    await tester.ensureVisible(find.text('Complete & Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete & Submit'));
    await tester.pump();
    expect(find.textContaining('Firebase not connected'), findsOneWidget);
  });

  testWidgets('Mechanic dashboard shows incoming requests', (
    WidgetTester tester,
  ) async {
    const mech = AppUser(
      uid: 'mech1',
      name: 'Nimal',
      email: 'nimal@example.com',
      phone: '',
      role: AppRole.mechanic,
    );
    await tester.pumpWidget(
      const MaterialApp(home: MechanicDashboardScreen(user: mech)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello,'), findsOneWidget);
    expect(find.text('Nimal'), findsWidgets);
    expect(find.text('RoadMate'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text("Let's keep\nSri Lanka moving!"), findsOneWidget);
    expect(find.text('New Requests'), findsWidgets);
    expect(find.text("Today's Earnings"), findsOneWidget);
    expect(find.text('Rs. 12,500'), findsOneWidget);
    expect(find.text('View New Requests'), findsOneWidget);

    // CTA jumps to the Jobs tab, opened on fresh (new) jobs.
    await tester.ensureVisible(find.text('View New Requests'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View New Requests'));
    await tester.pumpAndSettle();
    expect(find.text('Jobs'), findsWidgets);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.textContaining('Kasun Perera'), findsOneWidget);
    expect(find.text('Flat Tyre'), findsWidgets);
    // No inline Accept button — tapping a card opens Request Details.
    expect(find.text('Accept Job'), findsNothing);

    await tester.tap(find.textContaining('Kasun Perera').first);
    await tester.pumpAndSettle();
    expect(find.text('Request Details'), findsOneWidget);
    expect(find.text('Customer Details'), findsOneWidget);
    expect(find.text('Flat Tyre Assistance'), findsOneWidget);
    expect(find.text('No. 25, Galle Road, Colombo 06'), findsOneWidget);
    expect(find.text('Estimated Service Fee'), findsOneWidget);
    expect(find.text('Rs. 3,500'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);

    // Accept without Firebase shows the setup hint.
    await tester.ensureVisible(find.text('Accept'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pump();
    expect(find.textContaining('Firebase not connected'), findsOneWidget);
    await tester.pumpAndSettle();

    // Back to Jobs: Active filter shows in-progress jobs.
    await tester.ensureVisible(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    expect(find.text('Start — On the way'), findsOneWidget);

    // Done filter shows finished jobs, read-only.
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsWidgets);
    expect(find.text('Mark Completed'), findsNothing);
  });

  testWidgets('Request success page shows receipt and tracks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RequestSuccessScreen(
          refCode: '#RM1058',
          serviceType: AssistanceType.flatTyre,
          address: 'No. 25, Galle Road, Colombo 06',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Request Submitted!'), findsOneWidget);
    expect(find.text('Status: Searching Nearby Patrol'), findsOneWidget);
    expect(find.textContaining('#RM'), findsOneWidget);
    expect(find.text('Flat Tyre Assistance'), findsOneWidget);
    expect(find.text('Track Request'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);

    // Track pops the page (result `true` → Requests tab).
    await tester.ensureVisible(find.text('Track Request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Track Request'));
    await tester.pumpAndSettle();
    expect(find.text('Request Submitted!'), findsNothing);
  });

  testWidgets('Request success page goes back home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RequestSuccessScreen(
          refCode: '#RM1058',
          serviceType: AssistanceType.flatTyre,
          address: 'No. 25, Galle Road, Colombo 06',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Back to Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();
    expect(find.text('Request Submitted!'), findsNothing);
  });

  testWidgets('AuthGate shows onboarding without Firebase', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    // firebaseReady is false in tests → straight to onboarding.
    expect(find.text('Help on the road, always with you.'), findsOneWidget);
  });

  testWidgets('Chat thread shows messages and sends', (
    WidgetTester tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final chat = ChatService(db: db);
    const req = ServiceRequest(
      id: 'req1',
      driverUid: 'driver1',
      driverName: 'Kasun',
      type: AssistanceType.flatTyre,
      status: RequestStatus.accepted,
      refCode: '#RM1058',
      mechanicUid: 'mech1',
      mechanicName: 'Nimal',
    );
    await chat.send(
      requestId: 'req1',
      senderUid: 'mech1',
      senderName: 'Nimal',
      senderRole: 'mechanic',
      text: 'On my way, 10 mins',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          request: req,
          senderUid: 'driver1',
          senderName: 'Kasun',
          senderRole: 'driver',
          peerName: 'Nimal',
          chatService: chat,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nimal'), findsWidgets);
    expect(find.text('On my way, 10 mins'), findsOneWidget);

    // Driver replies — bubble appears on the right.
    await tester.enterText(
        find.byType(TextField), 'Near Mile Post 42');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Near Mile Post 42'), findsOneWidget);

    final all = await chat.watch('req1').first;
    expect(all, hasLength(2));
  });

  testWidgets('Chat own bubble long-press edits and deletes', (
    WidgetTester tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final chat = ChatService(db: db);
    const req = ServiceRequest(
      id: 'req1',
      driverUid: 'driver1',
      driverName: 'Kasun',
      type: AssistanceType.flatTyre,
      status: RequestStatus.accepted,
      refCode: '#RM1058',
      mechanicUid: 'mech1',
      mechanicName: 'Nimal',
    );
    await chat.send(
      requestId: 'req1',
      senderUid: 'driver1',
      senderName: 'Kasun',
      senderRole: 'driver',
      text: 'Hello there',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          request: req,
          senderUid: 'driver1',
          senderName: 'Kasun',
          senderRole: 'driver',
          peerName: 'Nimal',
          chatService: chat,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hello there'), findsOneWidget);

    // Long-press own bubble → Edit message → save new text.
    await tester.longPress(find.text('Hello there'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit message'));
    await tester.pumpAndSettle();
    final dialogField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    expect(dialogField, findsOneWidget);
    await tester.enterText(dialogField, 'Hello!!');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Hello!!'), findsOneWidget);
    expect(find.text('edited'), findsOneWidget);

    // Long-press → Delete message → confirm.
    await tester.longPress(find.text('Hello!!'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Hello!!'), findsNothing);
  });

  testWidgets('Profile page shows menu, edits, guards save', (
    WidgetTester tester,
  ) async {
    const user = AppUser(
      uid: 'u1',
      name: 'Kasun Perera',
      email: 'kasun@example.com',
      phone: '+94771234567',
      role: AppRole.driver,
    );
    await tester.pumpWidget(
      const MaterialApp(home: ProfileScreen(user: user)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kasun Perera'), findsWidgets);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Vehicle Information'), findsOneWidget);
    expect(find.text('Vehicle Details'), findsNothing); // no inline vehicle
    expect(find.text('Logout'), findsOneWidget);

    // Personal Information opens edit mode; save without Firebase shows hint.
    await tester.tap(find.text('Personal Information'));
    await tester.pumpAndSettle();
    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pump();
    expect(find.textContaining('Firebase not connected'), findsOneWidget);
  });

  testWidgets('Admin profile shows ADMIN badge, no vehicle', (
    WidgetTester tester,
  ) async {
    const admin = AppUser(
      uid: 'a1',
      name: 'Admin Perera',
      email: 'admin@roadmate.lk',
      phone: '',
      role: AppRole.admin,
    );
    await tester.pumpWidget(
      const MaterialApp(home: ProfileScreen(user: admin)),
    );
    await tester.pumpAndSettle();

    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('Vehicle Information'), findsNothing);
  });

  testWidgets('Mechanic profile has no vehicle entry', (
    WidgetTester tester,
  ) async {
    const mech = AppUser(
      uid: 'm1',
      name: 'Nimal',
      email: 'n@e.com',
      phone: '',
      role: AppRole.mechanic,
    );
    await tester.pumpWidget(
      const MaterialApp(home: ProfileScreen(user: mech)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mechanic'), findsOneWidget);
    expect(find.text('Services Offered'), findsOneWidget);
    expect(find.text('Vehicle Information'), findsNothing);
    expect(find.text('Emergency Contacts'), findsNothing);
  });

  testWidgets('Driver avatar opens Profile page', (
    WidgetTester tester,
  ) async {
    const user = AppUser(
      uid: 'u1',
      name: 'Kasun Perera',
      email: 'kasun@example.com',
      phone: '',
      role: AppRole.driver,
    );
    await tester.pumpWidget(
      const MaterialApp(home: DriverDashboardScreen(user: user)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CircleAvatar).first);
    await tester.pumpAndSettle();
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Kasun Perera'), findsWidgets);
  });

  testWidgets('Admin dashboard shows stats and tabs', (
    WidgetTester tester,
  ) async {
    const admin = AppUser(
      uid: 'a1',
      name: 'Admin Perera',
      email: 'admin@roadmate.lk',
      phone: '',
      role: AppRole.admin,
    );
    await tester.pumpWidget(
      const MaterialApp(home: AdminDashboardScreen(user: admin)),
    );
    await tester.pumpAndSettle();

    expect(find.text('RoadMate Admin'), findsOneWidget);
    expect(find.textContaining('Hello, Admin'), findsOneWidget);
    expect(find.text('Total Users'), findsOneWidget);
    expect(find.text('Pending Requests'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Requests by Status'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('Requests by Service'), findsOneWidget);
    expect(find.text('Users by Role'), findsOneWidget);
    expect(find.text('All Requests'), findsWidgets);
    expect(find.text('All Users'), findsWidgets);

    // Requests tab lists every request (demo without Firebase).
    await tester.tap(find.text('Requests').last);
    await tester.pumpAndSettle();
    expect(find.text('Flat Tyre • #RM1058'), findsOneWidget);

    // Users tab lists every user (demo without Firebase).
    await tester.tap(find.text('Users').last);
    await tester.pumpAndSettle();
    expect(find.text('kasun@example.com'), findsOneWidget);
    expect(find.text('Admins are created in the Firebase console only.'),
        findsOneWidget);

    // Payments tab shows revenue analysis (demo without Firebase).
    await tester.tap(find.text('Payments'));
    await tester.pumpAndSettle();
    expect(find.text('Revenue (paid)'), findsOneWidget);
    expect(find.text('Rs. 24500'), findsOneWidget);
    expect(find.text('Paid vs Pending'), findsOneWidget);
    expect(find.text('Revenue by Method'), findsOneWidget);
    expect(find.text('Daily Revenue'), findsOneWidget);
  });

  testWidgets('Admin changes a user role', (tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('u1').set({
      'name': 'Kasun Perera',
      'email': 'kasun@example.com',
      'phone': '',
      'role': 'driver',
    });
    const admin = AppUser(
      uid: 'a1',
      name: 'Admin Perera',
      email: 'admin@roadmate.lk',
      phone: '',
      role: AppRole.admin,
    );
    firebaseReady = true;
    addTearDown(() => firebaseReady = false);

    await tester.pumpWidget(
      MaterialApp(
        home: AdminDashboardScreen(
          user: admin,
          authService: AuthService(db: db),
          assistanceService: AssistanceService(db: db),
          paymentService: PaymentService(db: db),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kasun Perera'));
    await tester.pumpAndSettle();
    expect(find.text('Current: driver'), findsOneWidget);

    await tester.tap(find.text('Mechanic'));
    await tester.pumpAndSettle();
    expect(find.text('Role changed to mechanic.'), findsOneWidget);

    final doc = await db.collection('users').doc('u1').get();
    expect(doc.data()?['role'], 'mechanic');
  });

  testWidgets('Admin cancels then deletes a request', (tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('requests').doc('r1').set({
      'driverUid': 'd1',
      'driverName': 'Kasun',
      'type': 'flatTyre',
      'status': 'pending',
      'address': 'Old Road 1',
      'refCode': '#RM3001',
      'createdAt': DateTime(2026, 10, 2, 10, 0),
    });
    const admin = AppUser(
      uid: 'a1',
      name: 'Admin Perera',
      email: 'admin@roadmate.lk',
      phone: '',
      role: AppRole.admin,
    );
    firebaseReady = true;
    addTearDown(() => firebaseReady = false);

    await tester.pumpWidget(
      MaterialApp(
        home: AdminDashboardScreen(
          user: admin,
          authService: AuthService(db: db),
          assistanceService: AssistanceService(db: db),
          paymentService: PaymentService(db: db),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.text('Flat Tyre • #RM3001'), findsOneWidget);

    // Cancel the pending request.
    await tester.tap(find.text('Flat Tyre • #RM3001'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel request'));
    await tester.pumpAndSettle();
    expect(find.text('Request cancelled.'), findsOneWidget);
    var doc = await db.collection('requests').doc('r1').get();
    expect(doc.data()?['status'], 'cancelled');

    // Delete it permanently.
    await tester.tap(find.text('Flat Tyre • #RM3001'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel request'), findsNothing);
    await tester.tap(find.text('Delete request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    // Let the multi-step async delete finish while the snackbar is up.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Request deleted.'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Flat Tyre • #RM3001'), findsNothing);
    doc = await db.collection('requests').doc('r1').get();
    expect(doc.exists, isFalse);
  });

  testWidgets('Receipt shows invoice with PAID stamp', (
    WidgetTester tester,
  ) async {
    const txn = TxnRecord(
      id: 't1',
      requestId: 'req1',
      refCode: '#RM1058',
      type: 'Flat Tyre',
      payerUid: 'driver1',
      payerName: 'Kasun',
      payeeUid: 'mech1',
      payeeName: 'Nimal',
      amount: 3500,
      method: 'Card •• 4242',
      status: 'paid',
      items: [
        FeeLine('Flatbed Dispatch & Triage', 2800),
        FeeLine('Tyre Change Labour', 700),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: DigitalReceiptScreen(transaction: txn.toPaymentTransaction())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Digital Receipt'), findsOneWidget);
    expect(find.text('INVOICE NUMBER'), findsOneWidget);
    expect(find.text('RoadMate'), findsOneWidget);
  });

  testWidgets('Transaction history lists with receipts', (
    WidgetTester tester,
  ) async {
    final db = FakeFirebaseFirestore();
    final pay = PaymentService(db: db);
    await pay.createTransaction(
      requestId: 'req1',
      refCode: '#RM1058',
      type: 'Flat Tyre',
      payerUid: 'driver1',
      payerName: 'Kasun',
      amount: 3500,
      method: 'Card •• 4242',
      items: const [FeeLine('Dispatch', 3500)],
      paidAtOnce: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentHistoryScreen(
          paymentService: pay,
          driverUid: 'driver1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Payment History'), findsOneWidget);
  });

  testWidgets('RoleHome routes driver to dashboard, mechanic to jobs', (
    WidgetTester tester,
  ) async {
    const driver = AppUser(
      uid: 'u1',
      name: 'Kasun',
      email: 'k@e.com',
      phone: '',
      role: AppRole.driver,
    );
    await tester.pumpWidget(
      const MaterialApp(home: RoleHome(user: driver)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Quick Services'), findsOneWidget);

    const mech = AppUser(
      uid: 'u2',
      name: 'Nimal',
      email: 'n@e.com',
      phone: '',
      role: AppRole.mechanic,
    );
    await tester.pumpWidget(const MaterialApp(home: RoleHome(user: mech)));
    await tester.pumpAndSettle();
    // Jobs tab content is offstage until its nav item is tapped.
    // It opens on fresh (new) jobs.
    await tester.tap(find.text('Jobs'));
    await tester.pumpAndSettle();
    expect(find.text('New'), findsOneWidget);
    // Cards open Request Details instead of inline accept.
    expect(find.text('Accept Job'), findsNothing);
    expect(find.textContaining('Kasun Perera'), findsOneWidget);

    const admin = AppUser(
      uid: 'a1',
      name: 'Admin Perera',
      email: 'admin@roadmate.lk',
      phone: '',
      role: AppRole.admin,
    );
    await tester.pumpWidget(const MaterialApp(home: RoleHome(user: admin)));
    await tester.pumpAndSettle();
    expect(find.text('RoadMate Admin'), findsOneWidget);
    expect(find.text('Total Users'), findsOneWidget);
  });
}
