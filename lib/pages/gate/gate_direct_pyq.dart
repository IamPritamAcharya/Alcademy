import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'gate_pdf_viewer.dart';

class GateDirectPyqPage extends StatefulWidget {
  const GateDirectPyqPage({super.key});

  @override
  State<GateDirectPyqPage> createState() => _GateDirectPyqPageState();
}

class _GateDirectPyqPageState extends State<GateDirectPyqPage> {
  String _selectedYear = '';
  String _selectedBranchCode = '';
  List<String> _years = [];
  List<Map<String, String>> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final String response = await rootBundle.loadString('lib/assets/gate_source.json');
    final data = await json.decode(response);
    
    if (mounted) {
      setState(() {
        _years = List<String>.from(data['pyqYears']);
        _branches = (data['pyqBranches'] as List).map((b) => {
          'name': b['name'] as String,
          'code': b['code'] as String,
        }).toList();
        
        if (_years.isNotEmpty) _selectedYear = _years[0];
        if (_branches.isNotEmpty) _selectedBranchCode = _branches[0]['code']!;
        _isLoading = false;
      });
    }
  }

  void _downloadQuestionPaper() {
    // Template: https://gate2026.iitg.ac.in/doc/download/2025/CE12025.pdf
    final url = 'https://gate2026.iitg.ac.in/doc/download/$_selectedYear/$_selectedBranchCode$_selectedYear.pdf';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GatePdfViewer(
          url: url,
          title: '$_selectedBranchCode $_selectedYear Question Paper',
        ),
      ),
    );
  }

  void _downloadAnswerKey() {
    // Template: https://gate2026.iitg.ac.in/doc/download/2025_Key/CE_Keys.pdf
    final url = 'https://gate2026.iitg.ac.in/doc/download/${_selectedYear}_Key/${_selectedBranchCode}_Keys.pdf';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GatePdfViewer(
          url: url,
          title: '$_selectedBranchCode $_selectedYear Answer Key',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Direct PYQ Downloads',
          style: TextStyle(
            fontFamily: 'ProductSans',
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF3DFFC0))) : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Graphic
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Icon(Icons.picture_as_pdf_rounded, color: Colors.white.withOpacity(0.8), size: 36),
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Select Year',
              style: TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedYear,
              items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedYear = val);
              },
            ),

            const SizedBox(height: 24),
            
            const Text(
              'Select Subject',
              style: TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedBranchCode,
              items: _branches.map((b) => DropdownMenuItem(
                value: b['code'],
                child: Text('${b['name']} (${b['code']})'),
              )).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedBranchCode = val);
              },
            ),

            const SizedBox(height: 48),

            // Action Cards
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: 'Question\nPaper',
                    icon: Icons.description_rounded,
                    color: const Color(0xFF3DFFC0),
                    onTap: _downloadQuestionPaper,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionCard(
                    title: 'Answer\nKey',
                    icon: Icons.key_rounded,
                    color: const Color(0xFFB97AFF),
                    onTap: _downloadAnswerKey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Files are fetched directly from the official IIT Guwahati GATE servers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E1E1E),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.5)),
          style: const TextStyle(
            fontFamily: 'ProductSans',
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 80,
                color: color.withOpacity(0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
