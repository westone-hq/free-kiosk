// lib/ui/customer/customer_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/models/models.dart';
import 'package:kiosk/providers/providers.dart';

import 'menu_detail_sheet.dart';

/// 메뉴 탭 + 그리드 (4.2)
class CustomerMenuScreen extends ConsumerWidget {
  const CustomerMenuScreen({
    super.key,
    required this.storeId,
    required this.tableNo,
  });

  final String storeId;
  final String tableNo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final menusAsync = ref.watch(menuItemsProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (categories) {
        return menusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (menus) {
            return _CustomerMenuBody(
              categories: categories,
              menus: menus,
              storeId: storeId,
              tableNo: tableNo,
              onTapMenu: (m) async {
                await showMenuDetailSheet(
                  context,
                  ref,
                  menu: m,
                  storeId: storeId,
                  tableNo: tableNo,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CustomerMenuBody extends ConsumerStatefulWidget {
  const _CustomerMenuBody({
    required this.categories,
    required this.menus,
    required this.storeId,
    required this.tableNo,
    required this.onTapMenu,
  });

  final List<Category> categories;
  final List<MenuItem> menus;
  final String storeId;
  final String tableNo;
  final void Function(MenuItem menu) onTapMenu;

  @override
  ConsumerState<_CustomerMenuBody> createState() => _CustomerMenuBodyState();
}

class _CustomerMenuBodyState extends ConsumerState<_CustomerMenuBody> {
  String? _tabCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _tabCategoryId = widget.categories.first.id;
    }
  }

  List<MenuItem> _visibleMenus() {
    final cid = _tabCategoryId;
    Iterable<MenuItem> it = widget.menus.where((m) => m.enabled);
    if (cid != null) {
      it = it.where((m) => m.categoryId == cid);
    }
    return it.toList();
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.categories;
    final visible = _visibleMenus();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (c, i) {
              final cat = cats[i];
              final selected = _tabCategoryId == cat.id;
              return ChoiceChip(
                label: Text(cat.name),
                selected: selected,
                onSelected: cat.enabled
                    ? (_) {
                        setState(() {
                          _tabCategoryId = cat.id;
                        });
                      }
                    : null,
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemCount: cats.length,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: visible.length,
            itemBuilder: (c, i) {
              final m = visible[i];
              final soldOut = m.soldOut;
              final card = Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: soldOut
                      ? null
                      : () {
                          widget.onTapMenu(m);
                        },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: m.imageFile == null || m.imageFile!.isEmpty
                            ? Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(Icons.image_not_supported),
                              )
                            : Image.asset(
                                'data/images_menu/${m.imageFile}',
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${m.price}원',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            if (soldOut)
                              Text(
                                '품절',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
              if (soldOut) {
                return Opacity(opacity: 0.45, child: IgnorePointer(child: card));
              }
              return card;
            },
          ),
        ),
      ],
    );
  }
}
