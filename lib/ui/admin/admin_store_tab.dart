// lib/ui/admin/admin_store_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/providers/providers.dart';
import 'package:kiosk/services/services.dart';

/// 3.3: store.json + menu_items.json 편집 → saveStoreConfig / saveMenuItems
class AdminStoreTab extends ConsumerStatefulWidget {
  const AdminStoreTab({super.key});

  @override
  ConsumerState<AdminStoreTab> createState() => _AdminStoreTabState();
}

class _AdminStoreTabState extends ConsumerState<AdminStoreTab> {
  bool _inited = false;
  Store? _store;
  int _storeFileVersion = 1;
  List<Category> _categories = [];
  String? _selectedCategoryId;
  List<MenuItem> _menus = [];
  int _menuFileVersion = 2;

  void _initDraft(StoreConfigData cfg, List<MenuItem> items) {
    if (_inited) {
      return;
    }
    _inited = true;
    _store = cfg.store;
    _storeFileVersion = cfg.fileVersion;
    _categories = List<Category>.from(cfg.categories);
    _menus = List<MenuItem>.from(items);
    _menuFileVersion = 2;
    if (_categories.isNotEmpty) {
      _selectedCategoryId = _categories.first.id;
    } else {
      _selectedCategoryId = null;
    }
  }

  Future<void> _saveToDisk() async {
    final storeId = ref.read(scopedStoreIdProvider);
    if (storeId == null || storeId.isEmpty) {
      return;
    }
    if (_store == null) {
      return;
    }
    await saveStoreConfig(
      StoreConfigData(
        fileVersion: _storeFileVersion,
        store: _store!,
        categories: _categories,
      ),
      storeId: storeId,
    );
    await saveMenuItems(_menus, fileVersion: _menuFileVersion, storeId: storeId);
    if (!mounted) {
      return;
    }
    // 편집 중인 draft(_menus)는 유지합니다. invalidate 직후 provider가
    // 아직 빈 캐시를 주면 _inited=false 재초기화 때문에 메뉴가 사라집니다.
    ref.invalidate(storeConfigProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(menuItemsProvider);
    ref.invalidate(filteredMenuItemsProvider);
    ref.invalidate(storeProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장했습니다.')),
      );
    }
  }

  Future<void> _editCategory(int index) async {
    final cat = _categories[index];
    final nameCtrl = TextEditingController(text: cat.name);
    final sortCtrl = TextEditingController(text: '${cat.sortOrder}');
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('카테고리 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: sortCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '정렬 순서'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('확인')),
        ],
      ),
    );
    if (ok != true || !mounted) {
      nameCtrl.dispose();
      sortCtrl.dispose();
      return;
    }
    final name = nameCtrl.text.trim();
    final sort = int.tryParse(sortCtrl.text.trim()) ?? cat.sortOrder;
    nameCtrl.dispose();
    sortCtrl.dispose();
    if (name.isEmpty) {
      return;
    }
    setState(() {
      _categories[index] = Category(
        id: cat.id,
        name: name,
        enabled: cat.enabled,
        sortOrder: sort,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(storeConfigProvider);
    final ms = ref.watch(menuItemsProvider);

    return st.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('store: $e')),
      data: (cfg) {
        return ms.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('menu: $e')),
          data: (items) {
            _initDraft(cfg, items);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      FilledButton(
                        onPressed: _saveToDisk,
                        child: const Text('디스크에 저장'),
                      ),
                      const SizedBox(width: 8),
                      Text('매장: ${_store?.name ?? ""} (id: ${_store?.id})'),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 220,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('카테고리', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _categories.length,
                                itemBuilder: (c, i) {
                                  final cat = _categories[i];
                                  final selected = _selectedCategoryId == cat.id;
                                  return ListTile(
                                    selected: selected,
                                    title: Text(cat.name),
                                    subtitle: Text('sort:${cat.sortOrder}'),
                                    onTap: () {
                                      setState(() {
                                        _selectedCategoryId = cat.id;
                                      });
                                    },
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          tooltip: '이름 수정',
                                          onPressed: () => _editCategory(i),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          tooltip: '삭제',
                                          onPressed: () {
                                            if (_menus.any((m) => m.categoryId == cat.id)) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('이 카테고리에 메뉴가 있으면 삭제할 수 없습니다.'),
                                                ),
                                              );
                                              return;
                                            }
                                            setState(() {
                                              _categories.removeAt(i);
                                              if (_selectedCategoryId == cat.id) {
                                                _selectedCategoryId =
                                                    _categories.isNotEmpty ? _categories.first.id : null;
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
                                setState(() {
                                  _categories.add(
                                    Category(
                                      id: id,
                                      name: '새 카테고리',
                                      enabled: true,
                                      sortOrder: _categories.length,
                                    ),
                                  );
                                  _selectedCategoryId = id;
                                });
                              },
                              child: const Text('카테고리 추가'),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _selectedCategoryId == null
                            ? const Center(child: Text('카테고리를 선택하세요.'))
                            : _MenuPane(
                                categoryId: _selectedCategoryId!,
                                items: _menus,
                                onChanged: (list) {
                                  setState(() {
                                    _menus = list;
                                  });
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MenuPane extends StatelessWidget {
  const _MenuPane({
    required this.categoryId,
    required this.items,
    required this.onChanged,
  });

  final String categoryId;
  final List<MenuItem> items;
  final void Function(List<MenuItem>) onChanged;

  @override
  Widget build(BuildContext context) {
    final rows = items.where((m) => m.categoryId == categoryId).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('메뉴', style: TextStyle(fontWeight: FontWeight.bold)),
              FilledButton.tonal(
                onPressed: () {
                  onChanged([
                    ...items,
                    MenuItem(
                      id: 'menu_${DateTime.now().millisecondsSinceEpoch}',
                      name: '새 메뉴',
                      price: 0,
                      imageFile: null,
                      categoryId: categoryId,
                      enabled: true,
                      soldOut: false,
                      sortOrder: rows.length,
                    ),
                  ]);
                },
                child: const Text('메뉴 추가'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (c, i) {
              final m = rows[i];
              final indexInAll = items.indexOf(m);
              return ListTile(
                title: Text(m.name),
                subtitle: Text('${m.price}원'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('품절'),
                    Switch(
                      value: m.soldOut,
                      onChanged: (v) {
                        final copy = List<MenuItem>.from(items);
                        final old = copy[indexInAll];
                        copy[indexInAll] = MenuItem(
                          id: old.id,
                          name: old.name,
                          price: old.price,
                          description: old.description,
                          imageFile: old.imageFile,
                          categoryId: old.categoryId,
                          enabled: old.enabled,
                          soldOut: v,
                          sortOrder: old.sortOrder,
                        );
                        onChanged(copy);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final nameCtrl = TextEditingController(text: m.name);
                        final priceCtrl = TextEditingController(text: '${m.price}');
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('메뉴 수정'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '이름')),
                                TextField(
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: '가격(원)'),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('확인')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          final p = int.tryParse(priceCtrl.text) ?? 0;
                          final copy = List<MenuItem>.from(items);
                          final old = copy[indexInAll];
                          copy[indexInAll] = MenuItem(
                            id: old.id,
                            name: nameCtrl.text,
                            price: p,
                            description: old.description,
                            imageFile: old.imageFile,
                            categoryId: old.categoryId,
                            enabled: old.enabled,
                            soldOut: old.soldOut,
                            sortOrder: old.sortOrder,
                          );
                          onChanged(copy);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
