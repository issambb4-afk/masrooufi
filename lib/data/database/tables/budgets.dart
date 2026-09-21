import 'package:drift/drift.dart';
import 'categories.dart';

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get period => text()(); // e.g. 2026-09
  TextColumn get type => text()(); // global, category
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  IntColumn get amount => integer()(); // minor units
  TextColumn get currency => text().withLength(min: 3, max: 3)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
