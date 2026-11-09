import 'package:flutter/material.dart';
import '../models/mahasiswa.dart';
import '../services/api_service.dart';

class FormPage extends StatefulWidget {
  // null = mode tambah, terisi = mode edit
  final Mahasiswa? mahasiswa;
  const FormPage({super.key, this.mahasiswa});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final api = ApiService();
  late final TextEditingController nimC, namaC, prodiC, emailC;
  bool _loading = false;

  bool get isEdit => widget.mahasiswa != null;

  @override
  void initState() {
    super.initState();
    // isi awal form (kosong jika mode tambah)
    final m = widget.mahasiswa;
    nimC = TextEditingController(text: m?.nim);
    namaC = TextEditingController(text: m?.nama);
    prodiC = TextEditingController(text: m?.prodi);
    emailC = TextEditingController(text: m?.email);
  }

  @override
  void dispose() {
    nimC.dispose();
    namaC.dispose();
    prodiC.dispose();
    emailC.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = Mahasiswa(
      nim: nimC.text.trim(),
      nama: namaC.text.trim(),
      prodi: prodiC.text.trim(),
      email: emailC.text.trim(),
    );

    try {
      if (isEdit) {
        await api.update(widget.mahasiswa!.id!, data);
      } else {
        await api.create(data);
      }
      if (!mounted) return;
      // kirim "true" ke halaman list
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? '$label wajib diisi'
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Mahasiswa' : 'Tambah Mahasiswa'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(nimC, 'NIM'),
            _field(namaC, 'Nama'),
            _field(prodiC, 'Prodi'),
            _field(emailC, 'Email'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loading ? null : _simpan,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
