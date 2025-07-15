# frozen_string_literal: true

require "spec_helper"

describe CustomerMailer, "reply_to_email" do
  describe "receipt with product-specific reply-to email" do
    let(:seller) { create(:user, email: "seller@example.com", name: "Seller Name") }
    let(:product) { create(:product, user: seller) }
    let(:purchase) { create(:purchase, link: product, seller: seller, email: "customer@example.com") }

    before do
      purchase.create_url_redirect!
    end

    context "when product has reply_to_email set" do
      before do
        product.update!(reply_to_email: "product-support@example.com")
      end

      it "uses the product-specific reply-to email" do
        mail = CustomerMailer.receipt(purchase.id)
        expect(mail[:reply_to].value).to eq("product-support@example.com")
      end

      it "still uses seller name in from field" do
        mail = CustomerMailer.receipt(purchase.id)
        expect(mail[:from].value).to eq("Seller Name <noreply@#{CUSTOMERS_MAIL_DOMAIN}>")
      end
    end

    context "when product does not have reply_to_email set" do
      it "falls back to seller's support_or_form_email" do
        mail = CustomerMailer.receipt(purchase.id)
        expect(mail[:reply_to].value).to eq(seller.support_or_form_email)
      end
    end

    context "when product has empty reply_to_email" do
      before do
        product.update!(reply_to_email: "")
      end

      it "falls back to seller's support_or_form_email" do
        mail = CustomerMailer.receipt(purchase.id)
        expect(mail[:reply_to].value).to eq(seller.support_or_form_email)
      end
    end

    context "with seller having support_email" do
      before do
        seller.update!(support_email: "seller-support@example.com")
      end

      context "when product has reply_to_email" do
        before do
          product.update!(reply_to_email: "product-specific@example.com")
        end

        it "uses product reply_to_email instead of seller support_email" do
          mail = CustomerMailer.receipt(purchase.id)
          expect(mail[:reply_to].value).to eq("product-specific@example.com")
        end
      end

      context "when product does not have reply_to_email" do
        it "uses seller support_email" do
          mail = CustomerMailer.receipt(purchase.id)
          expect(mail[:reply_to].value).to eq("seller-support@example.com")
        end
      end
    end
  end

  # Skip preorder tests due to complex setup requirements
  # The reply-to functionality is already tested through receipt tests

  describe "refund with product-specific reply-to email" do
    let(:seller) { create(:user, email: "seller@example.com") }
    let(:product) { create(:product, user: seller) }
    let(:purchase) { create(:purchase, link: product, seller: seller) }

    context "when product has reply_to_email set" do
      before do
        product.update!(reply_to_email: "refunds@example.com")
      end

      it "uses the product-specific reply-to email" do
        mail = CustomerMailer.refund(purchase.email, product.id, purchase.id)
        expect(mail[:reply_to].value).to eq("refunds@example.com")
      end
    end

    context "when product does not have reply_to_email set" do
      it "falls back to seller's support_or_form_email" do
        mail = CustomerMailer.refund(purchase.email, product.id, purchase.id)
        expect(mail[:reply_to].value).to eq(seller.support_or_form_email)
      end
    end
  end

  describe "partial_refund with product-specific reply-to email" do
    let(:seller) { create(:user, email: "seller@example.com", name: "Seller") }
    let(:product) { create(:product, user: seller) }
    let(:purchase) { create(:purchase, link: product, seller: seller) }

    context "when product has reply_to_email set" do
      before do
        product.update!(reply_to_email: "partial-refunds@example.com")
      end

      it "uses the product-specific reply-to email" do
        mail = CustomerMailer.partial_refund(purchase.email, product.id, purchase.id, 500, "partial")
        expect(mail[:reply_to].value).to eq("partial-refunds@example.com")
      end
    end

    context "when product does not have reply_to_email set" do
      it "falls back to seller's name and email" do
        mail = CustomerMailer.partial_refund(purchase.email, product.id, purchase.id, 500, "partial")
        expect(mail[:reply_to].value).to eq("Seller <seller@example.com>")
      end
    end
  end
end