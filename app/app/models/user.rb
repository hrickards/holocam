class User < ActiveRecord::Base
	validates :provider, presence: true
	validates :uid, presence: true, uniqueness: {scope: :provider}

	# Return an existing user if present, otherwise create a new one
	# Also adds the phone number if present
	def self.find_or_create_from_oauth_hash(auth)
		# Use uid and provider fields in OmniAuth hash
    user = find_or_create_by(uid: auth.uid, provider: auth.provider)

		# Update phone number if we have one now
		user.update! phone: auth.info.phone if user.phone.blank? and (auth.info.present? and auth.info.phone.present?)

		return user
	end
end
