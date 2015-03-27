module ApplicationHelper
  def oauth_signin_path(provider)
    "/auth/#{provider.to_s}"
  end
end
