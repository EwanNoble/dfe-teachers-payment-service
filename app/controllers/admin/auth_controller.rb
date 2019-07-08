module Admin
  class AuthController < ApplicationController
    before_action :update_last_seen_at, only: [:callback]

    def sign_in
    end

    def sign_out
      session.destroy
      redirect_to root_path, notice: "You've been signed out"
    end

    def callback
      session[:login] = auth_hash.fetch("info").to_h
      redirect_to admin_path
    end

    def failure
    end

    private

    def auth_hash
      request.env.fetch("omniauth.auth")
    end
  end
end
