import 'package:carnet_auto/core/constants.dart';
import 'package:carnet_auto/models/maintenance_type.dart';
import 'package:carnet_auto/models/mileage_log.dart';
import 'package:carnet_auto/models/vehicle.dart';
import 'package:carnet_auto/services/prediction_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed "now" so nothing here depends on the wall clock.
final _now = DateTime(2026, 7, 28);

Vehicle _vehicle({int currentKm = 100000, DateTime? createdAt}) => Vehicle(
      id: 'v1',
      userId: 'u1',
      name: 'Clio',
      currentKm: currentKm,
      createdAt: createdAt,
    );

MaintenanceType _type({
  int? intervalKm,
  int? intervalMonths,
  int? lastDoneKm,
  DateTime? lastDoneDate,
}) =>
    MaintenanceType(
      id: 't1',
      vehicleId: 'v1',
      label: 'Vidange',
      intervalKm: intervalKm,
      intervalMonths: intervalMonths,
      lastDoneKm: lastDoneKm,
      lastDoneDate: lastDoneDate,
    );

MileageLog _log(int km, DateTime at) =>
    MileageLog(id: '$km', vehicleId: 'v1', km: km, recordedAt: at);

void main() {
  group('measuredMonthlyKmAverage', () {
    test('returns null rather than a fabricated figure when history is thin',
        () {
      expect(PredictionService.measuredMonthlyKmAverage([]), isNull);
      expect(
        PredictionService.measuredMonthlyKmAverage(
            [_log(1000, _now.subtract(const Duration(days: 30)))]),
        isNull,
      );
    });

    test('returns null when the odometer did not move', () {
      final logs = [
        _log(1000, _now.subtract(const Duration(days: 60))),
        _log(1000, _now.subtract(const Duration(days: 10))),
      ];
      expect(
          PredictionService.measuredMonthlyKmAverage(logs, now: _now), isNull);
    });

    test('measures a rate from two readings', () {
      final logs = [
        _log(10000, _now.subtract(const Duration(days: 60))),
        _log(12000, _now),
      ];
      // 2000 km over 60 days = ~1000 km/month.
      expect(
        PredictionService.measuredMonthlyKmAverage(logs, now: _now),
        closeTo(1000, 0.001),
      );
    });

    test('monthlyKmAverage falls back only when nothing can be measured', () {
      expect(
        PredictionService.monthlyKmAverage([], now: _now),
        Thresholds.fallbackKmPerMonth,
      );
    });
  });

  group('predict — anchoring', () {
    // The regression this whole group exists for: the anchor used to fall
    // back to the vehicle's *current* km, so the target moved with the car
    // and the maintenance could never come due.
    test('a km interval with no recorded last intervention needs setup', () {
      final p = PredictionService.predict(
        type: _type(intervalKm: 60000),
        vehicle: _vehicle(currentKm: 200000),
        kmPerMonth: 1000,
        now: _now,
      );

      expect(p.needsSetup, isTrue);
      expect(p.remainingKm, isNull,
          reason: 'no anchor means no km forecast at all');
      expect(p.urgency, 0);
      expect(p.isDueSoon, isFalse);
      expect(p.isOverdue, isFalse);
      expect(PredictionService.needsAlert(p, now: _now), isFalse,
          reason: 'an unknown échéance must not raise a reminder');
    });

    test('a time interval with no recorded last date needs setup', () {
      final p = PredictionService.predict(
        type: _type(intervalMonths: 12),
        vehicle: _vehicle(createdAt: DateTime(2020)),
        kmPerMonth: 1000,
        now: _now,
      );

      expect(p.needsSetup, isTrue);
      expect(p.dueDate, isNull,
          reason: 'the vehicle creation date is not a maintenance anchor');
    });

    test('an anchored maintenance becomes overdue as the car is driven', () {
      final p = PredictionService.predict(
        type: _type(intervalKm: 60000, lastDoneKm: 120000),
        vehicle: _vehicle(currentKm: 200000),
        kmPerMonth: 1000,
        now: _now,
      );

      expect(p.needsSetup, isFalse);
      // Target 180 000, car at 200 000 => 20 000 km past due.
      expect(p.remainingKm, -20000);
      expect(p.isOverdue, isTrue);
      expect(p.urgency, greaterThan(1.0));
    });

    test('one interval anchored and the other not still forecasts', () {
      final p = PredictionService.predict(
        type: _type(intervalKm: 10000, lastDoneKm: 95000, intervalMonths: 12),
        vehicle: _vehicle(currentKm: 100000),
        kmPerMonth: 1000,
        now: _now,
      );

      expect(p.needsSetup, isFalse);
      expect(p.remainingKm, 5000);
    });
  });

  group('predict — urgency', () {
    test('is not clamped, so overdue items can be ranked against each other',
        () {
      final slightly = PredictionService.predict(
        type: _type(intervalKm: 10000, lastDoneKm: 89000),
        vehicle: _vehicle(currentKm: 100000),
        kmPerMonth: 1000,
        now: _now,
      );
      final badly = PredictionService.predict(
        type: _type(intervalKm: 10000, lastDoneKm: 50000),
        vehicle: _vehicle(currentKm: 100000),
        kmPerMonth: 1000,
        now: _now,
      );

      expect(slightly.urgency, greaterThan(1.0));
      expect(badly.urgency, greaterThan(slightly.urgency),
          reason: 'clamping to 1.0 would make these two compare equal');
      // The progress bar still gets a usable 0..1 value.
      expect(badly.progress, 1.0);
    });

    test('is halfway through a half-consumed interval', () {
      final p = PredictionService.predict(
        type: _type(intervalKm: 10000, lastDoneKm: 95000),
        vehicle: _vehicle(currentKm: 100000),
        kmPerMonth: 1000,
        now: _now,
      );
      expect(p.urgency, closeTo(0.5, 0.0001));
    });

    test('takes the binding constraint of km and time', () {
      // 10% of the km interval used, but 100% of the time interval.
      final p = PredictionService.predict(
        type: _type(
          intervalKm: 10000,
          lastDoneKm: 99000,
          intervalMonths: 12,
          lastDoneDate: DateTime(2025, 7, 28),
        ),
        vehicle: _vehicle(currentKm: 100000),
        kmPerMonth: 1000,
        now: _now,
      );
      expect(p.urgency, closeTo(1.0, 0.01));
    });
  });

  group('needsAlert', () {
    test('honours a caller-supplied km threshold', () {
      final p = PredictionService.predict(
        type: _type(intervalKm: 10000, lastDoneKm: 91000),
        vehicle: _vehicle(currentKm: 100000),
        kmPerMonth: 1000,
        now: _now,
      );
      expect(p.remainingKm, 1000);

      expect(PredictionService.needsAlert(p, now: _now, kmThreshold: 500),
          isFalse);
      expect(PredictionService.needsAlert(p, now: _now, kmThreshold: 2000),
          isTrue);
    });

    test('a short km interval does not alert from the moment it is done', () {
      // The regression, from real data: a 7 000 km vidange on a car doing
      // 15 634 km/month is "due in 13 days" the instant it is performed.
      // Alerting on the *projected* date meant this type sat inside a
      // 30-day horizon permanently — the home banner shouted while the
      // card correctly showed a full interval remaining.
      final p = PredictionService.predict(
        type: _type(
          intervalKm: 7000,
          lastDoneKm: 569265,
          intervalMonths: 3,
          lastDoneDate: DateTime(2026, 7, 27),
        ),
        vehicle: _vehicle(currentKm: 569265),
        kmPerMonth: 15634,
        now: _now,
      );

      expect(p.remainingKm, 7000, reason: 'a whole interval is left');
      expect(p.urgency, lessThan(0.1), reason: 'it was done two days ago');
      expect(PredictionService.needsAlert(p, now: _now), isFalse);
    });

    test('still alerts once the distance actually runs out', () {
      final p = PredictionService.predict(
        type: _type(intervalKm: 7000, lastDoneKm: 569265),
        vehicle: _vehicle(currentKm: 575900),
        kmPerMonth: 15634,
        now: _now,
      );

      expect(p.remainingKm, 365);
      expect(PredictionService.needsAlert(p, now: _now), isTrue);
    });

    test('a genuine time interval still alerts on the calendar', () {
      // No km interval at all, so only the date can trigger it.
      final p = PredictionService.predict(
        type: _type(intervalMonths: 12, lastDoneDate: DateTime(2025, 8, 20)),
        vehicle: _vehicle(),
        kmPerMonth: 15634,
        now: _now,
      );

      expect(p.timeDueDate, DateTime(2026, 8, 20));
      expect(PredictionService.needsAlert(p, now: _now), isTrue);
    });

    test('honours a caller-supplied day threshold', () {
      final p = PredictionService.predict(
        type: _type(intervalMonths: 12, lastDoneDate: DateTime(2025, 8, 20)),
        vehicle: _vehicle(),
        kmPerMonth: 1000,
        now: _now,
      );
      // Due 2026-08-20, i.e. 23 days after the fixed "now".
      expect(PredictionService.needsAlert(p, now: _now, daysThreshold: 10),
          isFalse);
      expect(PredictionService.needsAlert(p, now: _now, daysThreshold: 30),
          isTrue);
    });
  });
}
