import 'package:flutter/material.dart';

import 'materi_colors.dart';

/// Satu baris tabel SOLID: huruf, nama prinsip, arti praktis, dan gejala
/// pelanggaran yang khas di Flutter.
@immutable
class SolidPrinciple {
  const SolidPrinciple({
    required this.letter,
    required this.name,
    required this.meaning,
    required this.symptom,
  });

  final String letter;
  final String name;
  final String meaning;
  final String symptom;
}

/// Isi slide "SOLID: Lima Prinsip dalam Bahasa Sehari-hari"
/// (Pemrograman Mobile · Minggu 7 · Clean Architecture).
///
/// Dipisah dari widget supaya teksnya bisa dipakai ulang — misalnya untuk
/// test atau materi di tempat lain — tanpa ikut membangun UI.
const List<SolidPrinciple> kSolidPrinciples = [
  SolidPrinciple(
    letter: 'S',
    name: 'Single Responsibility',
    meaning: 'Satu kelas, satu alasan untuk berubah',
    symptom: 'Widget 400 baris: fetch API + parsing JSON + format tanggal',
  ),
  SolidPrinciple(
    letter: 'O',
    name: 'Open/Closed',
    meaning: 'Tambah perilaku lewat ekstensi, bukan mengedit kode lama',
    symptom: 'Sumber data baru memaksa edit widget yang sudah jalan',
  ),
  SolidPrinciple(
    letter: 'L',
    name: 'Liskov Substitution',
    meaning: 'Pengganti harus bisa menggantikan aslinya tanpa merusak',
    symptom: 'Repository palsu melempar error yang tak pernah dilempar aslinya',
  ),
  SolidPrinciple(
    letter: 'I',
    name: 'Interface Segregation',
    meaning: 'Jangan paksa klien bergantung pada yang tak dipakai',
    symptom: 'Satu AppRepository raksasa untuk auth + notes + push',
  ),
  SolidPrinciple(
    letter: 'D',
    name: 'Dependency Inversion',
    meaning: 'Bergantung pada abstraksi, bukan implementasi',
    symptom: 'Notifier memanggil Dio / sqflite langsung',
  ),
];

/// Lebar layar mulai dari sini memakai tata letak tiga kolom seperti slide;
/// di bawahnya setiap prinsip menjadi satu kartu bertumpuk.
const double _kWideLayoutBreakpoint = 820;

class SolidPage extends StatelessWidget {
  const SolidPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOLID')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _kWideLayoutBreakpoint;
            return ListView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 32 : 16,
                vertical: 24,
              ),
              children: [
                const _Header(),
                SizedBox(height: wide ? 28 : 20),
                if (wide) const _WideTable() else const _StackedList(),
                const SizedBox(height: 24),
                const _FooterNote(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SOLID: Lima Prinsip dalam Bahasa Sehari-hari',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: MateriColors.navy,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pemrograman Mobile · Minggu 7 · Clean Architecture',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: MateriColors.slate,
              ),
        ),
      ],
    );
  }
}

/// Tata letak tiga kolom: prinsip · arti praktis · gejala.
class _WideTable extends StatelessWidget {
  const _WideTable();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Column(
      children: [
        Row(
          children: [
            const Spacer(flex: 34),
            Expanded(
              flex: 27,
              child: Text(
                'Arti praktis',
                style: labelStyle?.copyWith(color: MateriColors.slate),
              ),
            ),
            Expanded(
              flex: 39,
              child: Text(
                'Gejala pelanggaran di Flutter',
                style: labelStyle?.copyWith(color: MateriColors.brick),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final principle in kSolidPrinciples) ...[
          _WideRow(principle: principle),
          if (principle != kSolidPrinciples.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _WideRow extends StatelessWidget {
  const _WideRow({required this.principle});

  final SolidPrinciple principle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 34, child: _PrincipleLabel(principle: principle)),
        Expanded(
          flex: 27,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              principle.meaning,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MateriColors.ink,
                    height: 1.4,
                  ),
            ),
          ),
        ),
        Expanded(
          flex: 39,
          child: _SymptomCard(text: principle.symptom),
        ),
      ],
    );
  }
}

/// Satu kartu per prinsip, dipakai saat layar sempit.
class _StackedList extends StatelessWidget {
  const _StackedList();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        for (final principle in kSolidPrinciples) ...[
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PrincipleLabel(principle: principle),
                  const SizedBox(height: 12),
                  Text(
                    'Arti praktis',
                    style: textTheme.labelSmall?.copyWith(
                      color: MateriColors.slate,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    principle.meaning,
                    style: textTheme.bodyMedium?.copyWith(
                      color: MateriColors.ink,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gejala pelanggaran di Flutter',
                    style: textTheme.labelSmall?.copyWith(
                      color: MateriColors.brick,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _SymptomCard(text: principle.symptom),
                ],
              ),
            ),
          ),
          if (principle != kSolidPrinciples.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PrincipleLabel extends StatelessWidget {
  const _PrincipleLabel({required this.principle});

  final SolidPrinciple principle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LetterBadge(letter: principle.letter),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            principle.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: MateriColors.navy,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: MateriColors.teal,
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SymptomCard extends StatelessWidget {
  const _SymptomCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MateriColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: MateriColors.ink,
              height: 1.4,
            ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Ingat: yang dinilai adalah arah panah dependensi, bukan kedalaman '
      'folder.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: MateriColors.slate,
            fontStyle: FontStyle.italic,
          ),
    );
  }
}
