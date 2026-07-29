import 'package:carnet_auto/models/maintenance_history.dart';
import 'package:carnet_auto/services/history_filter.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 7, 28);

MaintenanceHistory _entry(
  String id, {
  String title = 'Vidange',
  String? garage,
  bool fuel = false,
  DateTime? at,
  int? km,
}) =>
    MaintenanceHistory(
      id: id,
      vehicleId: 'v1',
      title: title,
      garageName: garage,
      isFuel: fuel,
      km: km,
      doneAt: at ?? _now,
    );

List<String> _ids(List<MaintenanceHistory> items) =>
    items.map((h) => h.id).toList();

void main() {
  group('search', () {
    test('matches the title case-insensitively', () {
      final items = [
        _entry('a', title: 'Vidange moteur'),
        _entry('b', title: 'Plaquettes avant'),
      ];
      const filter = HistoryFilter(query: 'VIDANGE');
      expect(_ids(filter.apply(items, now: _now)), ['a']);
    });

    test('finds an accented title from an unaccented query', () {
      // Nobody types accents into a search box.
      final items = [
        _entry('a', title: 'Réparation embrayage'),
        _entry('b', title: 'Vidange'),
      ];
      const filter = HistoryFilter(query: 'reparation');
      expect(_ids(filter.apply(items, now: _now)), ['a']);
    });

    test('searches the garage name too', () {
      final items = [
        _entry('a', garage: 'Garage Bencheikh'),
        _entry('b', garage: 'Auto Service'),
      ];
      const filter = HistoryFilter(query: 'bencheikh');
      expect(_ids(filter.apply(items, now: _now)), ['a']);
    });

    test('a blank query keeps everything', () {
      final items = [_entry('a'), _entry('b')];
      const filter = HistoryFilter(query: '   ');
      expect(_ids(filter.apply(items, now: _now)), ['a', 'b']);
    });
  });

  group('kind', () {
    final items = [
      _entry('repair'),
      _entry('fill', fuel: true),
    ];

    test('maintenance excludes fill-ups', () {
      const filter = HistoryFilter(kind: HistoryKind.maintenance);
      expect(_ids(filter.apply(items, now: _now)), ['repair']);
    });

    test('fuel keeps only fill-ups', () {
      const filter = HistoryFilter(kind: HistoryKind.fuel);
      expect(_ids(filter.apply(items, now: _now)), ['fill']);
    });
  });

  group('period', () {
    final items = [
      _entry('recent', at: DateTime(2026, 6, 1)),
      _entry('lastYear', at: DateTime(2025, 12, 1)),
      _entry('old', at: DateTime(2023, 4, 1)),
    ];

    test('last 12 months is relative to the reference date', () {
      const filter = HistoryFilter(period: HistoryPeriod.last12Months);
      expect(_ids(filter.apply(items, now: _now)), ['recent', 'lastYear']);
    });

    test('this year is the calendar year', () {
      const filter = HistoryFilter(period: HistoryPeriod.thisYear);
      expect(_ids(filter.apply(items, now: _now)), ['recent']);
    });
  });

  test('criteria combine', () {
    final items = [
      _entry('a', title: 'Vidange', garage: 'Bencheikh'),
      _entry('b', title: 'Vidange', garage: 'Autre'),
      _entry('c', title: 'Vidange', garage: 'Bencheikh', fuel: true),
      _entry('d',
          title: 'Vidange', garage: 'Bencheikh', at: DateTime(2020, 1, 1)),
    ];
    const filter = HistoryFilter(
      query: 'vidange',
      garageName: 'Bencheikh',
      kind: HistoryKind.maintenance,
      period: HistoryPeriod.last12Months,
    );
    expect(_ids(filter.apply(items, now: _now)), ['a']);
  });

  group('isEmpty', () {
    test('is true for the default filter', () {
      expect(const HistoryFilter().isEmpty, isTrue);
    });

    test('is false once any criterion is set', () {
      expect(const HistoryFilter(query: 'x').isEmpty, isFalse);
      expect(const HistoryFilter(kind: HistoryKind.fuel).isEmpty, isFalse);
      expect(const HistoryFilter(garageName: 'g').isEmpty, isFalse);
      expect(
        const HistoryFilter(period: HistoryPeriod.thisYear).isEmpty,
        isFalse,
      );
    });
  });

  test('copyWith can clear the garage', () {
    const filter = HistoryFilter(garageName: 'Bencheikh');
    expect(filter.copyWith(garageName: null).garageName, isNull);
    // …and leaves it alone when not passed.
    expect(filter.copyWith(query: 'x').garageName, 'Bencheikh');
  });
}
