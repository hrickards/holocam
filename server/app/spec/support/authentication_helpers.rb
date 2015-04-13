module AuthenticationHelpers
	# Sign in as a new user
	def sign_in
		@user = FactoryGirl.create :user
		session[:user_id] = @user.id
	end
end
