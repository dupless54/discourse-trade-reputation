import Component from "@glimmer/component";
import { hash } from "@ember/helper";
import { LinkTo } from "@ember/routing";
import { trustHTML } from "@ember/template";
import RouteTemplate from "ember-route-template";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

const ALL_TIME_KEY = "all_time";
const COMPARISON_WINDOW_KEYS = [
  "last_30_days",
  "last_6_months",
  "last_1_year",
];

const RATING_ICONS = {
  positive: "circle-check",
  neutral: "circle-minus",
  negative: "circle-exclamation",
};

class UserTrade extends Component {
  get summary() {
    return this.args.model.summary;
  }

  get meta() {
    return this.args.model.meta;
  }

  buildWindow(key) {
    const data = this.summary[key];
    const positivePercentage = data.positive_percentage;

    return {
      key,
      labelKey: `trade_reputation.trade.summary.windows.${key}`,
      data,
      hasPositivePercentage:
        positivePercentage !== null && positivePercentage !== undefined,
    };
  }

  get allTimeWindow() {
    return this.buildWindow(ALL_TIME_KEY);
  }

  get allTime() {
    return this.allTimeWindow.data;
  }

  get allTimeHasPercentage() {
    return this.allTimeWindow.hasPositivePercentage;
  }

  get comparisonWindows() {
    return COMPARISON_WINDOW_KEYS.map((key) => this.buildWindow(key));
  }

  get distributionShares() {
    const { positive, neutral, negative, total } = this.allTime;

    if (!total) {
      return { positive: 0, neutral: 0, negative: 0 };
    }

    return {
      positive: (positive / total) * 100,
      neutral: (neutral / total) * 100,
      negative: (negative / total) * 100,
    };
  }

  get positiveBarStyle() {
    return trustHTML(`width: ${this.distributionShares.positive}%`);
  }

  get neutralBarStyle() {
    return trustHTML(`width: ${this.distributionShares.neutral}%`);
  }

  get negativeBarStyle() {
    return trustHTML(`width: ${this.distributionShares.negative}%`);
  }

  get feedbacks() {
    return this.args.model.feedbacks.map((feedback) => ({
      ...feedback,
      ratingLabelKey: `trade_reputation.trade.summary.${feedback.rating}`,
      ratingIcon: RATING_ICONS[feedback.rating],
    }));
  }

