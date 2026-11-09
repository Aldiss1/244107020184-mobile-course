import 'package:flutter/material.dart';
import '../models/mahasiswa.dart';
import '../services/api_service.dart';
import 'form_page.dart';

class MahasiswaListPage extends StatefulWidget {
  const MahasiswaListPage({super.key});

  @override
  State<MahasiswaListPage> createState() =>
      _MahasiswaListPageState();
}

class _MahasiswaListPageState
    extends State<MahasiswaListPage> {
  final api = ApiService();
  late Future<List<Mahasiswa>> _future;

  @override
  void initState() {
    super.initState();
    // panggil API saat halaman dibuka
    _future = api.getAll();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = api.getAll(); // minta data terbaru
    });
    await _future;
  }

  // m == null -> tambah, m != null -> edit
  Future<void> _bukaForm([Mahasiswa? m]) async {
    final berhasil = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormPage(mahasiswa: m),
      ),
    );
    if (berhasil == true) _refresh();
  }

  Future<void> _hapus(Mahasiswa m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus data?'),
        content: Text('Yakin menghapus ${m.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.delete(m.id!);
      _tampilPesan('Data berhasil dihapus');
      _refresh();
    } catch (e) {
      _tampilPesan('$e');
    }
  }

  void _tampilPesan(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(pesan)));
  }

  Widget _buildItem(Mahasiswa m) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(m.nama[0].toUpperCase()),
      ),
      title: Text(m.nama),
      subtitle: Text('${m.nim} • ${m.prodi}'),
      onTap: () => _bukaForm(m),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _hapus(m),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Mahasiswa')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _bukaForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Mahasiswa>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('Belum ada data'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) => _buildItem(list[i]),
            ),
          );
        },
      ),
    );
  }
}
