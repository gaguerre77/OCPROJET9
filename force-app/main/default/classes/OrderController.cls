public with sharing class OrderController {
  @AuraEnabled
  public static Decimal getSumOrdersOfAccount(Id accountId) {
    // Utilisation d'une requête agrégée pour calculer la somme côté base de données
    AggregateResult result = [
      SELECT SUM(TotalAmount) sumTotal
      FROM Order
      WHERE AccountId = :accountId AND Status = 'Activated'
    ];

    // Si aucune commande n'est trouvée, retourner 0
    return result.get('sumTotal') != null
      ? (Decimal) result.get('sumTotal')
      : 0;
  }
}
