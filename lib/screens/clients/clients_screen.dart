import 'package:flutter/material.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  bool _isLoading = true;
  final List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    // TODO: Load from Supabase
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  void _showAddClientDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddClientSheet(onSave: (client) {
        // TODO: Save to Supabase
        Navigator.pop(context);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Demo data
    final demoClients = List.generate(8, (index) => {
      'id': 'client-$index',
      'name': 'Client ${index + 1}',
      'email': 'client${index + 1}@example.com',
      'phone': '+1 555-000-${1000 + index}',
      'totalInvoices': (index + 1) * 3,
      'totalAmount': (index + 1) * 1500.0,
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadClients,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: demoClients.length,
                itemBuilder: (context, index) {
                  final client = demoClients[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          (client['name'] as String).substring(0, 1),
                          style: TextStyle(color: colorScheme.onPrimaryContainer),
                        ),
                      ),
                      title: Text(
                        client['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(client['email'] as String),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${client['totalInvoices']} invoices',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '\$${(client['totalAmount'] as double).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // TODO: Navigate to client detail
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClientDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Client'),
      ),
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Client',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSave({
                    'name': _nameController.text,
                    'email': _emailController.text,
                    'phone': _phoneController.text,
                    'address': _addressController.text,
                  });
                }
              },
              child: const Text('Save Client'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
