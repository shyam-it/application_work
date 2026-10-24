import 'package:flutter/material.dart';

import '../models/site.dart';
import '../services/site_service.dart';

class SiteManagementPage extends StatefulWidget {
  const SiteManagementPage({super.key});

  @override
  State<SiteManagementPage> createState() => _SiteManagementPageState();
}

class _SiteManagementPageState extends State<SiteManagementPage> {
  final TextEditingController _siteController = TextEditingController();

  final SiteService _siteService = SiteService();

  bool _isAdding = false;
  String? _errorMessage;

  Future<void> _addSite() async {
    final name = _siteController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter a site name.');
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
    });

    try {
      await _siteService.addSite(name);

      if (!mounted) return;

      _siteController.clear();
      _showMessage('Site added successfully.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
      });

      _showMessage('Could not add site. Check access and permissions.');
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _deactivateSite(Site site) async {
    try {
      await _siteService.deactivateSite(site.id);

      if (!mounted) return;

      _showMessage('${site.name} deactivated.');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Could not deactivate site. Check access and permissions.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _siteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFFA78BFA);

    return Scaffold(
      appBar: AppBar(title: const Text('Site Management')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage Work Sites',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Add and manage locations for attendance.',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _siteController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Enter site name',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _addSite(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAdding ? null : _addSite,
                  icon: _isAdding
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isAdding ? 'Adding...' : 'Add Site'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: const Color(0xFF111827),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Active Sites',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<Site>>(
                  stream: _siteService.watchActiveSites(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Could not load sites. Check Firestore access.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final sites = snapshot.data ?? [];

                    if (sites.isEmpty) {
                      return const Center(
                        child: Text(
                          'No active sites found. Add a site to get started.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: sites.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final site = sites[index];

                        return Card(
                          color: const Color(0xFF151D32),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF2E2450),
                              child: Icon(Icons.location_on, color: purple),
                            ),
                            title: Text(site.name),
                            trailing: IconButton(
                              tooltip: 'Deactivate site',
                              icon: const Icon(
                                Icons.block,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _deactivateSite(site),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
