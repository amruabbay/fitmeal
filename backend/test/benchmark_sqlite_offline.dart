/// ==========================================================================
/// ⏱️ CONTOH FUNGSI FLUTTER — Mengukur Response Time Query SQLite Lokal
/// ==========================================================================
///
/// File ini berisi contoh implementasi fungsi di Flutter untuk mengukur
/// latensi (ms) saat melakukan query pencarian data makanan secara lokal
/// di SQLite menggunakan `Stopwatch()`.
///
/// Cara pakai:
///   1. Copy fungsi-fungsi di bawah ke project Flutter Anda.
///   2. Pastikan package `sqflite` sudah ditambahkan di pubspec.yaml.
///   3. Panggil `runBenchmarkPencarianOffline()` dari halaman debug/test.
///
/// Dependensi: sqflite, path
/// ==========================================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// ==========================================================================
/// 🔧 HELPER: Buka koneksi database
/// ==========================================================================
Future<Database> _openFoodDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'skripsi_diet.db');

  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Tabel ini seharusnya sudah ada dari sinkronisasi awal
      await db.execute('''
        CREATE TABLE IF NOT EXISTS food_cache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fatsecret_id TEXT UNIQUE,
          nama_makanan TEXT,
          deskripsi_asli TEXT,
          kategori TEXT,
          kalori REAL,
          protein REAL,
          karbo REAL,
          lemak REAL,
          porsi_gram REAL DEFAULT 100
        )
      ''');
    },
  );
}

/// ==========================================================================
/// ⏱️ FUNGSI UTAMA: Mengukur waktu query pencarian SQLite
/// ==========================================================================
/// Fungsi ini melakukan query SELECT pencarian makanan berdasarkan kata kunci,
/// lalu mengukur berapa lama waktu eksekusi menggunakan Stopwatch().
///
/// [keyword]  : Kata kunci pencarian (misal: "nasi", "ayam", "tempe")
/// [iterasi]  : Jumlah pengulangan query untuk mendapat rata-rata stabil
///
/// Returns: Map berisi statistik waktu (mean, min, max) dalam milidetik.
///
Future<Map<String, dynamic>> ukurWaktuQueryLokal({
  required String keyword,
  int iterasi = 10,
}) async {
  final db = await _openFoodDatabase();
  final List<double> waktuList = [];
  int jumlahHasil = 0;

  for (int i = 0; i < iterasi; i++) {
    // --- Mulai stopwatch ---
    final stopwatch = Stopwatch()..start();

    // --- Query pencarian (sama persis dengan logika backend) ---
    final List<String> keywords = keyword.toLowerCase().split(' ');
    final List<String> clauses = [];
    final List<String> params = [];

    for (final k in keywords) {
      clauses.add("lower(nama_makanan) LIKE ?");
      params.add('%$k%');
    }

    final sqlQuery =
        "SELECT * FROM food_cache WHERE ${clauses.join(' OR ')}";

    final results = await db.rawQuery(sqlQuery, params);

    // --- Hentikan stopwatch ---
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000.0; // μs → ms
    waktuList.add(elapsedMs);

    // Simpan jumlah hasil dari iterasi pertama
    if (i == 0) {
      jumlahHasil = results.length;
    }
  }

  await db.close();

  // --- Hitung statistik ---
  if (waktuList.isEmpty) {
    return {
      'keyword': keyword,
      'error': 'Tidak ada iterasi yang berhasil',
    };
  }

  final meanMs = waktuList.reduce((a, b) => a + b) / waktuList.length;
  final minMs = waktuList.reduce((a, b) => a < b ? a : b);
  final maxMs = waktuList.reduce((a, b) => a > b ? a : b);

  // Standard Deviation
  double stdMs = 0;
  if (waktuList.length > 1) {
    final variance = waktuList
            .map((t) => (t - meanMs) * (t - meanMs))
            .reduce((a, b) => a + b) /
        (waktuList.length - 1);
    stdMs = variance > 0 ? _sqrt(variance) : 0;
  }

  return {
    'keyword': keyword,
    'mean_ms': double.parse(meanMs.toStringAsFixed(3)),
    'min_ms': double.parse(minMs.toStringAsFixed(3)),
    'max_ms': double.parse(maxMs.toStringAsFixed(3)),
    'std_ms': double.parse(stdMs.toStringAsFixed(3)),
    'jumlah_hasil': jumlahHasil,
    'iterasi': iterasi,
  };
}

/// Helper: Square root (karena dart:math mungkin belum diimport)
double _sqrt(double value) {
  // Newton's method approximation
  if (value <= 0) return 0;
  double guess = value / 2;
  for (int i = 0; i < 20; i++) {
    guess = (guess + value / guess) / 2;
  }
  return guess;
}

/// ==========================================================================
/// 🚀 FUNGSI BENCHMARK: Jalankan semua kata kunci pencarian
/// ==========================================================================
/// Panggil fungsi ini dari halaman debug / tombol test di aplikasi Flutter.
///
/// Contoh pemanggilan:
/// ```dart
/// ElevatedButton(
///   onPressed: () async {
///     await runBenchmarkPencarianOffline();
///   },
///   child: Text('Run Benchmark'),
/// )
/// ```
///
Future<void> runBenchmarkPencarianOffline() async {
  final List<String> kataKunciUji = [
    'nasi', 'ayam', 'tempe', 'bayam', 'pisang',
    'ikan', 'roti', 'telur', 'kangkung', 'jeruk',
  ];

  print('═' * 60);
  print('  ⏱️ BENCHMARK PENCARIAN OFFLINE (SQLite)');
  print('═' * 60);

  final List<Map<String, dynamic>> semuaHasil = [];

  for (final keyword in kataKunciUji) {
    final hasil = await ukurWaktuQueryLokal(
      keyword: keyword,
      iterasi: 10,
    );
    semuaHasil.add(hasil);

    if (hasil.containsKey('error')) {
      print('  ❌ "$keyword" → ${hasil['error']}');
    } else {
      print(
        '  ✅ "$keyword" → '
        'mean: ${hasil['mean_ms']} ms, '
        'min: ${hasil['min_ms']} ms, '
        'max: ${hasil['max_ms']} ms, '
        'hasil: ${hasil['jumlah_hasil']}',
      );
    }
  }

  // --- Ringkasan ---
  final berhasil =
      semuaHasil.where((h) => !h.containsKey('error')).toList();
  if (berhasil.isNotEmpty) {
    final allMeans =
        berhasil.map((h) => h['mean_ms'] as double).toList();
    final avgMean =
        allMeans.reduce((a, b) => a + b) / allMeans.length;
    final globalMin =
        allMeans.reduce((a, b) => a < b ? a : b);
    final globalMax =
        allMeans.reduce((a, b) => a > b ? a : b);

    print('');
    print('─' * 60);
    print('  📊 RINGKASAN:');
    print('     Rata-rata keseluruhan : ${avgMean.toStringAsFixed(3)} ms');
    print('     Query tercepat        : ${globalMin.toStringAsFixed(3)} ms');
    print('     Query terlambat       : ${globalMax.toStringAsFixed(3)} ms');
    print('─' * 60);

    if (avgMean < 5.0) {
      print('  ⚡ Query SQLite lokal SANGAT CEPAT (<5ms).');
      print('     Offline-first approach terbukti efektif.');
    } else if (avgMean < 50.0) {
      print('  ✅ Query SQLite lokal CEPAT (<50ms). Responsif untuk UX.');
    } else {
      print('  ⚠️ Query SQLite lokal >50ms. Pertimbangkan indexing.');
    }
  }

  print('═' * 60);
}
