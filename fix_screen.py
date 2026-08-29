import sys
import re

path = r'H:\FlutterProject\pintarlabs_license_platform\admin\lib\features\licenses\presentation\licenses_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

replacement = """                              if (l.status == 'ACTIVE')
                                IconButton(
                                  icon: const Icon(Icons.link_off, size: 20, color: Colors.blue),
                                  tooltip: 'Reset Device (Unbind)',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Confirm Unbind'),
                                        content: const Text('Hapus ikatan perangkat pada lisensi ini? Pelanggan harus melakukan aktivasi ulang.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Unbind')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      ref.read(licenseActionProvider.notifier).unbindLicense(l.id);
                                    }
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),"""

content = content.replace("                              IconButton(\n                                icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),", replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
