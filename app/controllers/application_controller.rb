class ApplicationController < ActionController::Base
  TIMEOUT_LENGTH_IN_MINUTES = 30
  TIMEOUT_WARNING_LENGTH_IN_MINUTES = 2

  http_basic_authenticate_with(
    name: ENV["BASIC_AUTH_USERNAME"],
    password: ENV["BASIC_AUTH_PASSWORD"],
    if: -> { ENV.key?("BASIC_AUTH_USERNAME") },
  )

  helper_method :signed_in?, :govuk_verify_enabled?, :current_claim

  private

  def send_unstarted_claiments_to_the_start
    redirect_to root_url unless current_claim.present?
  end

  def signed_in?
    session.key?(:login)
  end

  def govuk_verify_enabled?
    ENV["GOVUK_VERIFY_ENABLED"]
  end

  def current_claim
    @current_claim ||= TslrClaim.find(session[:tslr_claim_id]) if session.key?(:tslr_claim_id)
  end

  def update_last_seen_at
    session[:last_seen_at] = Time.zone.now
  end

  def session_timed_out?
    session_present? && session[:last_seen_at] < TIMEOUT_LENGTH_IN_MINUTES.minutes.ago
  end

  def session_present?
    (session.key?(:tslr_claim_id) || session.key?(:login)) &&
      session.key?(:last_seen_at)
  end

  def end_expired_sessions
    if session_timed_out?
      clear_session
      redirect_to timeout_path
    end
  end

  def clear_session
    session.delete(:tslr_claim_id)
    session.delete(:login)
    session.delete(:last_seen_at)
    session.delete(:verify_request_id)
  end

  def timeout_path
    "/"
  end
end
