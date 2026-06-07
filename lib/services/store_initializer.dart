// lib/services/store_initializer.dart
import 'package:kiosk/models/models.dart';

import 'catalog_loader.dart';
import 'order_book_service.dart';
import 'order_documents.dart';

/// 회원가입 직후 — 해당 storeId 전용 데이터 파일을 만듭니다.
Future<void> initializeNewStore({
  required String storeId,
  required String storeName,
  required String address,
}) async {
  await saveStoreConfig(
    StoreConfigData(
      fileVersion: 1,
      store: Store(
        id: storeId,
        name: storeName,
        address: address,
      ),
      categories: const [
        Category(
          id: 'cat_default',
          name: '기본',
          enabled: true,
          sortOrder: 0,
        ),
      ],
    ),
    storeId: storeId,
  );

  await saveMenuItems(const [], fileVersion: 2, storeId: storeId);

  await saveTables(
    const [
      TableInfo(tableNo: '1', label: '1번', gridX: 0, gridY: 0),
      TableInfo(tableNo: '2', label: '2번', gridX: 1, gridY: 0),
      TableInfo(tableNo: '3', label: '3번', gridX: 0, gridY: 1),
      TableInfo(tableNo: '4', label: '4번', gridX: 1, gridY: 1),
    ],
    fileVersion: 1,
    storeId: storeId,
  );

  final orders = OrderBookService(storeId: storeId);
  await orders.saveActiveOrders(
    const ActiveOrdersDocument(version: 1, orders: []),
  );
  await orders.saveArchive(
    const OrderArchiveDocument(version: 1, entries: []),
  );
}
