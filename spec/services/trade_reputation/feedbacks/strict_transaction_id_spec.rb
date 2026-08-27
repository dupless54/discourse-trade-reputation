# frozen_string_literal: true

describe TradeReputation::Feedbacks::Create do
  fab!(:buyer) { Fabricate(:user) }

  it "rejects a partially numeric transaction id before calling Marketplace" do
    expect(Marketplace::TradeContract).not_to receive(:completed_transaction_info)

    result =
      described_class.call(
        guardian: buyer.guardian,
        params: {
          marketplace_transaction_id: "1abc",
          rating: "positive",
          comment: nil,
        },
      )

    expect(result).to be_failure
  end

  it "passes a verified positive integer to Marketplace after strict parsing" do
    expect(Marketplace::TradeContract).to receive(:completed_transaction_info)
      .with(123)
      .and_return(nil)

    result =
      described_class.call(
        guardian: buyer.guardian,
        params: {
          marketplace_transaction_id: "123",
          rating: "positive",
          comment: nil,
        },
      )

    expect(result).to be_failure
    expect(result.feedback_ineligible).to eq(true)
  end
end
