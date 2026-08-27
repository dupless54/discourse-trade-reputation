import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const CTA_SELECTOR = ".trade-reputation-feedback-cta";
const FORM_SELECTOR = ".trade-reputation-feedback-new__form";

acceptance("Trade Reputation | Marketplace feedback CTA", function (needs) {
  needs.user();

  needs.pretender((server, helper) => {
    server.get("/marketplace/listings/:listing_id", (request) => {
      const id = Number(request.params.listing_id);
      return helper.response({
        listing: {
          id,
          title: `Listing ${id}`,
          cooked: "<p>Listing body</p>",
          price_cents: 1000,
          currency: "USD",
          status: id === 1 ? "sold" : "active",
          seller: { id: 99, username: "seller" },
        },
      });
    });

    server.get("/marketplace/listings/:listing_id/transaction", (request) => {
      const listingId = Number(request.params.listing_id);
      const completed = listingId === 1;
      return helper.response({
        transaction: {
          id: completed ? 42 : 43,
          listing_id: listingId,
          buyer_id: 1,
          seller_id: 99,
          status: completed ? "completed" : "pending",
          buyer_confirmed_at: completed ? "2026-08-27T08:00:00.000Z" : null,
          seller_confirmed_at: completed ? "2026-08-27T08:00:00.000Z" : null,
          completed_at: completed ? "2026-08-27T08:00:00.000Z" : null,
          cancelled_at: null,
          cancelled_by_id: null,
        },
      });
    });

    server.get(
      "/trade-reputation/feedbacks/:transaction_id/eligibility.json",
      (_request) => helper.response({ eligible: true })
    );
  });

  test("a completed Marketplace transaction exposes the feedback CTA and opens the form", async function (assert) {
    await visit("/marketplace/listings/1");

    assert.dom(CTA_SELECTOR).exists("completed transaction shows feedback CTA");
    assert
      .dom(CTA_SELECTOR)
      .hasAttribute(
        "href",
        "/trade-reputation/feedback/new?transaction_id=42",
        "CTA carries the completed Marketplace transaction id"
      );

    await click(CTA_SELECTOR);

    assert.dom(FORM_SELECTOR).exists("CTA opens the existing feedback form");
  });

  test("a pending Marketplace transaction does not expose the feedback CTA", async function (assert) {
    await visit("/marketplace/listings/2");

    assert.dom(CTA_SELECTOR).doesNotExist("pending transaction has no feedback CTA");
  });
});
