class CashierSession {
  const CashierSession({
    required this.cashierId,
    required this.partnerId,
    required this.category,
    required this.packageBalance,
    required this.isActive,
  });

  final String cashierId;
  final int partnerId;
  final String category;
  final String packageBalance;
  final bool isActive;
}
