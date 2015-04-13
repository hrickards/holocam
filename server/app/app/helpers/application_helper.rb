module ApplicationHelper
  def oauth_signin_path(provider)
    "/auth/#{provider.to_s}"
  end

	def navbar_text(key)
		I18n.t "navbar.#{key}"
	end
end
