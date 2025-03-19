import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  // Ensure Flutter framework is fully initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await DatabaseHelper.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'İnek Doğum Takip Sistemi',
      theme: ThemeData.dark(), // Always use dark theme
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [const Locale('tr', 'TR')],
      home: CowBirthTrackingSystem(),
    );
  }
}

class CowBirthTrackingSystem extends StatefulWidget {
  @override
  _CowBirthTrackingSystemState createState() => _CowBirthTrackingSystemState();
}

class _CowBirthTrackingSystemState extends State<CowBirthTrackingSystem> {
  List<Map<String, dynamic>> _cows = [];
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _inseminationDate;

  @override
  void initState() {
    super.initState();
    _loadCows();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadCows() {
    final cows = DatabaseHelper.getAllCows();
    setState(() {
      _cows = cows;
    });
  }

  void _showAddCowDialog({int? index, Map<String, dynamic>? cow}) {
    if (cow != null) {
      _nameController.text = cow['name'];
      _descriptionController.text = cow['description'];
      _inseminationDate = DateTime.parse(cow['inseminationDate']);
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext innerContext, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                // Added rounded corners
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: Text(
                cow == null ? 'Yeni İnek Ekle' : 'İnek Güncelle',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      // Added padding
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: _nameController,
                        style: TextStyle(fontSize: 18, color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'İnek Adı',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: _descriptionController,
                        style: TextStyle(fontSize: 18, color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Açıklama',
                          labelStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate: _inseminationDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                          locale: const Locale('tr', 'TR'),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _inseminationDate = pickedDate;
                          });
                        }
                      },
                      child: Text(
                        _inseminationDate == null
                            ? 'Tohumlanma Tarihini Seç'
                            : 'Seçilen Tarih: ${DateFormat('dd/MM/yyyy').format(_inseminationDate!)}',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'İptal',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  onPressed: () async {
                    if (_nameController.text.isNotEmpty &&
                        _inseminationDate != null) {
                      try {
                        final expectedCalvingDate = _inseminationDate!.add(
                          Duration(days: 283),
                        );
                        final newCow = {
                          'name': _nameController.text,
                          'description': _descriptionController.text,
                          'inseminationDate':
                              _inseminationDate!.toIso8601String(),
                          'expectedCalvingDate':
                              expectedCalvingDate.toIso8601String(),
                        };
                        if (index == null) {
                          await DatabaseHelper.insertCow(newCow);
                        } else {
                          await DatabaseHelper.updateCow(index, newCow);
                        }
                        _loadCows();
                        _nameController.clear();
                        _descriptionController.clear();
                        _inseminationDate = null;
                        Navigator.of(dialogContext).pop();
                      } catch (e) {
                        print('Error inserting/updating cow: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Veri eklenirken/güncellenirken hata oluştu: $e',
                            ),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lütfen tüm alanları doldurun')),
                      );
                    }
                  },
                  child: Text(
                    cow == null ? 'Kaydet' : 'Güncelle',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCowDetails(Map<String, dynamic> cow, int index) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            cow['name'],
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Açıklama: ${cow['description'] ?? 'Açıklama yok'}',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              SizedBox(height: 10),
              Text(
                'Tohumlanma Tarihi: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(cow['inseminationDate']))}',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              Text(
                'Tahmini Doğum Tarihi: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(cow['expectedCalvingDate']))}',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Kapat',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showAddCowDialog(index: index, cow: cow);
              },
              child: Text(
                'Güncelle',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseHelper.deleteCow(index);
                _loadCows();
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Sil',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort cows: ongoing pregnancies first (remainingDays > 0) sorted ascending, then finished ones.
    final sortedCows = List<Map<String, dynamic>>.from(_cows);
    sortedCows.sort((a, b) {
      final aExpected = DateTime.parse(a['expectedCalvingDate']);
      final bExpected = DateTime.parse(b['expectedCalvingDate']);
      final aRemaining = aExpected.difference(DateTime.now()).inDays;
      final bRemaining = bExpected.difference(DateTime.now()).inDays;
      if (aRemaining > 0 && bRemaining > 0) {
        return aRemaining.compareTo(bRemaining);
      } else if (aRemaining > 0 && bRemaining <= 0) {
        return -1;
      } else if (aRemaining <= 0 && bRemaining > 0) {
        return 1;
      } else {
        return aRemaining.compareTo(bRemaining);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('İnek Doğum Takip Sistemi'),
        centerTitle: true,
      ),
      body:
          sortedCows.isEmpty
              ? Center(
                child: Text(
                  'Henüz hiç inek eklenmedi',
                  style: TextStyle(fontSize: 18),
                ),
              )
              : ListView.builder(
                itemCount: sortedCows.length,
                itemBuilder: (context, index) {
                  final cow = sortedCows[index];
                  final expectedCalvingDate = DateTime.parse(
                    cow['expectedCalvingDate'],
                  );
                  final remainingDays =
                      expectedCalvingDate.difference(DateTime.now()).inDays;
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      title: Text(
                        cow['name'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ), // Enhanced title style
                      ),
                      subtitle: Text(
                        remainingDays > 0
                            ? 'Tahmini Doğum: ${DateFormat('dd/MM/yyyy').format(expectedCalvingDate)}\nKalan Gün: $remainingDays'
                            : 'Tahmini Doğum: ${DateFormat('dd/MM/yyyy').format(expectedCalvingDate)}\nGebelik Bitti',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[300],
                        ), // Enhanced subtitle style
                      ),
                      trailing: Icon(
                        remainingDays > 0
                            ? Icons.pregnant_woman_sharp
                            : Icons.cake,
                        color: remainingDays > 0 ? Colors.orange : Colors.green,
                        size: 32,
                      ),
                      onTap: () => _showCowDetails(cow, _cows.indexOf(cow)),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCowDialog(),
        child: Icon(Icons.add),
        tooltip: 'Yeni İnek Ekle',
      ),
    );
  }
}
