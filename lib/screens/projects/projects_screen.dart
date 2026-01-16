import 'package:flutter/material.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final demoProjects = [
      {'name': 'Website Redesign', 'client': 'Acme Corp', 'status': 'active', 'progress': 0.7},
      {'name': 'Mobile App Development', 'client': 'Tech Startup', 'status': 'active', 'progress': 0.4},
      {'name': 'Brand Identity', 'client': 'New Venture', 'status': 'completed', 'progress': 1.0},
      {'name': 'Marketing Campaign', 'client': 'Big Client', 'status': 'on_hold', 'progress': 0.2},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: demoProjects.length,
        itemBuilder: (context, index) {
          final project = demoProjects[index];
          final statusColor = project['status'] == 'active'
              ? Colors.green
              : (project['status'] == 'completed' ? Colors.blue : Colors.orange);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (project['status'] as String).toUpperCase().replaceAll('_', ' '),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project['client'] as String,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: project['progress'] as double,
                            backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${((project['progress'] as double) * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Add project
        },
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }
}
