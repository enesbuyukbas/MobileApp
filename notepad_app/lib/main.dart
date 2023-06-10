import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(NotepadApp());
}

class NotepadApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notepad',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotepadScreen(),
    );
  }
}

class NotepadScreen extends StatefulWidget {
  @override
  _NotepadScreenState createState() => _NotepadScreenState();
}

class _NotepadScreenState extends State<NotepadScreen> {
  TextEditingController _textEditingController = TextEditingController();
  NotepadManager notepadManager = NotepadManager();
  String selectedNoteId = '';

  @override
  void initState() {
    super.initState();
    notepadManager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notepad'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Note>>(
                stream: notepadManager.notesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('An error occurred'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  List<Note> notes = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      Note note = notes[index];
                      return ListTile(
                        title: Text(note.content),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            notepadManager.deleteNoteById(note.id);
                          },
                        ),
                        onTap: () {
                          setState(() {
                            selectedNoteId = note.id;
                            _textEditingController.text = note.content;
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _textEditingController,
              maxLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your note...',
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    String note = _textEditingController.text;
                    notepadManager.addNote(note);
                    _textEditingController.clear();
                  },
                  child: Text('Save'),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () {
                    String note = _textEditingController.text;
                    notepadManager.updateNoteById(selectedNoteId, note);
                    _textEditingController.clear();
                  },
                  child: Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Note {
  final String id;
  final String content;

  Note({
    required this.id,
    required this.content,
  });
}

class NotepadManager {
  final CollectionReference notesCollection =
      FirebaseFirestore.instance.collection('notes');
  late Stream<List<Note>> notesStream;

  void initialize() {
    notesStream = notesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Note(
          id: doc.id,
          content: doc['content'],
        );
      }).toList();
    });
  }

  void addNote(String content) {
    notesCollection.add({'content': content});
  }

  void deleteNoteById(String id) {
    notesCollection.doc(id).delete();
  }

  void updateNoteById(String id, String newContent) {
    notesCollection.doc(id).update({'content': newContent});
  }
}
