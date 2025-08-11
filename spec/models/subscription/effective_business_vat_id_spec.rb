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

    it "returns the most recent VAT ID when multiple VAT-only refunds exist" do
      user = create(:user)
      product = create(:product, user: user)
      subscription = create(:subscription, user:, link: product)
      original = create(:purchase, is_original_subscription_purchase: true, link: product, subscription: subscription)
      
      # Create first refund with old VAT ID
      create(:refund, purchase: original, link_id: product.id, seller_id: product.user_id, amount_cents: 0, gumroad_tax_cents: 100).tap do |r|
        r.business_vat_id = "FR123456789"
        r.save!
      end
      
      # Create second refund with updated VAT ID
      create(:refund, purchase: original, link_id: product.id, seller_id: product.user_id, amount_cents: 0, gumroad_tax_cents: 100).tap do |r|
        r.business_vat_id = "IE6388047V"
        r.save!
      end

      expect(subscription.effective_business_vat_id).to eq("IE6388047V")
    end

    it "is memoized to avoid multiple database queries" do
      user = create(:user)
      product = create(:product, user: user)
      subscription = create(:subscription, user:, link: product)
      original = create(:purchase, is_original_subscription_purchase: true, link: product, subscription: subscription)
      original.create_purchase_sales_tax_info!(business_vat_id: "FR123456789")
      
      # First call
      expect(subscription.effective_business_vat_id).to eq("FR123456789")
      
      # Modify the database directly (simulating another process changing it)
      original.purchase_sales_tax_info.update_column(:business_vat_id, "CHANGED123")
      
      # Second call should return memoized value, not the changed one
      expect(subscription.effective_business_vat_id).to eq("FR123456789")
    end
  end

  context "seller-responsible VAT scenarios" do
    it "still passes VAT ID even when seller is responsible for VAT collection" do
      user = create(:user)
      product = create(:product, user: user)
      subscription = create(:subscription, user:, link: product)
      original = create(:purchase, is_original_subscription_purchase: true, link: product, subscription: subscription, country: "Italy")
      
      # Add VAT ID via refund
      create(:refund, purchase: original, link_id: product.id, seller_id: product.user_id, amount_cents: 0, gumroad_tax_cents: 100).tap do |r|
        r.business_vat_id = "IT12345678901"
        r.save!
      end
      
      # Create seller-responsible tax rate
      create(:zip_tax_rate, country: "IT", zip_code: nil, state: nil, combined_rate: 0.22, is_seller_responsible: true)
      
      # The subscription should still have the VAT ID available
      expect(subscription.effective_business_vat_id).to eq("IT12345678901")
      
      # When building a purchase, it should include the VAT ID
      purchase = subscription.build_purchase
      expect(purchase.business_vat_id).to eq("IT12345678901")
      
      # Note: The actual tax calculation (whether to charge VAT or not) is handled by SalesTaxCalculator
      # This test just ensures the VAT ID is properly propagated regardless of seller responsibility
    end
  end
end
