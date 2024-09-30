import 'package:flutter/foundation.dart' show immutable;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '/models/party.dart';
import '/models/guest.dart';  // You'll need to create this model

@immutable
class PartyDatabase {
  static const String _databaseName = 'partiesDatabase.db';
  static const int _databaseVersion = 2;  // Increased version number

  // Create a singleton
  const PartyDatabase._privateConstructor();
  static const PartyDatabase instance = PartyDatabase._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    final String path = join(dbPath, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  //! Create Database method
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $partyTable (
        ${PartyFields.id} $idType,
        ${PartyFields.title} $textType,
        ${PartyFields.description} $textType,
        ${PartyFields.date} $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $guestTable (
        ${GuestFields.id} $idType,
        ${GuestFields.partyId} INTEGER NOT NULL,
        ${GuestFields.name} $textType,
        ${GuestFields.email} $textType,
        FOREIGN KEY (${GuestFields.partyId}) REFERENCES $partyTable(${PartyFields.id}) ON DELETE CASCADE
      )
    ''');
  }

  //! Upgrade Database method
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $guestTable (
          ${GuestFields.id} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${GuestFields.partyId} INTEGER NOT NULL,
          ${GuestFields.name} TEXT NOT NULL,
          ${GuestFields.email} TEXT NOT NULL,
          FOREIGN KEY (${GuestFields.partyId}) REFERENCES $partyTable(${PartyFields.id}) ON DELETE CASCADE
        )
      ''');
    }
  }

  //! C --> CRUD = Create
  Future<Party> createParty(Party party) async {
    final db = await instance.database;
    final id = await db.insert(
      partyTable,
      party.toMap(),
    );
    return party.copy(id: id);
  }

  Future<Guest> createGuest(Guest guest) async {
    if (guest.partyId == null) {
      throw Exception('Cannot create a guest without a party');
    }
    if (guest.name.isEmpty) {
      throw Exception('Cannot create a guest without a name');
    }
    if (guest.email.isEmpty) {
      throw Exception('Cannot create a guest without an email');
    }
    if (guest.id != null) {
        final id = await updateGuest(guest);
        return guest.copy(id: id);
    }
    final db = await instance.database;
    final id = await db.insert(
      guestTable,
      guest.toMap(),
    );
    return guest.copy(id: id);
  }

  //! R -- CURD = Read
  Future<Party> readParty(int id) async {
    final db = await instance.database;
    final partyData = await db.query(
      partyTable,
      columns: PartyFields.values,
      where: '${PartyFields.id} = ?',
      whereArgs: [id],
    );
    if (partyData.isNotEmpty) {
      return Party.fromMap(partyData.first);
    } else {
      throw Exception('Could not find a party with the given ID');
    }
  }

  Future<List<Guest>> readGuestsForParty(int partyId) async {
    final db = await instance.database;
    final guestData = await db.query(
      guestTable,
      columns: GuestFields.values,
      where: '${GuestFields.partyId} = ?',
      whereArgs: [partyId],
    );
    return guestData.map((data) => Guest.fromMap(data)).toList();
  }

  // Get All Parties
  Future<List<Party>> readAllParties() async {
    final db = await instance.database;
    final result =
        await db.query(partyTable, orderBy: '${PartyFields.date} ASC');
    return result.map((partyData) => Party.fromMap(partyData)).toList();
  }

  //! U --> CRUD = Update
  Future<int> updateParty(Party party) async {
    final db = await instance.database;
    return await db.update(
      partyTable,
      party.toMap(),
      where: '${PartyFields.id} = ?',
      whereArgs: [party.id],
    );
  }

  Future<int> updateGuest(Guest guest) async {
    final db = await instance.database;
    return await db.update(
      guestTable,
      guest.toMap(),
      where: '${GuestFields.id} = ?',
      whereArgs: [guest.id],
    );
  }

  //! D --> CRUD = Delete
  Future<int> deleteParty(int id) async {
    final db = await instance.database;
    return await db.delete(
      partyTable,
      where: '${PartyFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGuest(int id) async {
    final db = await instance.database;
    return await db.delete(
      guestTable,
      where: '${GuestFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future deleteAllGuestsForParty(int partyId) async {
    final db = await instance.database;
    return await db.delete(
      guestTable,
      where: '${GuestFields.partyId} = ?',
      whereArgs: [partyId],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}