import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../main.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  bool _isLoading = true;
  String _searchQuery = '';
  final List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  void _showAddClientSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AddClientSheet(onSave: (client) {
        Navigator.pop(context);
      }),
    );
  }

  // Demo data
  List<Map<String, dynamic>> get _demoClients => [
    {'id': '1', 'name': 'Acme Corporation', 'email': 'billing@acme.com', 'phone': '+1 555-0101', 'totalInvoices': 12, 'totalAmount': 45600.0, 'status': 'active'},
    {'id': '2', 'name': 'TechStart Inc', 'email': 'accounts@techstart.io', 'phone': '+1 555-0102', 'totalInvoices': 8, 'totalAmount': 28500.0, 'status': 'active'},
    {'id': '3', 'name': 'Design Studio Co', 'email': 'hello@designstudio.co', 'phone': '+1 555-0103', 'totalInvoices': 5, 'totalAmount': 15200.0, 'status': 'active'},
    {'id': '4', 'name': 'Global Media Group', 'email': 'finance@globalmedia.com', 'phone': '+1 555-0104', 'totalInvoices': 3, 'totalAmount': 9800.0, 'status': 'inactive'},
    {'id': '5', 'name': 'Startup Labs', 'email': 'team@startuplabs.io', 'phone': '+1 555-0105', 'totalInvoices': 15, 'totalAmount': 62300.0, 'status': 'active'},
    {'id': '6', 'name': 'Creative Agency', 'email': 'info@creativeagency.com', 'phone': '+1 555-0106', 'totalInvoices': 7, 'totalAmount': 21000.0, 'status': 'active'},
  ];

  List<Map<String, dynamic>> get _filteredClients {
    if (_searchQuery.isEmpty) return _demoClients;
    return _demoClients.where((c) => 
      (c['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (c['email'] as String).toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Clients', style: Theme.of(context).textTheme.headlineMedium),
                  Row(
                    children: [
                      _HeaderButton(icon: Icons.filter_list, onTap: () {}),
                      const SizedBox(width: 8),
                      _HeaderButton(icon: Icons.add, onTap: _showAddClientSheet, isPrimary: true),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search clients...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Client List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
                  : RefreshIndicator(
                      color: AppColors.blue,
                      backgroundColor: AppColors.cardBackground,
                      onRefresh: _loadClients,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredClients.length,
                        itemBuilder: (context, index) {
                          final client = _filteredClients[index];
                          return _ClientCard(client: client, currencyFormat: currencyFormat);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HeaderButton({required this.icon, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.blue : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Map<String, dynamic> client;
  final NumberFormat currencyFormat;

  const _ClientCard({required this.client, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final isActive = client['status'] == 'active';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      (client['name'] as String).substring(0, 1),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              client['name'] as String,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isActive ? AppColors.green : AppColors.textSecondary).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? AppColors.green : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(client['email'] as String, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _InfoChip(icon: Icons.receipt_long, label: '${client['totalInvoices']} invoices'),
                          const SizedBox(width: 12),
                          _InfoChip(icon: Icons.attach_money, label: currencyFormat.format(client['totalAmount'])),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _AddClientSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _AddClientSheet({required this.onSave});

  @override
  State<_AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<_AddClientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Client', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary)),
                IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            _buildField(_nameController, 'Client Name', Icons.business),
            const SizedBox(height: 12),
            _buildField(_emailController, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _buildField(_phoneController, 'Phone', Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildField(_addressController, 'Address', Icons.location_on_outlined, maxLines: 2),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSave({'name': _nameController.text, 'email': _emailController.text, 'phone': _phoneController.text, 'address': _addressController.text});
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Save Client', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue, width: 2)),
      ),
      validator: label == 'Client Name' ? (v) => v?.isEmpty ?? true ? 'Required' : null : null,
    );
  }
}
