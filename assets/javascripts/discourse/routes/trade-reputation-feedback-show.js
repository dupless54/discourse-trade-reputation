import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class TradeReputationFeedbackShowRoute extends DiscourseRoute {
  model(params) {
    return ajax(`/trade-reputation/feedbacks/public/${params.public_id}.json`);
  }
}
