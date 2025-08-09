# frozen_string_literal: true

require "spec_helper"

describe Subscription do
  context "#effective_business_vat_id" do
    it "returns nil when no VAT ID exists on original purchase or refunds" do
      user = create(:user)
      product = create(:product, user: user)
      subscription = create(:subscription, user:, link: product)
      create(:purchase, is_original_subscription_purchase: true, link: product, subscription: subscription)

      expect(subscription.effective_business_vat_id).to be_nil
    end

    it "returns VAT ID from original purchase when present" do
      user = create(:user)
      product = create(:product, user: user)
      subscription = create(:subscription, user:, link: product)
      original = create(:purchase, is_original_subscription_purchase: true, link: product, subscription: subscription)
      original.create_purchase_sales_tax_info!(business_vat_id: "FR123456789")

      expect(subscription.effective_business_vat_id).to eq("FR123456789")
    end

    it "returns VAT ID from VAT-only refund when original purchase had none" do
      user = create(:user)
      product = create(:product, user: user)
      subscription = create(:subscription, user:, link: product)
      original = create(:purchase, is_original_subscription_purchase: true, link: product, subscription: subscription)
      create(:refund, purchase: original, link_id: product.id, seller_id: product.user_id, amount_cents: 0, gumroad_tax_cents: 100).tap do |r|
        r.business_vat_id = "IE6388047V"
        r.save!
      end

      expect(subscription.effective_business_vat_id).to eq("IE6388047V")
    end
  end
end
