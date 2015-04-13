require "rails_helper"

feature "Traditional authentication" do
	background do
		@email = Faker::Internet.email
		@password = Faker::Internet.password

		@existing_email = Faker::Internet.email
		@existing_password = Faker::Internet.password
		User.authenticate_from_traditional @existing_email, @existing_password
	end

	scenario "Signing up and out with traditional authentication" do
		visit '/signup'
		within('#session') do
			fill_in I18n.t('label.email'), with: @email
			fill_in I18n.t('label.password'), with: @password
		end
		click_button I18n.t('button.sign_up')
		expect(page).to have_link I18n.t('link.sign_out')

		click_link I18n.t('link.sign_out')
		expect(page).to have_link I18n.t('link.sign_up')
	end

	scenario "Signing back in and out with traditional authentication" do
		visit '/signin'
		within('#session') do
			fill_in I18n.t('label.email'), with: @existing_email
			fill_in I18n.t('label.password'), with: @existing_password
		end
		click_button I18n.t('button.sign_in')
		expect(page).to have_link I18n.t('link.sign_out')

		click_link I18n.t('link.sign_out')
		expect(page).to have_link I18n.t('link.sign_in')
	end
end
