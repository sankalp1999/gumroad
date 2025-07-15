# frozen_string_literal: true

require "spec_helper"

describe Link, "reply_to_email" do
  let(:link) { create(:product) }

  describe "json_data accessor" do
    it "defaults to nil" do
      expect(link.reply_to_email).to be_nil
    end

    it "can be set and retrieved" do
      link.reply_to_email = "support@example.com"
      expect(link.reply_to_email).to eq("support@example.com")
    end

    it "persists after save" do
      link.reply_to_email = "custom@example.com"
      link.save!
      link.reload
      expect(link.reply_to_email).to eq("custom@example.com")
    end
  end

  describe "validations" do
    it "accepts valid email addresses" do
      link.reply_to_email = "valid@example.com"
      expect(link).to be_valid
    end

    it "accepts nil" do
      link.reply_to_email = nil
      expect(link).to be_valid
    end

    it "accepts empty string" do
      link.reply_to_email = ""
      expect(link).to be_valid
    end

    it "rejects invalid email addresses" do
      link.reply_to_email = "not-an-email"
      expect(link).not_to be_valid
      expect(link.errors[:reply_to_email]).to include("is invalid")
    end

    it "rejects email addresses with spaces" do
      link.reply_to_email = "has spaces@example.com"
      expect(link).not_to be_valid
      expect(link.errors[:reply_to_email]).to include("is invalid")
    end

    it "accepts email addresses with plus signs" do
      link.reply_to_email = "support+product@example.com"
      expect(link).to be_valid
    end

    it "accepts email addresses with dots" do
      link.reply_to_email = "first.last@example.com"
      expect(link).to be_valid
    end
  end
end