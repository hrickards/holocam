require 'rails_helper'
require_relative '../support/authentication_helpers'

RSpec.describe TimeslotsController, type: :controller do
  include AuthenticationHelpers

  describe "GET #index" do
		def get_index
			get :index
			@data = JSON.parse response.body
		end

		def populate_queue
			controller.queue_manager.add FactoryGirl.create(:testuser)
		end

		def add_current_user_to_queue
			controller.queue_manager.add controller.current_user
		end

		context "when user logged in" do
			context "when queue empty" do
				it "returns the correct information" do
					sign_in
					get_index

					expect(@data["queue_length"]).to eq(0)
					expect(@data["queue_empty"]).to eq(true)
					expect(@data["in_queue"]).to eq(false)
				end
			end

			context "when queue not empty" do
				context "when user at start of queue" do
					it "returns the correct information" do
						sign_in
						add_current_user_to_queue
						populate_queue
						get_index

						expect(@data["queue_length"]).to be > 0
						expect(@data["queue_empty"]).to eq(false)
						expect(@data["queue_eta"]).to be > 0
						expect(@data["in_queue"]).to eq(true)
						expect(@data["position"]).to eq(0)
						expect(@data["eta"]).to eq(0)
						expect(@data["current_user"]).to eq(true)
					end
				end


				context "when user in queue (not at start)" do
					it "returns the correct information" do
						sign_in
						populate_queue
						add_current_user_to_queue
						get_index

						expect(@data["queue_length"]).to be > 0
						expect(@data["queue_empty"]).to eq(false)
						expect(@data["queue_eta"]).to be > 0
						expect(@data["in_queue"]).to eq(true)
						expect(@data["position"]).to be > 0
						expect(@data["eta"]).to be > 0
						expect(@data["current_user"]).to eq(false)
					end
				end

				context "when user not in queue" do
					it "returns the correct information" do
						sign_in
						populate_queue
						get_index

						expect(@data["queue_length"]).to be > 0
						expect(@data["queue_empty"]).to eq(false)
						expect(@data["queue_eta"]).to be > 0
						expect(@data["in_queue"]).to eq(false)
						expect(@data["current_user"]).to eq(false)
					end
				end
			end
		end

		context "when user not logged in" do
			context "when queue empty" do
				it "returns the correct information" do
					get_index

					expect(@data["queue_length"]).to eq(0)
					expect(@data["queue_empty"]).to eq(true)
				end
			end

			context "when queue not empty" do
				it "returns the correct information" do
					populate_queue
					get_index

					expect(@data["queue_length"]).to be > 0
					expect(@data["queue_empty"]).to eq(false)
					expect(@data["queue_eta"]).to be > 0
				end
			end
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
				expect { post(:create) }.to change(controller.queue_manager, :queue_length).by(1)
			end
		end

		context "when user logged out" do
			it "redirects to main page with error" do
				post :create
				expect(response).to redirect_to '/'
				expect(flash[:alert]).to match(I18n.t('error.must_be_signed_in'))
			end

			it "doesn't add user to queue" do
				expect { post(:create) }.to_not change(controller.queue_manager, :queue_length)
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
					expect { delete(:destroy) }.to change(controller.queue_manager, :queue_length).by(-1)
				end
			end

			context "when user not in queue" do
				it "redirects to main page with error" do
					delete :destroy
					expect(response).to redirect_to '/'
					expect(flash[:alert]).to match(I18n.t('error.not_in_queue'))
				end

				it "doesn't change queue" do
					expect { delete(:destroy) }.to_not change(controller.queue_manager, :queue_length)
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
				expect { delete(:destroy) }.to_not change(controller.queue_manager, :queue_length)
			end
		end
	end
end
