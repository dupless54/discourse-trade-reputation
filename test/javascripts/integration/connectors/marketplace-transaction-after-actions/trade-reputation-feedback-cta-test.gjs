import { render, settled } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import TradeReputationFeedbackCta from "discourse/plugins/discourse-trade-reputation/discourse/connectors/marketplace-transaction-after-actions/trade-reputation-feedback-cta";

const CTA_SELECTOR = ".trade-reputation-feedback-cta";
const REVIEWED_SELECTOR = ".trade-reputation-feedback-cta--reviewed";

module(
  "Integration | Connector | Marketplace transaction feedback CTA",
  function (hooks) {
    setupRenderingTest(hooks);

    test("renders the active CTA for an eligible completed transaction", async function (assert) {
      pretender.get("/trade-reputation/feedbacks/42/eligibility.json", () =>
        response({ eligible: true })
      );

      this.outletArgs = {
        transaction: { id: 42, status: "completed" },
      };

      await render(
        <template>
          <TradeReputationFeedbackCta @outletArgs={{this.outletArgs}} />
        </template>
      );

      assert.dom(CTA_SELECTOR).exists("the CTA is shown");
      assert.dom(REVIEWED_SELECTOR).doesNotExist();
      assert
        .dom(CTA_SELECTOR)
        .hasAttribute(
          "href",
          "/trade-reputation/feedback/new?transaction_id=42",
          "CTA points to the existing feedback form"
        );
    });

    test("renders a disabled reviewed state when feedback was already submitted", async function (assert) {
      pretender.get("/trade-reputation/feedbacks/44/eligibility.json", () =>
        response({ eligible: false, already_reviewed: true })
      );

      this.outletArgs = {
        transaction: { id: 44, status: "completed" },
      };

      await render(
        <template>
          <TradeReputationFeedbackCta @outletArgs={{this.outletArgs}} />
        </template>
      );

      assert
        .dom(REVIEWED_SELECTOR)
        .hasText("Reviewed", "the disabled reviewed state is shown");
      assert
        .dom(`a${CTA_SELECTOR}`)
        .doesNotExist("the active feedback link is not shown");
    });

    test("renders nothing when the current user is not eligible and has not reviewed", async function (assert) {
      pretender.get("/trade-reputation/feedbacks/45/eligibility.json", () =>
        response({ eligible: false })
      );

      this.outletArgs = {
        transaction: { id: 45, status: "completed" },
      };

      await render(
        <template>
          <TradeReputationFeedbackCta @outletArgs={{this.outletArgs}} />
        </template>
      );

      assert.dom(CTA_SELECTOR).doesNotExist();
    });

    test("renders nothing when the eligibility request fails", async function (assert) {
      pretender.get("/trade-reputation/feedbacks/46/eligibility.json", () =>
        response(503, { error: "unavailable" })
      );

      this.outletArgs = {
        transaction: { id: 46, status: "completed" },
      };

      await render(
        <template>
          <TradeReputationFeedbackCta @outletArgs={{this.outletArgs}} />
        </template>
      );
      await settled();

      assert.dom(CTA_SELECTOR).doesNotExist();
    });

    test("does not render for a pending transaction and never calls eligibility", async function (assert) {
      this.outletArgs = {
        transaction: { id: 43, status: "pending" },
      };

      await render(
        <template>
          <TradeReputationFeedbackCta @outletArgs={{this.outletArgs}} />
        </template>
      );

      assert.dom(CTA_SELECTOR).doesNotExist();
      assert.strictEqual(
        pretender.handledRequests.filter((request) =>
          request.url.includes("/trade-reputation/feedbacks/43/eligibility")
        ).length,
        0,
        "shouldRender kept the connector from ever instantiating, so no request was made"
      );
    });
  }
);
