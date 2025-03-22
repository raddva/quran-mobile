import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quran_mobile/widgets/quote_dialog.dart';

class QuotesPage extends StatefulWidget {
  const QuotesPage({super.key});

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> {
  final List<Map<String, dynamic>> _quotes = [];
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isLoading = true;

  User? get _user => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    if (_user == null) return;

    setState(() => _isLoading = true);
    final snapshot = await _firestore
        .collection("admin")
        .doc(_user!.uid)
        .collection("quotes")
        .orderBy('created_at', descending: true)
        .get();

    setState(() {
      _quotes.clear();
      for (var doc in snapshot.docs) {
        _quotes.add({
          'id': doc.id,
          'quote': doc['quote'],
          'subtitle': doc['subtitle'],
          'created_at': doc['created_at'],
        });
      }
      _isLoading = false;
    });
  }

  Future<void> _addQuote(String quote, String subtitle) async {
    if (_user == null) return;

    final createdAt = DateTime.now().toIso8601String();
    final docRef = await _firestore
        .collection("admin")
        .doc(_user!.uid)
        .collection("quotes")
        .add({
      'quote': quote,
      'subtitle': subtitle,
      'created_at': createdAt,
    });

    setState(() {
      _quotes.insert(0, {
        'id': docRef.id,
        'quote': quote,
        'subtitle': subtitle,
        'created_at': createdAt,
      });
    });
  }

  Future<void> _editQuote(int index, String quote, String subtitle) async {
    if (_user == null) return;

    final quoteData = _quotes[index];
    final id = quoteData['id'];

    await _firestore
        .collection("admin")
        .doc(_user!.uid)
        .collection("quotes")
        .doc(id)
        .update({
      'quote': quote,
      'subtitle': subtitle,
    });

    setState(() {
      _quotes[index]['quote'] = quote;
      _quotes[index]['subtitle'] = subtitle;
    });
  }

  Future<void> _deleteQuote(int index) async {
    if (_user == null) return;

    final id = _quotes[index]['id'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Quote"),
        content: const Text("Are you sure you want to delete this quote?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore
          .collection("admin")
          .doc(_user!.uid)
          .collection("quotes")
          .doc(id)
          .delete();

      setState(() {
        _quotes.removeAt(index);
      });
    }
  }

  void _showAddModal() {
    showDialog(
      context: context,
      builder: (context) => QuoteDialog(onSubmit: _addQuote),
    );
  }

  void _showEditModal(int index) {
    final item = _quotes[index];
    showDialog(
      context: context,
      builder: (context) => QuoteDialog(
        initialQuote: item['quote'],
        initialSubtitle: item['subtitle'],
        onSubmit: (q, s) => _editQuote(index, q, s),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quotes',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddModal,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text("Add Quote"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: constraints.maxWidth),
                          child: PaginatedDataTable(
                            columns: const [
                              DataColumn(label: Text('Title')),
                              DataColumn(label: Text('Subtitle')),
                              DataColumn(label: Text('Created At')),
                              DataColumn(label: Text('Actions')),
                            ],
                            source: _QuotesDataSource(
                                _quotes, _showEditModal, _deleteQuote),
                            rowsPerPage: 10,
                            columnSpacing: 200,
                            dataRowHeight: 50,
                            headingRowColor:
                                MaterialStateProperty.all(Colors.green[100]),
                            showCheckboxColumn: false,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuotesDataSource extends DataTableSource {
  final List<Map<String, dynamic>> quotes;
  final void Function(int) onEdit;
  final void Function(int) onDelete;

  _QuotesDataSource(this.quotes, this.onEdit, this.onDelete);

  @override
  DataRow getRow(int index) {
    final quote = quotes[index];
    return DataRow(cells: [
      DataCell(Text(quote['quote'])),
      DataCell(Text(quote['subtitle'])),
      DataCell(Text(quote['created_at'].toString().split('T').first)),
      DataCell(Row(children: [
        IconButton(
            onPressed: () => onEdit(index),
            icon: const Icon(Icons.edit, color: Colors.blue)),
        IconButton(
            onPressed: () => onDelete(index),
            icon: const Icon(Icons.delete, color: Colors.red)),
      ])),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => quotes.length;
  @override
  int get selectedRowCount => 0;
}
