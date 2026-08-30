import { click, currentURL, visit } from "@ember/test-helpers";
import { test } from "qunit";
import pretender from "discourse/tests/helpers/create-pretender";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const TRADE_PATH = "/trade-reputation/users/eviltrout/trade.json";

function buildWindow(total, positive, neutral, negative, positive_percentage) {
  return { total, positive, neutral, negative, positive_percentage };
}

function summaryFor() {
  return {
    all_time: buildWindow(12, 5, 4, 3, 41.67),
    last_30_days: buildWindow(3, 0, 3, 0, 0),
    last_6_months: buildWindow(0, 0, 0, 0, null),
    last_1_year: buildWindow(8, 4, 2, 2, 50),
    given_total: 6,
  };
}

const PAGE_1_FEEDBACKS = [
  {
    public_id: "11111111-1111-4111-8111-111111111111",
    transaction_reference: "TR-1",
    rating: "positive",
    comment: "<b>Great trade</b> & fast!",
    created_at: "2026-08-01T10:00:00Z",
    reviewer: { username: "alice", avatar_template: "/images/avatar.png" },
  },
  {
    public_id: "22222222-2222-4222-8222-222222222222",
    transaction_reference: "TR-2",
    rating: "neutral",
    comment: null,
    created_at: "2026-08-02T10:00:00Z",
    reviewer: { username: "bob", avatar_template: "/images/avatar.png" },
  },
  {
    public_id: "33333333-3333-4333-8333-333333333333",
    transaction_reference: "TR-3",
    rating: "negative",
    comment: "Late delivery",
    created_at: "2026-08-03T10:00:00Z",
    reviewer: null,
  },
];

const PAGE_2_FEEDBACKS = [
  {
    public_id: "44444444-4444-4444-8444-444444444444",
    transaction_reference: "TR-4",
    rating: "positive",
    comment: "ok",
    created_at: "2026-07-01T10:00:00Z",
    reviewer: { username: "carol", avatar_template: "/images/avatar.png" },
  },
];

function installPretender(needs) {
  needs.pretender((server, helper) => {
    server.get(TRADE_PATH, (request) => {
      const page = Number(request.queryParams.page || 1);
      const feedbacks = page === 2 ? PAGE_2_FEEDBACKS : PAGE_1_FEEDBACKS;

      return helper.response({
        summary: summaryFor(page),
        feedbacks,
        meta: { page, per_page: 30, total: 12, total_pages: 2 },
      });
    });
  });
}

