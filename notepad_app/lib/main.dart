import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setEnabledSystemUIOverlays([]);
  runApp(NotepadApp());
}

class NotepadApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickNote',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFDCCFCA), // Arka plan rengi
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF291620), // AppBar rengi
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Color(0xFF291620), // Buton rengi
          ),
        ),
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
  User? _currentUser;
  bool _isLoggedIn = false; // Kullanıcı giriş durumunu tutan değişken

  @override
  void initState() {
    super.initState();
    notepadManager.initialize();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      setState(() {
        _isLoggedIn =
            true; // Kullanıcı girişi yapıldığında _isLoggedIn değerini true olarak ayarla
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 40,
              height: 40,
            ),
            SizedBox(width: 8),
            Text('QuickNote'),
          ],
        ),
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
                      child: Text('Bir hata oluştu'),
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
                      return Column(
                        children: [
                          ListTile(
                            title: Text(note.content),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: _isLoggedIn
                                      ? () {
                                          notepadManager
                                              .deleteNoteById(note.id);
                                        }
                                      : null,
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: _isLoggedIn
                                      ? () {
                                          setState(() {
                                            selectedNoteId = note.id;
                                            _textEditingController.text =
                                                note.content;
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                selectedNoteId = note.id;
                                _textEditingController.text = note.content;
                              });
                            },
                          ),
                          Divider(
                            color: Colors.black,
                            height: 1,
                          ),
                        ],
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
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFF291620),
                  ),
                ),
                hintText: 'Notunuzu girin...',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed:
                  _isLoggedIn // Kullanıcı girişi yapıldığında butona basılabilirliği kontrol et
                      ? () {
                          if (selectedNoteId.isEmpty) {
                            // Yeni not oluştur
                            String note = _textEditingController.text;
                            notepadManager.addNote(
                              note,
                              _currentUser!.uid,
                            );
                          } else {
                            // Notu güncelle
                            String note = _textEditingController.text;
                            notepadManager.updateNoteById(selectedNoteId, note);
                            selectedNoteId = '';
                          }
                          _textEditingController.clear();
                        }
                      : null,
              child: Text(selectedNoteId.isEmpty ? 'Kaydet' : 'Kaydet'),
            ),
            SizedBox(height: 16.0),
          ],
        ),
      ),
      floatingActionButton: _isLoggedIn
          ? null
          : FloatingActionButton(
              onPressed: () {
                _showLoginDialog();
              },
              child: Icon(Icons.login),
              backgroundColor: Color(0xFF0C5159),
            ),
      persistentFooterButtons: _isLoggedIn
          ? [
              ElevatedButton(
                onPressed: () {
                  _logout();
                },
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF7A1938),
                ),
                child: Text('Çıkış Yap'),
              ),
            ]
          : null,
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Giriş Yap'),
        content: LoginDialogContent(
          onLoggedIn: () {
            _getCurrentUser();
          },
          onRegister: () {
            _showRegisterDialog();
          },
        ),
      ),
    );
  }

  void _showRegisterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kayıt Ol'),
        content: RegisterDialogContent(
          onRegistered: () {
            _getCurrentUser();
          },
        ),
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _isLoggedIn =
          false; // Çıkış yapıldığında _isLoggedIn değerini false olarak ayarla
    });
  }
}

class LoginDialogContent extends StatefulWidget {
  final VoidCallback? onLoggedIn;
  final VoidCallback? onRegister;

  LoginDialogContent({this.onLoggedIn, this.onRegister});

  @override
  _LoginDialogContentState createState() => _LoginDialogContentState();
}

class _LoginDialogContentState extends State<LoginDialogContent> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _login();
              },
              child: Text('Giriş Yap'),
            ),
            SizedBox(height: 16.0),
            TextButton(
              onPressed: widget.onRegister,
              child: Text('Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }

  void _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş başarılı'),
          ),
        );
        if (widget.onLoggedIn != null) {
          widget.onLoggedIn!();
        }
      }
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giriş başarısız'),
        ),
      );
    }
  }
}

class RegisterDialogContent extends StatefulWidget {
  final VoidCallback? onRegistered;

  RegisterDialogContent({this.onRegistered});

  @override
  _RegisterDialogContentState createState() => _RegisterDialogContentState();
}

class _RegisterDialogContentState extends State<RegisterDialogContent> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _register();
              },
              child: Text('Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }

  void _register() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt başarılı'),
          ),
        );
        if (widget.onRegistered != null) {
          widget.onRegistered!();
        }
      }
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt başarısız'),
        ),
      );
    }
  }
}

class NotepadManager {
  final CollectionReference notesCollection =
      FirebaseFirestore.instance.collection('notes');
  late Stream<List<Note>> notesStream;

  void initialize() {
    notesStream = notesCollection.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return Note.fromSnapshot(doc);
        }).toList();
      },
    );
  }

  void addNote(String content, String userId) {
    notesCollection.add(
      {'content': content, 'userId': userId},
    );
  }

  void deleteNoteById(String id) {
    notesCollection.doc(id).delete();
  }

  void updateNoteById(String id, String content) {
    notesCollection.doc(id).update({'content': content});
  }
}

class Note {
  final String id;
  final String content;

  Note({
    required this.id,
    required this.content,
  });

  factory Note.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return Note(
      id: snapshot.id,
      content: data['content'],
    );
  }
}
