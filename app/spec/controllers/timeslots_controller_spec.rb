require 'rails_helper'
require_relative '../support/authentication_helpers'

RSpec.describe TimeslotsController, type: :controller do
  include AuthenticationHelpers

  describe "GET #index" do
		it "gets a valid 200 response" do
			expect(response.status).to eq(200)
		end
	end

  describe "POST #create" do
		context "when user logged in" do
			before(:each) { sign_in }
			it "redirects to main page with message" do
				post :create
				expect(response).to redirect_to '/'
				expect(flash[:notice]).to match(I18n.t('notice.added_to_queue'))
			end

			it "adds user to queue" do
				expect { post(:create) }.to change(Timeslot, :count).by(1)
			end
		end

		context "when user logged out" do
			it "redirects to main page with error" do
				post :create
				expect(response).to redirect_to '/'
				expect(flash[:alert]).to match(I18n.t('error.must_be_signed_in'))
			end

			it "doesn't add user to queue" do
				expect { post(:create) }.to_not change(Timeslot, :count)
			end
		end
	end

  describe "DELETE #destroy" do
		context "when user logged in" do
			before(:each) { sign_in }
			context "when user in queue" do
				before(:each) { post :create }

				it "redirects to main page with message" do
					delete :destroy
					expect(response).to redirect_to '/'
					expect(flash[:notice]).to match(I18n.t('notice.removed_from_queue'))
				end

				it "removes user from queue" do
					expect { delete(:destroy) }.to change(Timeslot, :count).by(-1)
				end
			end

			context "when user not in queue" do
				it "redirects to main page with error" do
					delete :destroy
					expect(response).to redirect_to '/'
					expect(flash[:alert]).to match(I18n.t('error.not_in_queue'))
				end

				it "doesn't change queue" do
					expect { delete(:destroy) }.to_not change(Timeslot, :count)
				end
			end
		end

		context "when user not logged in" do
			it "redirects to main page with error" do
				delete :destroy
				expect(response).to redirect_to '/'
				expect(flash[:alert]).to match(I18n.t('error.must_be_signed_in'))
			end

			it "doesn't change queue" do
				expect { delete(:destroy) }.to_not change(Timeslot, :count)
			end
		end
	end
end
