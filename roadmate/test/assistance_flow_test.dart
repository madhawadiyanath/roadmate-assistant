import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmate/models/service_request.dart';
import 'package:roadmate/services/assistance_service.dart';

/// End-to-end database flow: driver sends a request → it appears in the
/// mechanic's pending feed → mechanic accepts → both sides see updates.
void main() {
  test('driver request reaches mechanic and completes', () async {
    final db = FakeFirebaseFirestore();
    final service = AssistanceService(db: db);

    // 1. Driver creates a request with location.
    final id = await service.createRequest(
      driverUid: 'driver1',
      driverName: 'Kasun',
      type: AssistanceType.flatTyre,
      address: 'No. 25, Galle Road, Colombo 06',
    );
    expect(id, isNotEmpty);

    // 2. Mechanic sees it in the pending feed with all data intact,
    // including a stable reference code.
    final pending = await service.watchPendingRequests().first;
    expect(pending, hasLength(1));
    expect(pending.first.type, AssistanceType.flatTyre);
    expect(pending.first.address, 'No. 25, Galle Road, Colombo 06');
    expect(pending.first.driverName, 'Kasun');
    expect(pending.first.status, RequestStatus.pending);
    expect(pending.first.refCode, matches(r'^#RM\d{4}$'));
    final code = pending.first.refCode;

    // 3. Mechanic accepts → job appears in their job list.
    await service.acceptRequest(
      requestId: id,
      mechanicUid: 'mech1',
      mechanicName: 'Nimal',
    );
    final jobs = await service.watchMechanicJobs('mech1').first;
    expect(jobs, hasLength(1));
    expect(jobs.first.status, RequestStatus.accepted);
    expect(jobs.first.mechanicName, 'Nimal');

    // 4. No longer in the pending feed.
    expect(await service.watchPendingRequests().first, isEmpty);

    // 5. Driver sees the accepted status + mechanic name live.
    final driverView = await service.watchDriverRequests('driver1').first;
    expect(driverView.first.status, RequestStatus.accepted);
    expect(driverView.first.mechanicName, 'Nimal');

    // 6. Mechanic advances to completed.
    await service.updateStatus(id, RequestStatus.onTheWay);
    await service.updateStatus(id, RequestStatus.completed);
    final done = await service.watchDriverRequests('driver1').first;
    expect(done.first.status, RequestStatus.completed);

    // 7. Reference code is stable across reads (same doc, same code).
    expect(done.first.refCode, code);
    final reread = await service.watchDriverRequests('driver1').first;
    expect(reread.first.refCode, code);
  });
}
