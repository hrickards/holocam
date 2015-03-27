require 'rails_helper'

RSpec.describe User, type: :model do
	context "with no phone number" do
		subject(:user) { FactoryGirl.build(:user, phone: nil) }
		it "saves correctly" do
			expect { user.save }.to change(User, :count).by(1)
		end
	end

	context "in oauth" do
		let(:facebook_hash) { FactoryGirl.build(:facebook_hash) }
		let(:twitter_hash) { FactoryGirl.build(:facebook_hash, provider: facebook_hash.uid) }
		let(:no_provider_hash) { FactoryGirl.build(:facebook_hash, provider: nil) }
		let(:no_uid_hash) { FactoryGirl.build(:facebook_hash, uid: nil) }
		let(:phone_hash) { FactoryGirl.build(:facebook_hash) }

		it "creates a new user" do
			expect { User.authenticate_from_oauth(facebook_hash) }.to change(User, :count).by(1)
		end

		it "finds an old user" do
			existing_user = User.authenticate_from_oauth(facebook_hash)
			expect(User.authenticate_from_oauth(facebook_hash)).to eq(existing_user)
		end

		it "doesn't allow duplicate users" do
			User.authenticate_from_oauth(facebook_hash)
			expect { User.authenticate_from_oauth(facebook_hash) }.to_not change(User, :count)
		end

		it "allowers users with the same uid across different providers" do
			User.authenticate_from_oauth(facebook_hash)
			expect { User.authenticate_from_oauth(twitter_hash) }.to change(User, :count).by(1)
		end

		it "rejects invalid hashes" do
			expect { User.authenticate_from_oauth(no_provider_hash) }.to raise_error
			expect { User.authenticate_from_oauth(no_uid_hash) }.to raise_error
		end

		it "extracts the phone number if present" do
			expect(User.authenticate_from_oauth(phone_hash).phone).to eq(phone_hash.info.phone)
		end

		it "should know it's type" do
			expect(User.authenticate_from_oauth(phone_hash).traditional?).to eq(false)
		end
	end

	context "in password mode" do
		let(:email) { Faker::Internet.email }
		let(:password) { Faker::Internet.password }

		it "creates a new user" do
			expect { User.authenticate_from_traditional(email, password) }.to change(User, :count).by(1)
		end

		it "requires a password" do
			expect { User.authenticate_from_traditional(email, "") }.to_not change(User, :count)
		end
		
		it "requires an email address" do
			expect { User.authenticate_from_traditional("", password) }.to_not change(User, :count)
		end

		it "finds an old user with the correct password" do
			new_user = User.authenticate_from_traditional(email, password)
			expect(User.authenticate_from_traditional(email, password)).to eql(new_user)
		end

		it "doesn't find an old user with the wrong password" do
			new_user = User.authenticate_from_traditional(email, password)
			expect(User.authenticate_from_traditional(email, password + "a")).to eql(false)
		end

		it "doesn't allow duplicate users" do
			User.authenticate_from_traditional(email, password)
			expect { User.authenticate_from_traditional(email, password) }.to_not change(User, :count)
		end

		it "should know it's type" do
			expect(User.authenticate_from_traditional(email, password).traditional?).to eq(true)
		end
	end
end
