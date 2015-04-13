require "rails_helper"

feature "Main page" do
	# Sign in with traditional authentication
	def sign_in
		visit '/signup'
		within('#session') do
			fill_in I18n.t('label.email'), with: Faker::Internet.email
			fill_in I18n.t('label.password'), with: Faker::Internet.password
		end
		click_button I18n.t('button.sign_up')
	end
	# Sign out of any authentication
	def sign_out
		click_link I18n.t('link.sign_out')
	end

	# Check the relevant links are present when we sign in/out of the homepage
	scenario "Signing in" do
		visit '/'
		expect(page).to have_link I18n.t('link.sign_in')
		expect(page).to have_link I18n.t('link.sign_up')

		sign_in

		visit '/'
		expect(page).to have_link I18n.t('link.sign_out')

		sign_out

		visit '/'
		expect(page).to have_link I18n.t('link.sign_in')
		expect(page).to have_link I18n.t('link.sign_up')
	end

	scenario 'Navigation' do
		visit '/'
		expect(page).to have_link I18n.t('navbar.viewer')
		expect(page).to have_link I18n.t('navbar.about')

		click_link I18n.t('navbar.about')
		expect(page).to have_content I18n.t('about.title')
		expect(page).to have_link I18n.t('navbar.viewer')
		expect(page).to have_link I18n.t('navbar.about')
	end
end
