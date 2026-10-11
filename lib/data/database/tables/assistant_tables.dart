import 'package:drift/drift.dart';

/// K1: metinsiz, yalnız cihazda. SyncColumns/tetikleyici/bulut kaydı YOK.
@DataClassName('AssistantQualityEvent')
class AssistantQualityEvents extends Table {
  TextColumn get eventId => text()();
  TextColumn get ownerId => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get source => text()();
  IntColumn get contractVersion => integer().withDefault(const Constant(2))();
  TextColumn get model => text().nullable()();
  TextColumn get fingerprint => text().nullable()();
  TextColumn get decision => text()();
  TextColumn get outcome => text().withDefault(const Constant('completed'))();
  TextColumn get queryId => text().nullable()();
  TextColumn get periodId => text().nullable()();
  TextColumn get exerciseType => text().withDefault(const Constant('none'))();
  BoolColumn get wantsInterpretation =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get ambiguous => boolean().withDefault(const Constant(false))();
  TextColumn get correctedQueryId => text().nullable()();
  TextColumn get correctedPeriodId => text().nullable()();
  BoolColumn get exerciseChanged =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get clarified => boolean().withDefault(const Constant(false))();
  IntColumn get latencyMs => integer().nullable()();
  IntColumn get inputTokens => integer().nullable()();
  IntColumn get outputTokens => integer().nullable()();
  TextColumn get errorCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {eventId};
}
