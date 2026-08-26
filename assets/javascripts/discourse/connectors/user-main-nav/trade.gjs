import { LinkTo } from "@ember/routing";
import { i18n } from "discourse-i18n";

const TradeNavItem = <template>
  {{#unless @outletArgs.model.profile_hidden}}
    <li class="user-main-nav-outlet trade-reputation-nav-item">
      <LinkTo @route="user.trade">
        {{i18n "trade_reputation.trade.nav_label"}}
      </LinkTo>
    </li>
  {{/unless}}
</template>;

export default TradeNavItem;
