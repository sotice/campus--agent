import 'models.dart';

/// Mock campus card data for demo
class MockCampusCardData {
  static final CampusCardInfo activeCard = CampusCardInfo(
    cardNumber: '****5678',
    holderName: '张三',
    department: '计算机科学学院',
    balance: 286.50,
    status: 'active',
    lastTransaction: DateTime(2026, 7, 7, 7, 45),
    dailySpent: 23.50,
    dailyLimit: 200.00,
  );

  static final List<CardTransaction> recentTransactions = [
    CardTransaction(
      id: 'TXN001',
      time: DateTime(2026, 7, 7, 7, 45),
      location: '第一食堂 早餐窗口',
      amount: 8.50,
      type: 'consume',
      balanceAfter: 286.50,
    ),
    CardTransaction(
      id: 'TXN002',
      time: DateTime(2026, 7, 6, 12, 15),
      location: '第二食堂 午餐窗口',
      amount: 15.00,
      type: 'consume',
      balanceAfter: 295.00,
    ),
    CardTransaction(
      id: 'TXN003',
      time: DateTime(2026, 7, 6, 18, 30),
      location: '第一食堂 晚餐窗口',
      amount: 12.00,
      type: 'consume',
      balanceAfter: 310.00,
    ),
    CardTransaction(
      id: 'TXN004',
      time: DateTime(2026, 7, 5, 9, 0),
      location: '校园超市',
      amount: 25.80,
      type: 'consume',
      balanceAfter: 322.00,
    ),
    CardTransaction(
      id: 'TXN005',
      time: DateTime(2026, 7, 4, 14, 20),
      location: '自助充值机',
      amount: 200.00,
      type: 'recharge',
      balanceAfter: 347.80,
    ),
    CardTransaction(
      id: 'TXN006',
      time: DateTime(2026, 7, 3, 12, 0),
      location: '图书馆 打印服务',
      amount: 5.00,
      type: 'consume',
      balanceAfter: 147.80,
    ),
    CardTransaction(
      id: 'TXN007',
      time: DateTime(2026, 7, 2, 7, 30),
      location: '第三食堂 早餐窗口',
      amount: 6.00,
      type: 'consume',
      balanceAfter: 152.80,
    ),
  ];

  static CampusCardInfo getCardStatus() => activeCard;

  static List<CardTransaction> getRecentTransactions({int limit = 10}) {
    return recentTransactions.take(limit).toList();
  }
}
