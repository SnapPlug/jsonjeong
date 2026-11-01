class SubmissionsController < ApplicationController
  allow_unauthenticated_access
  around_action :switch_locale

  def new
    @submission = Submission.new(started_on: Date.current)
  end

  def create
    return redirect_to root_path if params[:website].present? # 봇 덫. 사람은 이 칸을 못 본다.

    @submission = Submission.new(submission_params.merge(locale: I18n.locale.to_s))
    if @submission.save
      redirect_to submission_path(@submission.token)
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @submission = Submission.find_by!(token: params[:token])
    @pool_size = Submission.pool.size
  end

  private

  def submission_params
    params.expect(submission: %i[name url email started_on ended_on hours cost_usd revenue_usd stuck quit_signal tools proof_url])
  end

  def switch_locale(&action)
    locale = params[:locale] == "en" ? :en : :ko
    @html_lang = locale.to_s
    I18n.with_locale(locale, &action)
  end

  def default_url_options
    { locale: I18n.locale == :en ? "en" : nil }
  end
end