  get hasFeedbackTotal() {
    return this.meta.total !== null && this.meta.total !== undefined;
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
      <section
        class="trade-reputation-hero"
        aria-labelledby="trade-reputation-hero-heading"
      >
        <div class="trade-reputation-hero__header">
          <div class="trade-reputation-hero__heading-group">
            <h2
              id="trade-reputation-hero-heading"
              class="trade-reputation-hero__heading"
            >
              {{i18n "trade_reputation.trade.summary.overview_heading"}}
            </h2>
            <p class="trade-reputation-hero__description">
              {{i18n "trade_reputation.trade.summary.description"}}
            </p>
          </div>

          <span class="trade-reputation-hero__verified">
            {{dIcon "circle-check"}}
            {{i18n "trade_reputation.trade.summary.verified_transactions"}}
          </span>
        </div>

        <div class="trade-reputation-hero__primary">
          <p class="trade-reputation-hero__percentage">
            {{#if this.allTimeHasPercentage}}
              {{this.allTime.positive_percentage}}<span
                class="trade-reputation-hero__percentage-sign"
              >%</span>
            {{else}}
              <span class="trade-reputation-hero__percentage-empty">
                {{i18n "trade_reputation.trade.summary.no_data"}}
              </span>
            {{/if}}
          </p>
          <p class="trade-reputation-hero__caption">
            {{i18n "trade_reputation.trade.summary.hero_label"}}
            <span class="trade-reputation-hero__caption-scope">
              · {{i18n "trade_reputation.trade.summary.windows.all_time"}}
            </span>
          </p>
        </div>

        <div class="trade-reputation-hero__distribution" aria-hidden="true">
          <span class="trade-reputation-hero__bar">
            <span
              class="trade-reputation-hero__bar-segment -positive"
              style={{this.positiveBarStyle}}
            ></span>
            <span
              class="trade-reputation-hero__bar-segment -neutral"
              style={{this.neutralBarStyle}}
            ></span>
            <span
              class="trade-reputation-hero__bar-segment -negative"
              style={{this.negativeBarStyle}}
            ></span>
          </span>
        </div>

        <div class="trade-reputation-hero__legend">
          <span class="trade-reputation-hero__legend-item -positive">
            <span class="trade-reputation-hero__legend-dot"></span>
            {{i18n "trade_reputation.trade.summary.positive"}}
            <strong>{{this.allTime.positive}}</strong>
          </span>
          <span class="trade-reputation-hero__legend-item -neutral">
            <span class="trade-reputation-hero__legend-dot"></span>
            {{i18n "trade_reputation.trade.summary.neutral"}}
            <strong>{{this.allTime.neutral}}</strong>
          </span>
          <span class="trade-reputation-hero__legend-item -negative">
            <span class="trade-reputation-hero__legend-dot"></span>
            {{i18n "trade_reputation.trade.summary.negative"}}
            <strong>{{this.allTime.negative}}</strong>
          </span>
        </div>

        <dl class="trade-reputation-hero__stats">
          <div class="trade-reputation-hero__stat">
            <dt>{{i18n "trade_reputation.trade.summary.total"}}</dt>
            <dd>{{this.allTime.total}}</dd>
          </div>
          <div class="trade-reputation-hero__stat -positive">
            <dt>
              {{dIcon "circle-check"}}
              {{i18n "trade_reputation.trade.summary.positive"}}
            </dt>
            <dd>{{this.allTime.positive}}</dd>
          </div>
          <div class="trade-reputation-hero__stat -neutral">
            <dt>
              {{dIcon "circle-minus"}}
              {{i18n "trade_reputation.trade.summary.neutral"}}
            </dt>
            <dd>{{this.allTime.neutral}}</dd>
          </div>
          <div class="trade-reputation-hero__stat -negative">
            <dt>
              {{dIcon "circle-exclamation"}}
              {{i18n "trade_reputation.trade.summary.negative"}}
            </dt>
            <dd>{{this.allTime.negative}}</dd>
          </div>
          <div class="trade-reputation-hero__stat -given">
            <dt>{{i18n "trade_reputation.trade.summary.given_total"}}</dt>
            <dd>{{this.summary.given_total}}</dd>
          </div>
        </dl>
      </section>

      <section
        class="trade-reputation-periods"
        aria-labelledby="trade-reputation-periods-heading"
      >
        <div class="trade-reputation-section-heading">
          <div>
            <h2 id="trade-reputation-periods-heading">
              {{i18n "trade_reputation.trade.summary.periods_heading"}}
            </h2>
            <p>{{i18n "trade_reputation.trade.summary.periods_description"}}</p>
          </div>
        </div>

        <div class="trade-reputation-periods__grid">
          {{#each this.comparisonWindows as |bucket|}}
            <article class="trade-reputation-periods__card">
              <h3 class="trade-reputation-periods__card-heading">
                {{i18n bucket.labelKey}}
              </h3>

              <p class="trade-reputation-periods__percentage">
                {{#if bucket.hasPositivePercentage}}
                  {{bucket.data.positive_percentage}}%
                {{else}}
                  {{i18n "trade_reputation.trade.summary.no_data"}}
                {{/if}}
              </p>

              <p class="trade-reputation-periods__percentage-label">
                {{i18n "trade_reputation.trade.summary.hero_label"}}
              </p>

              <dl class="trade-reputation-periods__breakdown">
                <div>
                  <dt>{{i18n "trade_reputation.trade.summary.total"}}</dt>
                  <dd>{{bucket.data.total}}</dd>
                </div>
                <div>
                  <dt>{{i18n "trade_reputation.trade.summary.positive"}}</dt>
                  <dd>{{bucket.data.positive}}</dd>
                </div>
                <div>
                  <dt>{{i18n "trade_reputation.trade.summary.neutral"}}</dt>
                  <dd>{{bucket.data.neutral}}</dd>
                </div>
                <div>
                  <dt>{{i18n "trade_reputation.trade.summary.negative"}}</dt>
                  <dd>{{bucket.data.negative}}</dd>
                </div>
              </dl>
            </article>
          {{/each}}
        </div>
      </section>

      <section
        class="trade-reputation-history"
        aria-labelledby="trade-reputation-history-heading"
      >
        <div class="trade-reputation-history__header">
          <div>
            <div class="trade-reputation-history__heading-line">
              <h2 id="trade-reputation-history-heading">
                {{i18n "trade_reputation.trade.history.heading"}}
              </h2>
              {{#if this.hasFeedbackTotal}}
                <span class="trade-reputation-history__count">
                  {{this.meta.total}}
                </span>
              {{/if}}
            </div>
            <p class="trade-reputation-history__description">
              {{i18n "trade_reputation.trade.history.description"}}
            </p>
          </div>
        </div>

        {{#if this.feedbacks.length}}
          <ul class="trade-reputation-history__list">
            {{#each this.feedbacks as |feedback|}}
              <li class="trade-reputation-history__item">
                <div class="trade-reputation-history__identity">
                  {{#if feedback.reviewer}}
                    {{dAvatar feedback.reviewer imageSize="tiny"}}
                    <span class="trade-reputation-history__reviewer">
                      {{feedback.reviewer.username}}
                    </span>
                  {{else}}
                    <span
                      class="trade-reputation-history__reviewer trade-reputation-history__reviewer--fallback"
                    >
                      {{dIcon "user"}}
                      {{i18n "trade_reputation.trade.history.reviewer_fallback"}}
                    </span>
                  {{/if}}
                </div>

                <div class="trade-reputation-history__body">
                  <div class="trade-reputation-history__top">
                    <span
                      class={{dConcatClass
                        "trade-reputation-history__rating"
                        feedback.rating
                      }}
                    >
                      {{dIcon feedback.ratingIcon}}
                      {{i18n feedback.ratingLabelKey}}
                    </span>

                    <span class="trade-reputation-history__date">
                      {{dFormatDate feedback.created_at format="medium"}}
                    </span>
                  </div>

                  {{#if feedback.comment}}
                    <p class="trade-reputation-history__comment">
                      {{feedback.comment}}
                    </p>
                  {{/if}}

                  <div class="trade-reputation-history__footer">
                    <span class="trade-reputation-history__transaction">
                      {{i18n "trade_reputation.trade.history.transaction"}}:
                      <strong>{{feedback.transaction_reference}}</strong>
                    </span>

                    <LinkTo
                      @route="tradeReputationFeedbackShow"
                      @model={{feedback.public_id}}
                      class="trade-reputation-history__details"
                    >
                      {{i18n "trade_reputation.trade.history.details"}}
                      {{dIcon "chevron-right"}}
                    </LinkTo>
                  </div>
                </div>
              </li>
            {{/each}}
          </ul>

          {{#if this.hasPagination}}
            <nav
              class="trade-reputation-history__pagination"
              aria-label={{i18n "trade_reputation.trade.pagination.nav_label"}}
            >
              <div class="trade-reputation-history__pagination-slot -previous">
                {{#if this.hasPrevious}}
                  <LinkTo
                    @route="user.trade"
                    @query={{hash page=this.previousPage}}
                    class="btn btn-default trade-reputation-history__pagination-previous"
                  >
                    {{dIcon "chevron-left"}}
                    {{i18n "trade_reputation.trade.pagination.previous"}}
                  </LinkTo>
                {{/if}}
              </div>

              <span class="trade-reputation-history__page-status">
                {{i18n
                  "trade_reputation.trade.pagination.page_status"
                  page=this.meta.page
                  total=this.meta.total_pages
                }}
              </span>

              <div class="trade-reputation-history__pagination-slot -next">
                {{#if this.hasNext}}
                  <LinkTo
                    @route="user.trade"
                    @query={{hash page=this.nextPage}}
                    class="btn btn-default trade-reputation-history__pagination-next"
                  >
                    {{i18n "trade_reputation.trade.pagination.next"}}
                    {{dIcon "chevron-right"}}
                  </LinkTo>
                {{/if}}
              </div>
            </nav>
          {{/if}}
        {{else}}
          <div class="trade-reputation-history__empty">
            <span class="trade-reputation-history__empty-icon">
              {{dIcon "inbox"}}
            </span>
            <div>
              <p class="trade-reputation-history__empty-title">
                {{i18n "trade_reputation.trade.history.empty"}}
              </p>
              <p class="trade-reputation-history__empty-description">
                {{i18n "trade_reputation.trade.history.empty_description"}}
              </p>
            </div>
          </div>
        {{/if}}
      </section>
    </div>
  </template>
}

export default RouteTemplate(UserTrade);
