import 'dart:math';

enum OrderStatus {
  Reserved,
  Waiting,
  Opened,
  Saved,
  Ordered,
  BillRequested,
  StaffCalled,
  Timeout,
  Closed
}

enum SalesType {
  DineIn,
  Takeaway,
  Online,
  Delivery,
  Promotion,
  Service,
  CashIn,
  CashOut,
  TestTrainingSales
}

class OrderUpdateInput {
  String orderId;
  String storeId;
  SalesType salesType;
  OrderStatus status;
  bool isRefunded;
  DateTime createdAt;
  DateTime updatedAt;
  List<OrderDetailInput> orderDetails;
  List<PaymentInput> payments;

  OrderUpdateInput({
    required this.orderId,
    required this.storeId,
    required this.salesType,
    required this.status,
    required this.isRefunded,
    required this.createdAt,
    required this.updatedAt,
    required this.orderDetails,
    required this.payments,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'storeId': storeId,
        'salesType': salesType.name,
        'status': status.name,
        'isRefunded': isRefunded,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'orderDetails': orderDetails.map((e) => e.toJson()).toList(),
        'payments': payments.map((e) => e.toJson()).toList(),
      };
}

class OrderDetailInput {
  String companyId;
  String storeId;
  String orderId;
  String orderedBy;
  SalesType salesType;
  List<OrderItem> items;
  double amount;

  OrderDetailInput({
    required this.companyId,
    required this.storeId,
    required this.orderId,
    required this.orderedBy,
    required this.salesType,
    required this.items,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'companyId': companyId,
        'storeId': storeId,
        'orderId': orderId,
        'orderedBy': orderedBy,
        'salesType': salesType.name,
        'items': items.map((e) => e.toJson()).toList(),
        'amount': amount,
      };
}

class OrderItem {
  String itemId;
  String itemName;
  double qty;
  double price;

  OrderItem({
    required this.itemId,
    required this.itemName,
    required this.qty,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'itemName': itemName,
        'qty': qty,
        'price': price,
      };
}

class PaymentInput {
  String posId;
  String transactionStaffId;
  double total;

  PaymentInput({
    required this.posId,
    required this.transactionStaffId,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
        'posId': posId,
        'transactionStaffId': transactionStaffId,
        'total': total,
      };
}


OrderUpdateInput generateRandomOrder() {
  final rand = Random();

  String randomId() => 'ID-${rand.nextInt(99999)}';

  List<OrderItem> randomItems = List.generate(rand.nextInt(3) + 1, (index) {
    return OrderItem(
      itemId: randomId(),
      itemName: "Item ${rand.nextInt(100)}",
      qty: (rand.nextInt(5) + 1).toDouble(),
      price: (rand.nextInt(2000) / 100.0),
    );
  });

  double totalAmount = randomItems.fold(0.0, (sum, item) => sum + item.qty * item.price);

  return OrderUpdateInput(
    orderId: randomId(),
    storeId: "Store-123",
    salesType: SalesType.values[rand.nextInt(SalesType.values.length)],
    status: OrderStatus.values[rand.nextInt(OrderStatus.values.length)],
    isRefunded: rand.nextBool(),
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
    orderDetails: [
      OrderDetailInput(
        companyId: "Company-001",
        storeId: "Store-123",
        orderId: randomId(),
        orderedBy: "Staff-${rand.nextInt(10)}",
        salesType: SalesType.Takeaway,
        items: randomItems,
        amount: totalAmount,
      ),
    ],
    payments: [
      PaymentInput(
        posId: "POS-${rand.nextInt(5)}",
        transactionStaffId: "Staff-${rand.nextInt(10)}",
        total: totalAmount,
      ),
    ],
  );
}
