module Admin
  class BaseAdminController < ApplicationController
    before_action :ensure_authenticated_user, :end_expired_sessions, :update_last_seen_at

    private

    def ensure_authenticated_user
      redirect_to admin_sign_in_path unless signed_in?
    end

    def timeout_path
      admin_sign_in_path
    end
  end
end
