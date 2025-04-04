import { LightningElement, api, wire } from "lwc";
import getSumOrdersOfAccount from "@salesforce/apex/OrderController.getSumOrdersOfAccount";

export default class Orders extends LightningElement {
  sumOrdersOfCurrentAccount;
  @api recordId;

  @wire(getSumOrdersOfAccount, { accountId: "$recordId" })
  wiredSumOrders({ error, data }) {
    if (data) {
      this.sumOrdersOfCurrentAccount = data;
    } else if (error) {
      console.error("Error fetching sum of orders:", error);
    }
  }
}
