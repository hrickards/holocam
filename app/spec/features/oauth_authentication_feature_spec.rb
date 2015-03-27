require "rails_helper"

# OAuth is mocked out in rails_helper

feature "OAuth authentication" do
	scenario "Signing in with Twitter" do
		visit "signin"
		within("#session") do
			click_link 'twitter'
		end
		expect(page).to have_content I18n.t('notice.signed_in')
	end

	scenario "Signing in with Facebook" do
		visit "signin"
		within("#session") do
			click_link 'facebook'
		end
		expect(page).to have_content I18n.t('notice.signed_in')
	end

	scenario "Signing in with Google" do
		visit "signin"
		within("#session") do
			click_link 'google'
		end
		expect(page).to have_content I18n.t('notice.signed_in')
	end
end
