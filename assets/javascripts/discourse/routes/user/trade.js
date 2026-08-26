import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

const VALID_PAGE = /^[1-9]\d*$/;

export default class UserTradeRoute extends DiscourseRoute {
  templateName = "user/trade";

  queryParams = {
    page: { refreshModel: true },
  };

  model(params) {
    const user = this.modelFor("user");
    const page = VALID_PAGE.test(params.page) ? Number(params.page) : 1;

    return ajax(`/trade-reputation/users/${user.username}/trade.json`, {
      data: { page },
    });
  }

  titleToken() {
    return i18n("trade_reputation.trade.title");
  }
}
