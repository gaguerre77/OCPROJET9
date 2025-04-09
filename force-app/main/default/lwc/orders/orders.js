import { LightningElement, api, wire } from "lwc";
import getSumOrdersOfAccount from "@salesforce/apex/OrderController.getSumOrdersOfAccount";

export default class Orders extends LightningElement {
  sumOrdersOfCurrentAccount = 0;
  @api recordId;

  // Propriétés pour contrôler l'affichage conditionnel
  get isError() {
    return this.sumOrdersOfCurrentAccount <= 0;
  }

  get isSuccess() {
    return this.sumOrdersOfCurrentAccount > 0;
  }

  @wire(getSumOrdersOfAccount, { accountId: "$recordId" })
  wiredSumOrders({ error, data }) {
    if (data) {
      this.sumOrdersOfCurrentAccount = data;
    } else if (error) {
      console.error("Error fetching sum of orders:", error);
      this.sumOrdersOfCurrentAccount = 0; // Assurez-vous que la valeur est définie en cas d'erreur
    }
  }
}
