public with sharing class OrderController {
  @AuraEnabled(cacheable=true)
  public static Decimal getSumOrdersOfAccount(Id accountId) {
    System.debug('📨 [Apex] Reçu accountId : ' + accountId);

    if (accountId == null) {
      throw new AuraHandledException('L\'ID du compte est requis.');
    }
    // comment2
    try {
      AggregateResult result = [
        SELECT SUM(TotalAmount) sumTotal
        FROM Order
        WHERE AccountId = :accountId AND Status = 'Activated'
      ];

      Decimal total = (Decimal) result.get('sumTotal');
      System.debug('📊 [Apex] Total des commandes activées : ' + total);

      return total != null ? total : 0;
    } catch (Exception e) {
      System.debug('🔥 [Apex] Erreur : ' + e.getMessage());
      throw new AuraHandledException(
        'Erreur lors de la récupération du chiffre d\'affaire : ' +
        e.getMessage()
      );
    }
  }
}
