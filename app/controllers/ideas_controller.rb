class IdeasController < ApplicationController
  allow_unauthenticated_access
  around_action :switch_locale

  def index
    @ideas = Idea.all.group_by(&:batch)
    @totals = Idea.totals
  end

  def show
    @idea = Idea.find(params[:slug])
    raise ActiveRecord::RecordNotFound unless @idea.retro?
  end

  private

  def switch_locale(&action)
    locale = params[:locale] == "en" ? :en : :ko
    @html_lang = locale.to_s
    I18n.with_locale(locale, &action)
  end

  # 한국어 주소엔 접두사를 붙이지 않는다.
  def default_url_options
    { locale: I18n.locale == :en ? "en" : nil }
  end
end
