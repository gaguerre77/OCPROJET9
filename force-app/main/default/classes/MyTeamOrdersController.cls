public without sharing class MyTeamOrdersController {
  // TODO - Corriger l'erreur ici, nous retournons le montant TOTAL de tous les "Orders"
  // mais nous souhaitons retourner le montant TOTAL des orders  aux status = 'Activated' du compte sur lequel le composant LWC se situe
  //non codé
  //@AuraEnabled
  //public static Decimal getSumOrdersByAccount() {
  //AggregateResult groupedResults = [SELECT SUM(TotalAmount) total FROM Order];
  //return (Decimal) groupedResults.get('total');
  //}
}
