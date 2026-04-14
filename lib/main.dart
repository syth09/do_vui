import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
// Sửa ở đây: Đặt alias cho package path
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Đồ Vui',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const GameSettingsScreen(),
    );
  }
}

class GameSettingsScreen extends StatefulWidget {
  const GameSettingsScreen({super.key});

  @override
  State<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  bool _amThanh = true;
  bool _tuDongLuu = true;
  int _diemCaoNhat = 3500;
  double _volume = 0.7;

  final TextEditingController _diemController = TextEditingController();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Sử dụng p.join thay vì join
    String dbPath = p.join(await getDatabasesPath(), 'game_settings.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key TEXT UNIQUE,
            value TEXT
          )
        ''');
      },
    );
  }

  // Load settings từ SQLite
  Future<void> _loadSettings() async {
    final db = await database;

    final amThanhMap = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['am_thanh'],
    );
    final tuDongLuuMap = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['tu_dong_luu'],
    );
    final diemMap = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['diem_cao_nhat'],
    );
    final volumeMap = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['volume'],
    );

    setState(() {
      _amThanh = amThanhMap.isNotEmpty
          ? amThanhMap.first['value'] == '1'
          : true;
      _tuDongLuu = tuDongLuuMap.isNotEmpty
          ? tuDongLuuMap.first['value'] == '1'
          : true;
      _diemCaoNhat = diemMap.isNotEmpty
          ? int.tryParse(diemMap.first['value'] ?? '3500') ?? 3500
          : 3500;
      _volume = volumeMap.isNotEmpty
          ? double.tryParse(volumeMap.first['value'] ?? '0.7') ?? 0.7
          : 0.7;

      _diemController.text = _diemCaoNhat.toString();
    });
  }

  // Lưu settings vào SQLite
  Future<void> _saveSettings() async {
    final db = await database;

    await db.insert('settings', {
      'key': 'am_thanh',
      'value': _amThanh ? '1' : '0',
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('settings', {
      'key': 'tu_dong_luu',
      'value': _tuDongLuu ? '1' : '0',
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('settings', {
      'key': 'diem_cao_nhat',
      'value': _diemCaoNhat.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('settings', {
      'key': 'volume',
      'value': _volume.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã lưu cấu hình thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình game đồ vui'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: const Text('Âm thanh'),
                trailing: Switch(
                  value: _amThanh,
                  onChanged: (value) => setState(() => _amThanh = value),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Điểm cao nhất', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _diemController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Nhập điểm cao nhất',
                      ),
                      onChanged: (value) {
                        _diemCaoNhat = int.tryParse(value) ?? 3500;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: ListTile(
                title: const Text('Tự động lưu game'),
                trailing: Switch(
                  value: _tuDongLuu,
                  onChanged: (value) => setState(() => _tuDongLuu = value),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Volume',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      label: '${(_volume * 100).round()}%',
                      onChanged: (value) => setState(() => _volume = value),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_volume * 100).round()}%',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSettings,
        icon: const Icon(Icons.save),
        label: const Text('Lưu cấu hình'),
      ),
    );
  }

  @override
  void dispose() {
    _diemController.dispose();
    super.dispose();
  }
}
