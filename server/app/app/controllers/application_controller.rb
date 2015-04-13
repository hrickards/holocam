class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

	# Queue helpers
	helper_method :queue_manager
	def queue_manager
		# Singleton QueueManager
		TimedQueue::QueueManager.instance
	end

	# Authentication helpers
	helper_method :signed_in?, :current_user

	def signed_in?
		session[:user_id].present?
	end

	def current_user
		@current_user ||= User.find(session[:user_id]) if session[:user_id]
	end
end
