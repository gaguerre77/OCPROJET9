import { LightningElement, api, wire } from "lwc";
import getSumOrdersOfAccount from "@salesforce/apex/OrderController.getSumOrdersOfAccount";

export default class Orders extends LightningElement {
  sumOrdersOfCurrentAccount = 0;
  @api recordId;

  get isError() {
    const result = this.sumOrdersOfCurrentAccount <= 0;
    console.log("🟥 isError →", result);
    return result;
  }

  get isSuccess() {
    const result = this.sumOrdersOfCurrentAccount > 0;
    console.log("🟩 isSuccess →", result);
    return result;
  }

  @wire(getSumOrdersOfAccount, { accountId: "$recordId" })
  wiredSumOrders({ error, data }) {
    console.log("📨 recordId reçu :", this.recordId);

    if (data) {
      this.sumOrdersOfCurrentAccount = data;
      console.log("✅ Donnée reçue depuis Apex :", data);
    } else if (error) {
      console.error("❌ Erreur lors de l'appel Apex :", error);
      this.sumOrdersOfCurrentAccount = 0;
    }
  }
}
