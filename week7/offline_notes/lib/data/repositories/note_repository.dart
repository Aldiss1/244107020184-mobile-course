import '../local/db.dart';
import '../local/note.dart';

class NoteRepository {
  final DatabaseHelper _dbHelper;

  NoteRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Note>> fetchNotes() async {
    return await _dbHelper.getAllNotes();
  }

  Future<int> addNote(Note note) async {
    return await _dbHelper.insertNote(note);
  }

  Future<int> updateNote(Note note) async {
    return await _dbHelper.updateNote(note);
  }

  Future<int> deleteNote(int id) async {
    return await _dbHelper.deleteNote(id);
  }
}
