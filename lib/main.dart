import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(CardOrganizerApp());
}

class CardOrganizerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FolderListScreen(),
    );
  }
}

class FolderListScreen extends StatefulWidget {
  @override
  _FolderListScreenState createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  List<Map<String, dynamic>> _folders = [];
  late DatabaseHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _fetchFolders();
  }

  Future<void> _fetchFolders() async {
    final folders = await _dbHelper.getFolders();
    setState(() {
      _folders = folders;
    });
  }

  Future<void> _showAddFolderDialog() async {
    String folderName = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Folder'),
          content: TextField(
            onChanged: (value) {
              folderName = value;
            },
            decoration: InputDecoration(hintText: 'Folder Name'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _dbHelper.addFolder(folderName);
                Navigator.pop(context);
                _fetchFolders();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Folders'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddFolderDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          final folder = _folders[index];
          return ListTile(
            title: Text(folder['folder_name']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CardGridScreen(folderId: folder['id']),
                ),
              ).then((_) => _fetchFolders());
            },
          );
        },
      ),
    );
  }
}

class CardGridScreen extends StatefulWidget {
  final int folderId;

  CardGridScreen({required this.folderId});

  @override
  _CardGridScreenState createState() => _CardGridScreenState();
}

class _CardGridScreenState extends State<CardGridScreen> {
  List<Map<String, dynamic>> _cards = [];
  late DatabaseHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    final cards = await _dbHelper.getCardsForFolder(widget.folderId);
    setState(() {
      _cards = cards;
    });
  }

  Future<void> _showAddCardDialog() async {
    List<Map<String, dynamic>> availableCards =
        await _dbHelper.getAvailableCards();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select a Card'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableCards.length,
              itemBuilder: (context, index) {
                final card = availableCards[index];
                return ListTile(
                  title: Text(card['name']),
                  onTap: () async {
                    try {
                      await _dbHelper.addCardToFolder(
                          card['id'], widget.folderId);
                      Navigator.pop(context);
                      _fetchCards();
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteCard(int cardId) async {
    await _dbHelper.removeCardFromFolder(cardId);
    _fetchCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cards in Folder'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddCardDialog,
          ),
        ],
      ),
      body: GridView.builder(
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
          return Card(
            child: Stack(
              children: [
                Center(
                  child: Text(
                    card['name'],
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteCard(card['id']);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
