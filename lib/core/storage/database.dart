import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "iBankDatabase.db";
  static const _databaseVersion = 7;
  static const tableCards = 'cards';
  static const tableIds = 'ids';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.transaction((txn) async {
      if (oldVersion < 2) {
        await txn.execute('''
            CREATE TABLE $tableIds (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nickname TEXT NOT NULL,
              idType TEXT NOT NULL,
              encryptedData TEXT NOT NULL,
              encryptedImagePath TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
            ''');
        await txn.execute('CREATE INDEX idx_idType ON $tableIds (idType)');
        await txn.execute('CREATE INDEX idx_createdAt ON $tableIds (createdAt)');
      }
      
      if (oldVersion < 3) {
        await txn.execute('ALTER TABLE $tableCards ADD COLUMN isPinnedToTop INTEGER DEFAULT 0');
        await txn.execute('ALTER TABLE $tableCards ADD COLUMN isPinnedToHomescreen INTEGER DEFAULT 0');
        await txn.execute('ALTER TABLE $tableIds ADD COLUMN isPinnedToTop INTEGER DEFAULT 0');
        await txn.execute('ALTER TABLE $tableIds ADD COLUMN isPinnedToHomescreen INTEGER DEFAULT 0');
      }

      if (oldVersion < 4) {
        // FIX 2-1: cards move from five separately-encrypted columns to a single
        // encryptedData payload, so that saving or revealing a card costs one
        // authenticated cipher operation instead of five.
        //
        // Existing rows are dropped rather than migrated. They were encrypted
        // under the old un-authenticated key alias (ibank_master_key_v2), which
        // is abandoned by this same change, so their contents are already
        // unrecoverable — carrying the ciphertext forward would only leave rows
        // that can never be decrypted.
        await txn.execute('DROP TABLE IF EXISTS $tableCards');
        await txn.execute('''
            CREATE TABLE $tableCards (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nickname TEXT NOT NULL,
              cardBrand TEXT NOT NULL,
              lastFourDigits TEXT NOT NULL,
              encryptedData TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              isPinnedToTop INTEGER DEFAULT 0,
              isPinnedToHomescreen INTEGER DEFAULT 0
            )
            ''');
      }

      if (oldVersion < 5) {
        // Vestigial. Photos were briefly kept as separate encrypted files with
        // their name in this column, which cost a second authentication prompt
        // to open; they now travel inside encryptedData instead. The column is
        // added anyway so that a device which already ran this migration and one
        // which has not end up with the same schema. Nothing reads or writes it.
        // Safe to drop along with lockType whenever the schema is next rebuilt.
        await txn.execute(
          'ALTER TABLE $tableCards ADD COLUMN encryptedImagePath TEXT',
        );
      }

      if (oldVersion < 6) {
        // Whether an item has a photo, stored unencrypted on purpose.
        //
        // The photo itself lives inside the encrypted payload, which the vault
        // list deliberately does not read — so without this flag the list has no
        // way to show a "has a photo" badge without spending an authentication
        // prompt per item just to find out.
        //
        // It leaks only the fact that a picture is attached, which is no more
        // than the nickname and card brand sitting unencrypted in the same row
        // already give away. The picture itself stays sealed.
        await txn.execute(
          'ALTER TABLE $tableCards ADD COLUMN hasPhoto INTEGER DEFAULT 0',
        );
        await txn.execute(
          'ALTER TABLE $tableIds ADD COLUMN hasPhoto INTEGER DEFAULT 0',
        );
      }

      if (oldVersion < 7) {
        // The last day an item is valid, stored unencrypted, so that Karde can
        // warn before a card or a passport runs out.
        //
        // This is the one place where the vault gives something up, and it was
        // the user's decision rather than a convenience taken quietly. Karde
        // cannot read an expiry date that is sealed: the vault key demands an
        // authentication prompt for every use, so checking eight items would
        // mean eight fingerprint touches every time the app opened. There is no
        // version of this warning that works without the date being readable.
        //
        // What that costs, exactly. Somebody holding the database file but not
        // the key learns when each card and document expires, alongside the
        // nickname, the brand and the last four digits already sitting there.
        // The card number, the security code, the document number, the holder's
        // name and the photograph all stay sealed, so this does not assemble
        // into a usable card. It is still a real reduction, which is why the
        // feature has a switch that erases every one of these dates.
        //
        // Null until the item is next saved, or until the user asks Karde to
        // read the ones already stored — which costs the prompts described
        // above, once.
        await txn.execute(
          'ALTER TABLE $tableCards ADD COLUMN expiresOn TEXT',
        );
        await txn.execute(
          'ALTER TABLE $tableIds ADD COLUMN expiresOn TEXT',
        );
      }
    });
  }

  /// Writes one item's expiry date, touching nothing else in the row.
  ///
  /// Deliberately not `updateCard(card.toMap())`. The lists this is driven from
  /// carry no encrypted payload — [queryCardSummaries] does not select it — so
  /// writing a whole row built from a summary would replace the ciphertext with
  /// an empty string and destroy the card. A targeted update cannot make that
  /// mistake.
  Future<void> setCardExpiry(int id, DateTime? expiresOn) async {
    final db = await database;
    await db.update(
      tableCards,
      {'expiresOn': expiresOn?.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// As [setCardExpiry], for a document.
  Future<void> setIdExpiry(int id, DateTime? expiresOn) async {
    final db = await database;
    await db.update(
      tableIds,
      {'expiresOn': expiresOn?.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Forgets every stored expiry date, in both tables.
  ///
  /// What "turn expiry reminders off" actually does. Leaving the dates behind
  /// would make the switch a lie: the point of turning it off is that the dates
  /// stop being readable without the key, and that only happens if they go.
  Future<void> clearAllExpiryDates() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(tableCards, {'expiresOn': null});
      await txn.update(tableIds, {'expiresOn': null});
    });
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableCards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nickname TEXT NOT NULL,
            cardBrand TEXT NOT NULL,
            lastFourDigits TEXT NOT NULL,
            encryptedData TEXT NOT NULL,
            encryptedImagePath TEXT,
            hasPhoto INTEGER DEFAULT 0,
            expiresOn TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            isPinnedToTop INTEGER DEFAULT 0,
            isPinnedToHomescreen INTEGER DEFAULT 0
          )
          ''');

    // Create ids table on fresh install
    await db.execute('''
          CREATE TABLE $tableIds (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nickname TEXT NOT NULL,
            idType TEXT NOT NULL,
            encryptedData TEXT NOT NULL,
            encryptedImagePath TEXT,
            hasPhoto INTEGER DEFAULT 0,
            expiresOn TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            isPinnedToTop INTEGER DEFAULT 0,
            isPinnedToHomescreen INTEGER DEFAULT 0
          )
          ''');
    await db.execute('CREATE INDEX idx_idType ON $tableIds (idType)');
    await db.execute('CREATE INDEX idx_createdAt ON $tableIds (createdAt)');
  }

  // FIX 9-3: these were named insert/queryAllRows/update/delete but every one of
  // them hardcodes tableCards. The generic names invited callers to pass an ID row
  // and silently write it into the cards table; the names now say what they do.

  Future<int> insertCard(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableCards, row);
  }

  /// Every card, WITHOUT its encrypted payload.
  ///
  /// The payload now carries the card photo, so a photographed card's is close to
  /// a megabyte. The vault list and the dashboard rebuild often and decrypt
  /// nothing, so selecting it there would drag every photo's ciphertext through
  /// memory on each rebuild to display a nickname and four digits. Callers that
  /// actually need the payload fetch it by id with [cardPayload], and they are
  /// all about to spend an authentication prompt anyway, so one extra read by
  /// primary key costs nothing next to it.
  Future<List<Map<String, dynamic>>> queryCardSummaries() async {
    Database db = await instance.database;
    return await db.query(
      tableCards,
      columns: const [
        'id',
        'nickname',
        'cardBrand',
        'lastFourDigits',
        'hasPhoto',
        'expiresOn',
        'createdAt',
        'updatedAt',
        'isPinnedToTop',
        'isPinnedToHomescreen',
      ],
      orderBy: "createdAt DESC",
    );
  }

  /// The encrypted payload of one card, or null if the row is gone.
  Future<String?> cardPayload(int id) async {
    Database db = await instance.database;
    final rows = await db.query(
      tableCards,
      columns: const ['encryptedData'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['encryptedData'] as String?;
  }

  /// Every ID document, WITHOUT its encrypted payload. See [queryCardSummaries].
  Future<List<Map<String, dynamic>>> queryIdSummaries() async {
    Database db = await instance.database;
    return await db.query(
      tableIds,
      columns: const [
        'id',
        'nickname',
        'idType',
        'hasPhoto',
        'expiresOn',
        'createdAt',
        'updatedAt',
        'isPinnedToTop',
        'isPinnedToHomescreen',
      ],
      orderBy: "createdAt DESC",
    );
  }

  /// The encrypted payload of one ID document, or null if the row is gone.
  Future<String?> idPayload(int id) async {
    Database db = await instance.database;
    final rows = await db.query(
      tableIds,
      columns: const ['encryptedData'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['encryptedData'] as String?;
  }

  Future<int> updateCard(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(tableCards, _keepPayload(row), where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateId(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(tableIds, _keepPayload(row), where: 'id = ?', whereArgs: [id]);
  }

  /// Drops an empty `encryptedData` from an update, leaving the stored one alone.
  ///
  /// This guards a trap the list projection creates. Rows from
  /// [queryCardSummaries] / [queryIdSummaries] deliberately carry no payload, so
  /// a model built from one has `encryptedData: ''`. Pinning a card from the vault
  /// list does exactly `card.copyWith(isPinnedToTop: ...)` and writes it back —
  /// which, without this, would overwrite a perfectly good ciphertext with an
  /// empty string and destroy the card while appearing to succeed.
  ///
  /// An empty payload is never legitimate: every record is written with one. So
  /// treating "empty" as "not supplied" is safe, and it protects every caller
  /// rather than asking each one to remember.
  Map<String, dynamic> _keepPayload(Map<String, dynamic> row) {
    final payload = row['encryptedData'];
    if (payload is String && payload.isNotEmpty) return row;
    return Map<String, dynamic>.from(row)..remove('encryptedData');
  }

  Future<int> deleteCard(int id) async {
    Database db = await instance.database;
    return await db.delete(tableCards, where: 'id = ?', whereArgs: [id]);
  }

  /// Writes a whole restored backup in one transaction.
  ///
  /// A restore re-encrypts every record under this device's vault key, which
  /// costs one authentication prompt per record. If the user dismisses a prompt
  /// part way through, or the key is invalidated mid-restore, the rows written
  /// so far must not survive — a vault holding an arbitrary prefix of a backup is
  /// worse than one holding none of it, because the user has no way to tell which
  /// items made it across. Rows are expected to carry no `id`, so SQLite assigns
  /// fresh ones rather than colliding with what is already stored.
  Future<void> insertRestoredRecords({
    required List<Map<String, dynamic>> cards,
    required List<Map<String, dynamic>> ids,
  }) async {
    Database db = await instance.database;
    await db.transaction((txn) async {
      for (final row in cards) {
        await txn.insert(tableCards, row);
      }
      for (final row in ids) {
        await txn.insert(tableIds, row);
      }
    });
  }

  Future<void> deleteDatabaseFile() async {
    String path = join(await getDatabasesPath(), _databaseName);
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await deleteDatabase(path);
  }
}
