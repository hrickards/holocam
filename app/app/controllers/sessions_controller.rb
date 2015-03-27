class SessionsController < ApplicationController
	# GET /signin
	# GET /signup
  def new
		if signed_in?
			redirect_to root_url, alert: I18n.t('error.already_logged_in')
		else
			render "new"
		end
  end

	# GET /sessions/:provider/callback
  def create_from_oauth
		return redirect_to(root_url, alert: I18n.t('error.already_logged_in')) if signed_in?

		user = User.authenticate_from_oauth request.env['omniauth.auth']
		if user.present?
			sign_in user
			redirect_to root_url, notice: I18n.t('notice.logged_in')
		else
			redirect_to root_url, alert: I18n.t('error.oauth_error')
		end
  end

	# POST /sessions
  def create_from_traditional
		return redirect_to(root_url, alert: I18n.t('error.already_logged_in')) if signed_in?

		user = User.authenticate_from_traditional params[:email], params[:password]
		if user.present?
			sign_in user
			redirect_to root_url, notice: I18n.t('notice.logged_in')
		else
			redirect_to root_url, alert: I18n.t('error.invalid_username_password')
		end
  end

	# DELETE /signout
  def destroy
		if signed_in?
			sign_out
			redirect_to root_url, notice: I18n.t('notice.logged_out')
		else
			redirect_to root_url, alert: I18n.t('error.already_logged_out')
		end
  end

	private
	def sign_in(user)
		session[:user_id] = user.id
	end

	def sign_out
		session[:user_id] = nil
	end

end
