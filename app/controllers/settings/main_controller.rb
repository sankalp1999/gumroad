# frozen_string_literal: true

class Settings::MainController < Sellers::BaseController
  include ActiveSupport::NumberHelper

  before_action :authorize

  def show
    @title = "Settings"
    @react_component_props = SettingsPresenter.new(pundit_user:).main_props
  end

  def update
    begin
      # Filter out parameters that aren't user attributes
      filtered_params = user_params.except(
        :seller_refund_policy, 
        :purchasing_power_parity_excluded_product_ids,
        :products,
        :products_with_custom_reply_to,
        :has_unconfirmed_email,
        :compliance_country,
        :tax_id
      )
      
      current_seller.with_lock { current_seller.update!(filtered_params) }
    rescue ActiveRecord::RecordInvalid => e
      return render json: { success: false, error_message: e.record.errors.full_messages.to_sentence }
    rescue StandardError => e
      Bugsnag.notify(e)
      return render json: { success: false, error_message: "Something broke. We're looking into what happened. Sorry about this!" }
    end

    if params[:user][:email] == current_seller.email
      current_seller.unconfirmed_email = nil
    end

    if current_seller.account_level_refund_policy_enabled?
      refund_policy_params = seller_refund_policy_params
      current_seller.refund_policy.update!(
        max_refund_period_in_days: refund_policy_params[:max_refund_period_in_days],
        fine_print: refund_policy_params[:fine_print]
      )
    end

    if current_seller.save
      current_seller.update_purchasing_power_parity_excluded_products!(params[:user][:purchasing_power_parity_excluded_product_ids])
      
      # Update product-specific reply-to emails
      if params[:product_reply_to_emails].present? || params[:product_reply_to_ids].present?
        begin
          update_product_reply_to_emails!
        rescue StandardError => e
          Bugsnag.notify(e)
          return render json: { success: false, error_message: "Failed to update product reply-to emails. Please try again." }
        end
      end

      render json: { success: true }
    else
      render json: { success: false, error_message: current_seller.errors.full_messages.to_sentence }
    end
  end

  def resend_confirmation_email
    if current_seller.unconfirmed_email.present? || !current_seller.confirmed?
      current_seller.send_confirmation_instructions
      return render json: { success: true }
    end
    render json: { success: false }
  end

  private
    def user_params
      permitted_params = [
        :email,
        :enable_payment_email,
        :enable_payment_push_notification,
        :enable_recurring_subscription_charge_email,
        :enable_recurring_subscription_charge_push_notification,
        :enable_free_downloads_email,
        :enable_free_downloads_push_notification,
        :announcement_notification_enabled,
        :disable_comments_email,
        :disable_reviews_email,
        :support_email,
        :reply_to_email,
        :locale,
        :timezone,
        :currency_type,
        :purchasing_power_parity_enabled,
        :purchasing_power_parity_limit,
        :purchasing_power_parity_payment_verification_disabled,
        :show_nsfw_products,
        :has_unconfirmed_email,
        :compliance_country,
        :tax_id,
        { purchasing_power_parity_excluded_product_ids: [] },
        { products: [:id, :name] },
        { products_with_custom_reply_to: [] },
        { seller_refund_policy: [:enabled, :max_refund_period_in_days, :fine_print, :fine_print_enabled, { allowed_refund_periods_in_days: [:key, :value] }] }
      ]

      params.require(:user).permit(permitted_params)
    end

    def seller_refund_policy_params
      params[:user][:seller_refund_policy]&.permit(
        :enabled, 
        :max_refund_period_in_days, 
        :fine_print, 
        :fine_print_enabled,
        allowed_refund_periods_in_days: [:key, :value]
      )
    end

    def fetch_discover_sales(seller)
      PurchaseSearchService.search(
        seller:,
        price_greater_than: 0,
        recommended: true,
        state: "successful",
        exclude_bundle_product_purchases: true,
        aggs: { price_cents_total: { sum: { field: "price_cents" } } }
      ).aggregations["price_cents_total"]["value"]
    end

    def update_product_reply_to_emails!
      product_emails = params[:product_reply_to_emails]&.to_unsafe_h || {}
      selected_ids = params[:product_reply_to_ids] || []
      
      # Update all visible products
      current_seller.products.visible.each do |product|
        if selected_ids.include?(product.external_id)
          # Set or update reply-to email
          reply_to = product_emails[product.external_id]
          product.update!(reply_to_email: reply_to) if reply_to != product.reply_to_email
        elsif product.reply_to_email.present?
          # Clear reply-to email if product was deselected
          product.update!(reply_to_email: nil)
        end
      end
    end

    def authorize
      super([:settings, :main, current_seller])
    end
end
