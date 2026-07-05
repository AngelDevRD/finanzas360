import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/icon_map.dart';
import '../data/categories_repository.dart';
import 'category_form_sheet.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categorías'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Gastos'),
              Tab(text: 'Ingresos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CategoryList(type: 'expense'),
            _CategoryList(type: 'income'),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerStatefulWidget {
  const _CategoryList({required this.type});

  final String type;

  @override
  ConsumerState<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends ConsumerState<_CategoryList> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryFormSheet(context, type: widget.type),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar categoría...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              data: (all) => _buildList(context, all),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Category> all) {
    final items = all.where((c) => c.type == widget.type).toList();
    // Un grupo es una categoría que tiene subcategorías propias (ej. "Vivienda").
    // Una categoría "independiente" no tiene hijos ni padre (ej. todas las de
    // ingreso, o categorías de gasto creadas sin grupo): se trata como hoja.
    final hasChildrenIds = items
        .map((c) => c.parentId)
        .whereType<String>()
        .toSet();
    final groups = items
        .where((c) => c.parentId == null && hasChildrenIds.contains(c.id))
        .toList();
    final leaves = items
        .where((c) => c.parentId != null || !hasChildrenIds.contains(c.id))
        .toList();

    if (_query.isNotEmpty) {
      final matches = leaves
          .where((l) => l.name.toLowerCase().contains(_query.toLowerCase()))
          .toList();
      if (matches.isEmpty) {
        return Center(
          child: Text(
            'Sin resultados para "$_query"',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final leaf = matches[index];
          final group = groups.where((g) => g.id == leaf.parentId).firstOrNull;
          return _CategoryTile(
            category: leaf,
            subtitle: group?.name,
            onTap: leaf.isDefault
                ? null
                : () => showCategoryFormSheet(
                    context,
                    type: widget.type,
                    existing: leaf,
                  ),
            onDelete: leaf.isDefault
                ? null
                : () => ref.read(categoriesRepositoryProvider).delete(leaf.id),
          );
        },
      );
    }

    final standalone = leaves.where((l) => l.parentId == null).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final leaf in standalone)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CategoryTile(
              category: leaf,
              onTap: leaf.isDefault
                  ? null
                  : () => showCategoryFormSheet(
                      context,
                      type: widget.type,
                      existing: leaf,
                    ),
              onDelete: leaf.isDefault
                  ? null
                  : () =>
                        ref.read(categoriesRepositoryProvider).delete(leaf.id),
            ),
          ),
        for (final group in groups)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Color(group.color),
                child: Icon(
                  iconForKey(group.icon),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: Text(group.name),
              children: [
                for (final leaf in leaves.where((l) => l.parentId == group.id))
                  _CategoryTile(
                    category: leaf,
                    onTap: leaf.isDefault
                        ? null
                        : () => showCategoryFormSheet(
                            context,
                            type: widget.type,
                            existing: leaf,
                          ),
                    onDelete: leaf.isDefault
                        ? null
                        : () => ref
                              .read(categoriesRepositoryProvider)
                              .delete(leaf.id),
                  ),
                if (!group.isDefault)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Eliminar categoría'),
                    onTap: () =>
                        ref.read(categoriesRepositoryProvider).delete(group.id),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    this.subtitle,
    this.onTap,
    this.onDelete,
  });

  final Category category;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: subtitle != null
          ? const EdgeInsets.only(bottom: 8)
          : EdgeInsets.zero,
      child: ListTile(
        leading: Icon(iconForKey(category.icon), color: Color(category.color)),
        title: Text(category.name),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: onDelete == null
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
        onTap: onTap,
      ),
    );
  }
}
