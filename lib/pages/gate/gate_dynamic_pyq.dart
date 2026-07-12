import 'package:flutter/material.dart';
import 'gate_pdf_viewer.dart';
import 'models/gate_model.dart';
import 'utils/gate_data_fetcher.dart';

class GateDynamicSelectionPage extends StatefulWidget {
  final GateResource resource;
  
  const GateDynamicSelectionPage({super.key, required this.resource});

  @override
  State<GateDynamicSelectionPage> createState() => _GateDynamicSelectionPageState();
}

class _GateDynamicSelectionPageState extends State<GateDynamicSelectionPage> {
  String _selectedYear = '';
  String _selectedBranchCode = '';
  List<String> _years = [];
  List<Map<String, String>> _branches = [];
  bool _isLoading = true;

  late bool _needsYear;
  late bool _needsBranch;

  @override
  void initState() {
    super.initState();
    _needsYear = widget.resource.url.contains('{year}') || (widget.resource.keyUrl?.contains('{year}') ?? false);
    _needsBranch = widget.resource.url.contains('{branch}') || (widget.resource.keyUrl?.contains('{branch}') ?? false);
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await fetchGateData();
    
    if (mounted) {
      setState(() {
        _years = List<String>.from(data['pyqYears'] ?? []);
        _branches = (data['pyqBranches'] as List? ?? []).map((b) => {
          'name': b['name'] as String,
          'code': b['code'] as String,
        }).toList();

        if (widget.resource.subjectCodes != null && widget.resource.subjectCodes!.isNotEmpty) {
          _branches = _branches.where((b) => widget.resource.subjectCodes!.contains(b['code'])).toList();
        }
        
        if (_years.isNotEmpty) _selectedYear = _years[0];
        if (_branches.isNotEmpty) _selectedBranchCode = _branches[0]['code']!;
        _isLoading = false;
      });
    }
  }

  void _openPaper() {
    _openUrl(widget.resource.url, title: '${widget.resource.title} - Question Paper');
  }

  void _openKey() {
    if (widget.resource.keyUrl != null) {
      _openUrl(widget.resource.keyUrl!, title: '${widget.resource.title} - Answer Key');
    }
  }

  void _openUrl(String template, {required String title}) {
    String finalUrl = template;
    if (_needsYear) {
      finalUrl = finalUrl.replaceAll('{year}', _selectedYear);
    }
    if (_needsBranch) {
      finalUrl = finalUrl.replaceAll('{branch}', _selectedBranchCode);
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GatePdfViewer(
          url: finalUrl,
          title: title,
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
        title: Text(
          widget.resource.title,
          style: const TextStyle(
            fontFamily: 'ProductSans',
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF3DFFC0))) 
        : SingleChildScrollView(
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
                child: Icon(widget.resource.icon, color: Colors.white.withOpacity(0.8), size: 36),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                widget.resource.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            if (_needsYear) ...[
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
            ],
            
            if (_needsBranch) ...[
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
            ],

            // Action Button
            if (widget.resource.keyUrl != null) ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _openPaper,
                        icon: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
                        label: const Text('Question Paper', style: TextStyle(fontFamily: 'ProductSans', fontWeight: FontWeight.w700, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3DFFC0).withOpacity(0.8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _openKey,
                        icon: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 20),
                        label: const Text('Answer Key', style: TextStyle(fontFamily: 'ProductSans', fontWeight: FontWeight.w700, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4DA8FF).withOpacity(0.8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _openPaper,
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  label: const Text(
                    'Download / Open',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DFFC0).withOpacity(0.8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
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
    if (items.isEmpty) return const SizedBox.shrink();
    if (!items.any((item) => item.value == value)) value = items.first.value!;

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
}
