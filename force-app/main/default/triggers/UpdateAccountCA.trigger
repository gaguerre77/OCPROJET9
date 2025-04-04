trigger UpdateAccountCA on Order(after update) {
  Set<Id> accountIds = new Set<Id>();

  // Collecter les IDs de compte des commandes mises à jour
  for (Order newOrder : Trigger.new) {
    Order oldOrder = Trigger.oldMap.get(newOrder.Id);

    // Vérifier si le statut est passé de 'Draft' à 'Activated'
    if (
      oldOrder.Status == 'Draft' &&
      newOrder.Status == 'Activated' &&
      newOrder.AccountId != null
    ) {
      accountIds.add(newOrder.AccountId);
    }
  }

  // Si aucun compte à mettre à jour, quitter le déclencheur
  if (accountIds.isEmpty()) {
    return;
  }

  // Récupérer tous les comptes associés en une seule requête
  Map<Id, Account> accountsMap = new Map<Id, Account>(
    [
      SELECT Id, Chiffre_d_affaire__c
      FROM Account
      WHERE Id IN :accountIds
    ]
  );

  // Récupérer tous les orders activés pour les comptes concernés
  Map<Id, List<Order>> accountOrdersMap = new Map<Id, List<Order>>();
  for (Order order : [
    SELECT Id, AccountId, TotalAmount
    FROM Order
    WHERE AccountId IN :accountIds AND Status = 'Activated'
  ]) {
    if (!accountOrdersMap.containsKey(order.AccountId)) {
      accountOrdersMap.put(order.AccountId, new List<Order>());
    }
    accountOrdersMap.get(order.AccountId).add(order);
  }

  // Mettre à jour le champ Chiffre_d_affaire__c pour chaque compte
  for (Id accountId : accountOrdersMap.keySet()) {
    Account acc = accountsMap.get(accountId);
    if (acc != null) {
      // Calculer la somme des TotalAmount pour les orders activés
      Decimal sumTotalAmount = 0;
      for (Order order : accountOrdersMap.get(accountId)) {
        sumTotalAmount += order.TotalAmount;
      }
      acc.Chiffre_d_affaire__c = sumTotalAmount;
    }
  }

  // Mettre à jour tous les comptes en une seule opération DML
  update accountsMap.values();
}
