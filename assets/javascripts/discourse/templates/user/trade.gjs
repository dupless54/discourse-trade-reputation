import Component from "@glimmer/component";
import { hash } from "@ember/helper";
import { LinkTo } from "@ember/routing";
import RouteTemplate from "ember-route-template";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import { i18n } from "discourse-i18n";

const SUMMARY_WINDOW_KEYS = [
  "all_time",
  "last_30_days",
  "last_6_months",
  "last_1_year",
];

class UserTrade extends Component {
  get summary() {
    return this.args.model.summary;
  }

  get meta() {
    return this.args.model.meta;
  }

  get summaryWindows() {
    return SUMMARY_WINDOW_KEYS.map((key) => {
      const data = this.summary[key];
      const positivePercentage = data.positive_percentage;

      return {
        key,
        labelKey: `trade_reputation.trade.summary.windows.${key}`,
        data,
        hasPositivePercentage:
          positivePercentage !== null && positivePercentage !== undefined,
      };
    });
  }

  get feedbacks() {
    return this.args.model.feedbacks.map((feedback) => ({
      ...feedback,
      ratingLabelKey: `trade_reputation.trade.summary.${feedback.rating}`,
    }));
  }

  get hasPrevious() {
    return this.meta.page > 1;
  }

  get hasNext() {
    return this.meta.page < this.meta.total_pages;
  }

  get hasPagination() {
    return this.hasPrevious || this.hasNext;
  }

  get previousPage() {
    return this.meta.page - 1;
  }

  get nextPage() {
    return this.meta.page + 1;
  }

  <template>
    <div class="trade-reputation-user-trade">
      <section class="trade-reputation-summary">
        {{#each this.summaryWindows as |bucket|}}
          <div class="trade-reputation-summary__window">
            <h3>{{i18n bucket.labelKey}}</h3>
            <dl>
              <dt>{{i18n "trade_reputation.trade.summary.total"}}</dt>
              <dd>{{bucket.data.total}}</dd>

              <dt>{{i18n "trade_reputation.trade.summary.positive"}}</dt>
              <dd>{{bucket.data.positive}}</dd>

              <dt>{{i18n "trade_reputation.trade.summary.neutral"}}</dt>
              <dd>{{bucket.data.neutral}}</dd>

              <dt>{{i18n "trade_reputation.trade.summary.negative"}}</dt>
              <dd>{{bucket.data.negative}}</dd>

              <dt>{{i18n "trade_reputation.trade.summary.positive_percentage"}}</dt>
              <dd>
                {{#if bucket.hasPositivePercentage}}
                  {{bucket.data.positive_percentage}}%
                {{else}}
                  {{i18n "trade_reputation.trade.summary.no_data"}}
                {{/if}}
              </dd>
            </dl>
          </div>
        {{/each}}

        <div class="trade-reputation-summary__given">
          <span class="trade-reputation-summary__given-label">
            {{i18n "trade_reputation.trade.summary.given_total"}}
          </span>
          <span class="trade-reputation-summary__given-value">
            {{this.summary.given_total}}
          </span>
        </div>
      </section>

      <section class="trade-reputation-history">
        <h2>{{i18n "trade_reputation.trade.history.heading"}}</h2>

        {{#if this.feedbacks.length}}
          <ul class="trade-reputation-history__list">
            {{#each this.feedbacks as |feedback|}}
              <li class="trade-reputation-history__item">
                <div class="trade-reputation-history__reviewer">
                  {{#if feedback.reviewer}}
                    {{dAvatar feedback.reviewer imageSize="tiny"}}
                    <span class="trade-reputation-history__reviewer-username">
                      {{feedback.reviewer.username}}
                    </span>
                  {{else}}
                    <span class="trade-reputation-history__reviewer-username">
                      {{i18n "trade_reputation.trade.history.reviewer_fallback"}}
                    </span>
                  {{/if}}
                </div>

                <div
                  class={{dConcatClass
                    "trade-reputation-history__rating"
                    feedback.rating
                  }}
                >
                  {{i18n feedback.ratingLabelKey}}
                </div>

                <div class="trade-reputation-history__transaction">
                  {{i18n "trade_reputation.trade.history.transaction"}}:
                  {{feedback.transaction_reference}}
                </div>

                {{#if feedback.comment}}
                  <p class="trade-reputation-history__comment">
                    {{feedback.comment}}
                  </p>
                {{/if}}

                <div class="trade-reputation-history__date">
                  {{dFormatDate feedback.created_at format="medium"}}
                </div>

                <LinkTo
                  @route="tradeReputationFeedbackShow"
                  @model={{feedback.public_id}}
                  class="trade-reputation-history__details"
                >
                  {{i18n "trade_reputation.trade.history.details"}}
                </LinkTo>
              </li>
            {{/each}}
          </ul>

          {{#if this.hasPagination}}
            <nav class="trade-reputation-history__pagination">
              {{#if this.hasPrevious}}
                <LinkTo
                  @route="user.trade"
                  @query={{hash page=this.previousPage}}
                  class="trade-reputation-history__pagination-previous"
                >
                  {{i18n "trade_reputation.trade.pagination.previous"}}
                </LinkTo>
              {{/if}}

              {{#if this.hasNext}}
                <LinkTo
                  @route="user.trade"
                  @query={{hash page=this.nextPage}}
                  class="trade-reputation-history__pagination-next"
                >
                  {{i18n "trade_reputation.trade.pagination.next"}}
                </LinkTo>
              {{/if}}
            </nav>
          {{/if}}
        {{else}}
          <p class="trade-reputation-history__empty">
            {{i18n "trade_reputation.trade.history.empty"}}
          </p>
        {{/if}}
      </section>
    </div>
  </template>
}

export default RouteTemplate(UserTrade);