acceptance("Trade Reputation | User trade profile", function (needs) {
  needs.user({ username: "eviltrout" });
  installPretender(needs);

  test("renders the reputation overview hero and supporting stats", async function (assert) {
    await visit("/u/eviltrout/trade");

    assert
      .dom(".trade-reputation-hero__percentage")
      .containsText("41.67", "the all-time positive percentage is shown");

    const stats = ".trade-reputation-hero__stats > div";
    assert.dom(`${stats}:nth-child(1) dd`).hasText("12", "total feedback");
    assert.dom(`${stats}:nth-child(2) dd`).hasText("5", "positive feedback");
    assert.dom(`${stats}:nth-child(3) dd`).hasText("4", "neutral feedback");
    assert.dom(`${stats}:nth-child(4) dd`).hasText("3", "negative feedback");
    assert.dom(`${stats}:nth-child(5) dd`).hasText("6", "feedback given");
  });

  test("a zero positive percentage renders as 0%, not a no-data state", async function (assert) {
    await visit("/u/eviltrout/trade");

    const card = ".trade-reputation-periods__grid > article:nth-child(1)";
    assert.dom(`${card} .trade-reputation-periods__percentage`).hasText("0%");
  });

  test("a null positive percentage renders the no-data state", async function (assert) {
    await visit("/u/eviltrout/trade");

    const card = ".trade-reputation-periods__grid > article:nth-child(2)";
    assert
      .dom(`${card} .trade-reputation-periods__percentage`)
      .containsText("No feedback yet");
  });

  test("renders positive, neutral, and negative rating badges", async function (assert) {
    await visit("/u/eviltrout/trade");

    const items = ".trade-reputation-history__item";
    assert
      .dom(`${items}:nth-child(1) .trade-reputation-history__rating.positive`)
      .containsText("Positive");
    assert
      .dom(`${items}:nth-child(2) .trade-reputation-history__rating.neutral`)
      .containsText("Neutral");
    assert
      .dom(`${items}:nth-child(3) .trade-reputation-history__rating.negative`)
      .containsText("Negative");
  });

  test("feedback comments render as escaped plain text", async function (assert) {
    await visit("/u/eviltrout/trade");

    const comment =
      ".trade-reputation-history__item:nth-child(1) .trade-reputation-history__comment";
    assert
      .dom(comment)
      .hasText("<b>Great trade</b> & fast!", "the raw text is shown verbatim");
    assert
      .dom(`${comment} b`)
      .doesNotExist("the comment is not cooked as HTML");
  });

  test("a deleted reviewer falls back to a placeholder label", async function (assert) {
    await visit("/u/eviltrout/trade");

    assert
      .dom(
        ".trade-reputation-history__item:nth-child(3) .trade-reputation-history__reviewer--fallback"
      )
      .containsText("Deleted user");
  });

  test("the detail link uses the feedback's public_id", async function (assert) {
    await visit("/u/eviltrout/trade");

    assert
      .dom(
        ".trade-reputation-history__item:nth-child(1) .trade-reputation-history__details"
      )
      .hasAttribute(
        "href",
        "/trade-reputation/feedback/11111111-1111-4111-8111-111111111111"
      );
  });

  test("pagination requests and navigates to the correct backend page", async function (assert) {
    await visit("/u/eviltrout/trade");

    assert
      .dom(".trade-reputation-history__pagination-previous")
      .doesNotExist("no previous link on the first page");
    assert
      .dom(".trade-reputation-history__pagination-next")
      .exists("a next link is shown");

    await click(".trade-reputation-history__pagination-next");

    assert.strictEqual(currentURL(), "/u/eviltrout/trade?page=2");

    const requests = pretender.handledRequests.filter(
      (request) => request.url.split("?")[0] === TRADE_PATH
    );
    assert.strictEqual(requests.length, 2, "a second request was made");
    assert.strictEqual(
      new URL(requests[1].url, window.location.origin).searchParams.get(
        "page"
      ),
      "2",
      "the request asked the backend for page 2"
    );

    assert
      .dom(".trade-reputation-history__item:nth-child(1) .trade-reputation-history__transaction")
      .containsText("TR-4", "the second page's feedback is rendered");
    assert
      .dom(".trade-reputation-history__pagination-previous")
      .exists("a previous link is shown on the second page");
    assert
      .dom(".trade-reputation-history__pagination-next")
      .doesNotExist("no next link on the last page");
  });
});

acceptance("Trade Reputation | User trade profile | empty history", function (
  needs
) {
  needs.user({ username: "eviltrout" });

  needs.pretender((server, helper) => {
    server.get(TRADE_PATH, () =>
      helper.response({
        summary: {
          all_time: buildWindow(0, 0, 0, 0, null),
          last_30_days: buildWindow(0, 0, 0, 0, null),
          last_6_months: buildWindow(0, 0, 0, 0, null),
          last_1_year: buildWindow(0, 0, 0, 0, null),
          given_total: 0,
        },
        feedbacks: [],
        meta: { page: 1, per_page: 30, total: 0, total_pages: 0 },
      })
    );
  });

  test("renders a polished empty state and preserves zero as a real value", async function (assert) {
    await visit("/u/eviltrout/trade");

    assert
      .dom(".trade-reputation-history__empty")
      .containsText("No feedback received yet.");
    assert
      .dom(".trade-reputation-history__pagination")
      .doesNotExist("no pagination controls when there is nothing to page");
    assert
      .dom(".trade-reputation-hero__stats > div:nth-child(1) dd")
      .hasText("0", "a legitimate zero total is shown, not blank");
    assert
      .dom(".trade-reputation-hero__stat.-given dd")
      .hasText("0", "feedback given renders 0 rather than being hidden");
  });
});
