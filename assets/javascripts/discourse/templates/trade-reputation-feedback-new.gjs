import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { concat } from "@ember/helper";
import RouteTemplate from "ember-route-template";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
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
      <h1>{{i18n "trade_reputation.feedback_new.title"}}</h1>

      {{#if (eq this.eligibilityState "invalid")}}
        <p class="trade-reputation-feedback-new__message">
          {{i18n "trade_reputation.feedback_new.invalid_transaction"}}
        </p>
      {{else if (eq this.eligibilityState "already_reviewed")}}
        <p class="trade-reputation-feedback-new__message">
          {{i18n "trade_reputation.feedback_new.already_submitted"}}
        </p>
      {{else if (eq this.eligibilityState "ineligible")}}
        <p class="trade-reputation-feedback-new__message">
          {{i18n "trade_reputation.feedback_new.ineligible"}}
        </p>
      {{else if (eq this.eligibilityState "unavailable")}}
        <p class="trade-reputation-feedback-new__message">
          {{i18n "trade_reputation.feedback_new.unavailable"}}
        </p>
      {{else if (eq this.phase "success")}}
        <p class="trade-reputation-feedback-new__message -success">
          {{i18n "trade_reputation.feedback_new.success"}}
        </p>
      {{else if (eq this.phase "duplicate")}}
        <p class="trade-reputation-feedback-new__message">
          {{i18n "trade_reputation.feedback_new.already_submitted"}}
        </p>
      {{else if (eq this.phase "generic_error")}}
        <p class="trade-reputation-feedback-new__message">
          {{i18n "trade_reputation.feedback_new.ineligible"}}
        </p>
      {{else if (eq this.phase "unavailable")}}
        <p class="trade-reputation-feedback-new__message">
          {{i18n "trade_reputation.feedback_new.unavailable"}}
        </p>
      {{else if this.showForm}}
        <Form
          @onSubmit={{this.handleSubmit}}
          class="trade-reputation-feedback-new__form"
          as |form data|
        >
          {{#if this.submissionError}}
            <form.Alert @type="error">{{this.submissionError}}</form.Alert>
          {{/if}}

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

          <form.Field
            @name="comment"
            @title={{i18n "trade_reputation.feedback_new.comment_label"}}
            @type="textarea"
            as |field|
          >
            <field.Control />
          </form.Field>

          <form.Submit
            @label="trade_reputation.feedback_new.submit"
            @disabled={{not data.rating}}
          />
        </Form>
      {{/if}}
    </div>
  </template>
}

export default RouteTemplate(TradeReputationFeedbackNew);
