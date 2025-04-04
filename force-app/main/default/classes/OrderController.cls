public with sharing class OrderController {
  @AuraEnabled(cacheable=true)
  public static Decimal getSumOrdersOfAccount(Id accountId) {
    // Calculer la somme des montants des commandes pour le compte donné
    List<Order> orders = [
      SELECT TotalAmount
      FROM Order
      WHERE AccountId = :accountId
    ];
    Decimal sum = 0;
    for (Order order : orders) {
      sum += order.TotalAmount;
    }
    return sum;
  }
}
