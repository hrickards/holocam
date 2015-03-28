FactoryGirl.define do
	sequence :email do |n|
		"test#{n}@email.com"
	end

  factory :user do
		provider "testprovider"
		uid SecureRandom.uuid
		phone Faker::PhoneNumber.cell_phone

		factory :traditional_user do
			provider "traditional"
			uid Faker::Internet.email
			password Faker::Internet.password
		end

		factory :testuser do
			provider "traditional"
			uid { generate(:email) }
			password Faker::Internet.password
		end
  end

	factory :facebook_hash, class: OmniAuth::AuthHash do
		provider "facebook"
		uid SecureRandom.uuid

		info do
			first_name = Faker::Name.first_name
			last_name = Faker::Name.last_name
			{
				name: "#{first_name} #{last_name}",
				first_name: first_name,
				last_name: last_name,
				phone: Faker::PhoneNumber.cell_phone
			}
		end

		credentials do
			{
        token: SecureRandom.uuid,
        expires_at: Faker::Date.forward(2),
        expires: true
			}
		end

		extra do
			{
				raw_info: {
					email: Faker::Internet.email,
					verified: true
				}
			}
		end
	end

	factory :twitter_hash, class: OmniAuth::AuthHash do
		provider "facebook"
		uid SecureRandom.uuid
		info {}
		extra {}
		credentials do
			{
        token: SecureRandom.uuid,
        expires_at: Faker::Date.forward(2),
        expires: true
			}
		end
	end
end
