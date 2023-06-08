// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$AppDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$AppDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  DailyExpensesDao? _dailyExpensesDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `DailyExpensesTable` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `dateTime` TEXT NOT NULL, `date` TEXT NOT NULL, `city` TEXT NOT NULL, `reason` TEXT NOT NULL, `amount` TEXT NOT NULL)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  DailyExpensesDao get dailyExpensesDao {
    return _dailyExpensesDaoInstance ??=
        _$DailyExpensesDao(database, changeListener);
  }
}

class _$DailyExpensesDao extends DailyExpensesDao {
  _$DailyExpensesDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _dailyExpensesTableInsertionAdapter = InsertionAdapter(
            database,
            'DailyExpensesTable',
            (DailyExpensesTable item) => <String, Object?>{
                  'id': item.id,
                  'dateTime': item.dateTime,
                  'date': item.date,
                  'city': item.city,
                  'reason': item.reason,
                  'amount': item.amount
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<DailyExpensesTable>
      _dailyExpensesTableInsertionAdapter;

  @override
  Future<List<DailyExpensesTable>> getAllExpenses() async {
    return _queryAdapter.queryList(
        'SELECT * FROM DailyExpensesTable ORDER by datetime DESC, reason ASC',
        mapper: (Map<String, Object?> row) => DailyExpensesTable(
            row['dateTime'] as String,
            row['date'] as String,
            row['amount'] as String,
            row['reason'] as String,
            row['city'] as String));
  }

  @override
  Future<DailyExpensesTable?> getExpensesByID(int id) async {
    return _queryAdapter.query(
        'SELECT * FROM DailyExpensesTable WHERE id = ?1 ORDER by datetime DESC, reason ASC',
        mapper: (Map<String, Object?> row) => DailyExpensesTable(row['dateTime'] as String, row['date'] as String, row['amount'] as String, row['reason'] as String, row['city'] as String),
        arguments: [id]);
  }

  @override
  Future<List<DailyExpensesTable>> getExpensesByDate(String date) async {
    return _queryAdapter.queryList(
        'SELECT * FROM DailyExpensesTable WHERE date = ?1 ORDER by datetime DESC, reason ASC',
        mapper: (Map<String, Object?> row) => DailyExpensesTable(row['dateTime'] as String, row['date'] as String, row['amount'] as String, row['reason'] as String, row['city'] as String),
        arguments: [date]);
  }

  @override
  Future<List<DailyExpensesTable>> getExpensesBetweenDay(
    String startDate,
    String endDate,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM DailyExpensesTable WHERE date >= ?1 AND date <= ?2 ORDER by datetime DESC, reason ASC',
        mapper: (Map<String, Object?> row) => DailyExpensesTable(row['dateTime'] as String, row['date'] as String, row['amount'] as String, row['reason'] as String, row['city'] as String),
        arguments: [startDate, endDate]);
  }

  @override
  Future<void> insertExpenses(DailyExpensesTable user) async {
    await _dailyExpensesTableInsertionAdapter.insert(
        user, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertExpensesList(List<DailyExpensesTable> user) async {
    await _dailyExpensesTableInsertionAdapter.insertList(
        user, OnConflictStrategy.abort);
  }
}
