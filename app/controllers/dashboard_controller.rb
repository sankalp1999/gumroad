# frozen_string_literal: true

class DashboardController < Sellers::BaseController
  include ActionView::Helpers::NumberHelper, CurrencyHelper
  skip_before_action :check_suspended
  before_action :check_payment_details, only: :index

  def index
    authorize :dashboard

    if current_seller.suspended_for_tos_violation?
      redirect_to products_url
    else
      presenter = CreatorHomePresenter.new(pundit_user)
      @creator_home_props = presenter.creator_home_props
    end
  end

  def download_tax_form
    authorize :dashboard

    year = Time.current.year - 1
    tax_form_download_url = current_seller.tax_form_1099_download_url(year:)
    return redirect_to tax_form_download_url, allow_other_host: true if tax_form_download_url.present?

    flash[:alert] = "A 1099 form for #{year} was not filed for your account."
    redirect_to dashboard_path
  end
end
