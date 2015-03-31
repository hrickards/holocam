require 'rails_helper'
require_relative '../support/authentication_helpers'

RSpec.describe SessionsController, type: :controller do
  include AuthenticationHelpers
	
  describe "GET #new" do
		context "when user is logged in" do
			it "redirects to main page with alert" do
				sign_in
				get :new

				expect(response).to redirect_to '/'
				expect(flash[:alert]).to match(I18n.t('error.already_signed_in'))
				expect(controller.signed_in?).to eq(true)
				expect(controller.current_user).to eq(@user)
			end
		end

		context "when user is logged out" do
			it "renders the signin/up page" do
				get :new
				expect(response).to render_template(:new)
			end
		end
  end

  describe "GET #create_from_oauth" do
		let(:facebook_hash) { FactoryGirl.build :facebook_hash }
		context "when user is logged in" do
			it "redirects to main page with error" do
				sign_in
				request.env['omniauth.auth'] = facebook_hash
				get :create_from_oauth, provider: 'facebook'

				expect(response).to redirect_to '/'
				expect(flash[:alert]).to match(I18n.t('error.already_signed_in'))
				expect(controller.signed_in?).to eq(true)
				expect(controller.current_user).to eq(@user)
			end
		end

		context "when user is logged out" do
			context "when a valid OAuth hash is present" do
				it "logs user in and redirects to main page" do
					request.env['omniauth.auth'] = facebook_hash
					get :create_from_oauth, provider: 'facebook'

					expect(response).to redirect_to '/'
					expect(controller.signed_in?).to eq(true)
				end
			end

			context "when an invalid OAuth hash is present" do
				it "redirects to main page with error" do
					get :create_from_oauth, provider: 'facebook'

					expect(response).to redirect_to '/'
					expect(flash[:alert]).to match(I18n.t('error.oauth_error'))
					expect(controller.signed_in?).to eq(false)
				end
			end
		end
  end

  describe "POST #create_from_traditional" do
		let(:credentials) { FactoryGirl.attributes_for :traditional_user }

		context "when user is logged in" do
			it "redirects to main page with error" do
				sign_in
				post :create_from_traditional, {email: credentials[:uid], password: credentials[:password]}

				expect(response).to redirect_to '/'
				expect(flash[:alert]).to match(I18n.t('error.already_signed_in'))
				expect(controller.signed_in?).to eq(true)
				expect(controller.current_user).to eq(@user)
			end
		end

		context "when user is logged out" do
			context "when a valid username/password are present and user already exists" do
				it "logs user in and redirects to main page" do
					@user = User.create! credentials
					post :create_from_traditional, {email: credentials[:uid], password: credentials[:password]}

					expect(response).to redirect_to '/'
					expect(controller.signed_in?).to eq(true)
					expect(controller.current_user).to eq(@user)
				end
			end

			context "when a valid username/password are present and user doesn't already exist" do
				it "logs user in and redirects to main page" do
					@user = User.new credentials
					post :create_from_traditional, {email: credentials[:uid], password: credentials[:password]}

					expect(response).to redirect_to '/'
					expect(controller.signed_in?).to eq(true)
					expect(controller.current_user.uid).to eq(@user.uid)
					# Expect @user to already be created
					expect { User.authenticate_from_traditional(credentials[:email], credentials[:password]) }.to_not change(User, :count)
				end
			end

			context "when an invalid username/password are present" do
				it "redirects to main page with message" do
					@user = User.create! credentials
					post :create_from_traditional, {email: credentials[:uid], password: credentials[:password] + "a"}

					expect(response).to redirect_to '/'
					expect(flash[:alert]).to match(I18n.t('error.invalid_username_password'))
					expect(controller.signed_in?).to eq(false)
				end
			end
		end
  end

  describe "DELETE #destroy" do
		context "when user is logged in" do
			it "logs them out and redirects to main page" do
				sign_in
				delete :destroy

				expect(response).to redirect_to '/'
				expect(controller.signed_in?).to eq(false)
			end
		end

		context "when user is logged out" do
			it "redirects to main page with error" do
				delete :destroy

				expect(response).to redirect_to '/'
				expect(flash[:alert]).to match(I18n.t('error.already_signed_out'))
				expect(controller.signed_in?).to eq(false)
			end
		end
  end
end
