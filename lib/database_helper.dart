import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'card_organizer.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE folders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            folder_name TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE cards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            folder_id INTEGER
          )
        ''');

        await _insertDefaultFolders(db);
        await _insertDefaultCards(db);
      },
    );
  }

  Future<void> _insertDefaultFolders(Database db) async {
    const suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    for (var suit in suits) {
      await db.insert('folders', {'folder_name': suit});
    }
  }

  Future<void> _insertDefaultCards(Database db) async {
    const suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    for (var suit in suits) {
      for (var i = 1; i <= 13; i++) {
        await db.insert('cards', {'name': '$i of $suit'});
      }
    }
  }

  Future<void> addFolder(String folderName) async {
    final db = await database;
    await db.insert('folders', {'folder_name': folderName});
  }

  Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await database;
    return await db.query('folders');
  }

  Future<List<Map<String, dynamic>>> getCardsForFolder(int folderId) async {
    final db = await database;
    return await db
        .query('cards', where: 'folder_id = ?', whereArgs: [folderId]);
  }

  Future<List<Map<String, dynamic>>> getAvailableCards() async {
    final db = await database;
    return await db.rawQuery('SELECT * FROM cards WHERE folder_id IS NULL');
  }

  Future<void> addCardToFolder(int cardId, int folderId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM cards WHERE folder_id = ?', [folderId]));

    if (count != null && count >= 6) {
      throw Exception('Folder already has the maximum number of cards.');
    }

    await db.update('cards', {'folder_id': folderId},
        where: 'id = ?', whereArgs: [cardId]);
  }

  Future<void> removeCardFromFolder(int cardId) async {
    final db = await database;
    await db.update('cards', {'folder_id': null},
        where: 'id = ?', whereArgs: [cardId]);
  }

  Future<void> deleteFolder(int id) async {
    final db = await database;
    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
    await db.update('cards', {'folder_id': null},
        where: 'folder_id = ?', whereArgs: [id]);
  }
}
