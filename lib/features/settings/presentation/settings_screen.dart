import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/theme.dart';
import '../../../core/currency.dart';
import '../../../core/storage_mode.dart';
import '../../../core/sync/sync_settings.dart';
import '../../auth/data/auth_repository.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final currency = ref.watch(currencyProvider);
    final storageMode = ref.watch(storageModeProvider);
    final packageInfo = ref.watch(_packageInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          const _SectionHeader('Apariencia'),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Moneda'),
            trailing: DropdownButton<AppCurrency>(
              value: currency,
              underline: const SizedBox.shrink(),
              items: AppCurrency.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (c) {
                if (c != null) {
                  ref.read(currencyProvider.notifier).setCurrency(c);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Tema'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 16),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).setThemeMode(s.first),
            ),
          ),
          const Divider(),
          const _SectionHeader('Datos'),
          ListTile(
            leading: Icon(
              storageMode == StorageMode.cloud
                  ? Icons.cloud_outlined
                  : Icons.phone_android,
            ),
            title: const Text('Almacenamiento'),
            subtitle: Text(
              storageMode == StorageMode.cloud
                  ? 'En la nube (Supabase) -- requiere cuenta'
                  : 'Solo en este telefono',
            ),
            trailing: SegmentedButton<StorageMode>(
              segments: const [
                ButtonSegment(
                  value: StorageMode.local,
                  icon: Icon(Icons.phone_android, size: 16),
                  label: Text('Local'),
                ),
                ButtonSegment(
                  value: StorageMode.cloud,
                  icon: Icon(Icons.cloud_outlined, size: 16),
                  label: Text('Nube'),
                ),
              ],
              selected: {storageMode},
              onSelectionChanged: (s) =>
                  ref.read(storageModeProvider.notifier).setMode(s.first),
            ),
          ),
          if (storageMode == StorageMode.cloud) const _AccountTile(),
          if (storageMode == StorageMode.cloud) const _SyncFrequencyTile(),
          const Divider(),
          const _SectionHeader('Acerca de'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: packageInfo.when(
              data: (info) =>
                  Text('${info.version} (build ${info.buildNumber})'),
              loading: () => const Text('Cargando...'),
              error: (_, _) => const Text('No disponible'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.person_outline),
      title: Text(user.email ?? 'Cuenta'),
      subtitle: const Text('Sesion activa'),
      trailing: TextButton(
        onPressed: () => ref.read(authRepositoryProvider).signOut(),
        child: const Text('Cerrar sesion'),
      ),
    );
  }
}

class _SyncFrequencyTile extends ConsumerWidget {
  const _SyncFrequencyTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequency = ref.watch(syncFrequencyProvider);
    return ListTile(
      leading: const Icon(Icons.sync_outlined),
      title: const Text('Frecuencia de sync'),
      subtitle: const Text(
        'Tus datos siempre se guardan primero en el telefono; esto define '
        'cada cuanto se suben a la nube.',
      ),
      trailing: DropdownButton<SyncFrequency>(
        value: frequency,
        underline: const SizedBox.shrink(),
        items: SyncFrequency.values
            .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
            .toList(),
        onChanged: (f) {
          if (f != null) {
            ref.read(syncFrequencyProvider.notifier).setFrequency(f);
          }
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
