import 'package:drift/drift.dart';

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()(); // cash, bank, creditCard, wallet, other
  TextColumn get currency => text().withLength(min: 3, max: 3)(); // e.g. TND
  IntColumn get openingBalance => integer()(); // minor units, e.g. 1000 = 1 TND
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
