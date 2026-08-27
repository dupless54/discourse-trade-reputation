export default function () {
  this.route("tradeReputationFeedbackNew", {
    path: "/trade-reputation/feedback/new",
  });
  this.route("tradeReputationFeedbackShow", {
    path: "/trade-reputation/feedback/:public_id",
  });
}
