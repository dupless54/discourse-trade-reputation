import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { concat } from "@ember/helper";
import RouteTemplate from "ember-route-template";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { eq, not } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

const RATING_VALUES = ["positive", "neutral", "negative"];

class TradeReputationFeedbackNew extends Component {
  ratingValues = RATING_VALUES;

  @tracked phase = "form";
  @tracked submissionError = null;

  get eligibilityState() {
    return this.args.model.state;
  }

  get showForm() {
    return this.eligibilityState === "eligible" && this.phase === "form";
  }

  get transactionReference() {
    return this.args.model.transactionId
      ? `TR-${this.args.model.transactionId}`
      : null;
  }

  @action
  async handleSubmit(data) {
    this.submissionError = null;

    try {
      await ajax("/trade-reputation/feedbacks.json", {
        type: "POST",
        data: {
          marketplace_transaction_id: this.args.model.transactionId,
          rating: data.rating,
          comment: data.comment,
        },
      });

      this.phase = "success";
    } catch (error) {
      const status = error?.jqXHR?.status;

      if (status === 409) {
        this.phase = "duplicate";
      } else if (status === 422) {
        this.phase = "generic_error";
      } else if (status === 503) {
        this.phase = "unavailable";
      } else {
        this.submissionError = i18n(
          "trade_reputation.feedback_new.retryable_error"
        );
      }
    }
  }

  <template>
    <div class="trade-reputation-feedback-new">
      <header class="trade-reputation-feedback-new__header">
        <div class="trade-reputation-feedback-new__header-icon" aria-hidden="true">
          {{dIcon "circle-check"}}
        </div>
        <div>
          <p class="trade-reputation-feedback-new__eyebrow">
            {{i18n "trade_reputation.feedback_new.eyebrow"}}
          </p>
          <h1>{{i18n "trade_reputation.feedback_new.title"}}</h1>
          <p class="trade-reputation-feedback-new__description">
            {{i18n "trade_reputation.feedback_new.description"}}
          </p>
        </div>
      </header>

      {{#if this.transactionReference}}
        <div class="trade-reputation-feedback-new__transaction">
          <span>
            {{i18n "trade_reputation.feedback_new.transaction_label"}}
          </span>
          <strong>{{this.transactionReference}}</strong>
          <span class="trade-reputation-feedback-new__verified">
            {{dIcon "circle-check"}}
            {{i18n "trade_reputation.feedback_new.verified_notice"}}
          </span>
        </div>
      {{/if}}

      <div class="trade-reputation-feedback-new__content" aria-live="polite">
        {{#if (eq this.eligibilityState "invalid")}}
          <div class="trade-reputation-feedback-new__message -warning">
            {{dIcon "circle-exclamation"}}
            <p>{{i18n "trade_reputation.feedback_new.invalid_transaction"}}</p>
          </div>
        {{else if (eq this.eligibilityState "already_reviewed")}}
          <div class="trade-reputation-feedback-new__message -neutral">
            {{dIcon "circle-minus"}}
            <p>{{i18n "trade_reputation.feedback_new.already_submitted"}}</p>
          </div>
        {{else if (eq this.eligibilityState "ineligible")}}
          <div class="trade-reputation-feedback-new__message -warning">
            {{dIcon "circle-exclamation"}}
            <p>{{i18n "trade_reputation.feedback_new.ineligible"}}</p>
          </div>
        {{else if (eq this.eligibilityState "unavailable")}}
          <div class="trade-reputation-feedback-new__message -warning">
            {{dIcon "circle-exclamation"}}
            <p>{{i18n "trade_reputation.feedback_new.unavailable"}}</p>
          </div>
        {{else if (eq this.phase "success")}}
          <div class="trade-reputation-feedback-new__message -success">
            {{dIcon "circle-check"}}
            <p>{{i18n "trade_reputation.feedback_new.success"}}</p>
          </div>
        {{else if (eq this.phase "duplicate")}}
          <div class="trade-reputation-feedback-new__message -neutral">
            {{dIcon "circle-minus"}}
            <p>{{i18n "trade_reputation.feedback_new.already_submitted"}}</p>
          </div>
        {{else if (eq this.phase "generic_error")}}
          <div class="trade-reputation-feedback-new__message -warning">
            {{dIcon "circle-exclamation"}}
            <p>{{i18n "trade_reputation.feedback_new.ineligible"}}</p>
          </div>
        {{else if (eq this.phase "unavailable")}}
          <div class="trade-reputation-feedback-new__message -warning">
            {{dIcon "circle-exclamation"}}
            <p>{{i18n "trade_reputation.feedback_new.unavailable"}}</p>
          </div>
        {{else if this.showForm}}
          <Form
            @onSubmit={{this.handleSubmit}}
            class="trade-reputation-feedback-new__form"
            as |form data|
          >
            {{#if this.submissionError}}
              <form.Alert @type="error">{{this.submissionError}}</form.Alert>
            {{/if}}

            <div class="trade-reputation-feedback-new__form-section">
              <div class="trade-reputation-feedback-new__form-heading">
                <h2>{{i18n "trade_reputation.feedback_new.rating_heading"}}</h2>
                <p>{{i18n "trade_reputation.feedback_new.rating_help"}}</p>
              </div>

              <form.Field
                @name="rating"
                @title={{i18n "trade_reputation.feedback_new.rating_label"}}
                @type="radio-group"
                @validation="required"
                as |field|
              >
                <field.Control as |radioGroup|>
                  {{#each this.ratingValues as |value|}}
                    <radioGroup.Radio @value={{value}}>
                      {{i18n
                        (concat "trade_reputation.feedback_new.ratings." value)
                      }}
                    </radioGroup.Radio>
                  {{/each}}
                </field.Control>
              </form.Field>
            </div>

            <div class="trade-reputation-feedback-new__form-section">
              <div class="trade-reputation-feedback-new__form-heading">
                <h2>{{i18n "trade_reputation.feedback_new.comment_heading"}}</h2>
                <p>{{i18n "trade_reputation.feedback_new.comment_help"}}</p>
              </div>

              <form.Field
                @name="comment"
                @title={{i18n "trade_reputation.feedback_new.comment_label"}}
                @type="textarea"
                as |field|
              >
                <field.Control />
              </form.Field>
            </div>

            <div class="trade-reputation-feedback-new__submit-row">
              <p>{{i18n "trade_reputation.feedback_new.submit_notice"}}</p>
              <form.Submit
                @label="trade_reputation.feedback_new.submit"
                @disabled={{not data.rating}}
              />
            </div>
          </Form>
        {{/if}}
      </div>
    </div>
  </template>
}

export default RouteTemplate(TradeReputationFeedbackNew);
