class User < ActiveRecord::Base
	validates :provider, presence: true
	validates :uid, presence: true, uniqueness: {scope: :provider}
	has_many :timeslots

	# Optional password authentication
	# In that case, provider is "traditional" and uid is email
	# Stored as password_hash, password_salt in database
	attr_accessor :password
	before_save :encrypt_password
	# The uid/provider uniqueness ensures uniqueness of email addresses
	
	# OAuth vs. traditional
	def traditional?
		provider == "traditional"
	end

	# Generate salt and encrypt password into password_hash
	def encrypt_password
		if traditional? and password.present?
			self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
		end
	end

	# Check password to an unhashed one
	def check_password(password)
		traditional? and password_hash == BCrypt::Engine.hash_secret(password, password_salt)
	end

	# Takes an OmniAuth hash
	# Return an existing user if present, otherwise create a new one
	# Also adds the phone number if present
	def self.authenticate_from_oauth(auth)
		return nil if auth.blank?

		# Use uid and provider fields in OmniAuth hash
    user = find_or_create_by(uid: auth.uid, provider: auth.provider)
		return nil unless user.valid?

		# Update phone number if we have one now
		user.update! phone: auth.info.phone if user.phone.blank? and (auth.info.present? and auth.info.phone.present?)

		return user
	end

	# Takes a traditional email address and password
	# If an existing user with those details exists, return them
	# If an existing user with that email address but a different password exists, return false
	# If no existing user exists, create one and return it
	def self.authenticate_from_traditional(email, password)
		user = find_by(provider: 'traditional', uid: email)
		if user and user.check_password(password)
			# User with correct details
			user
		elsif user
			# Incorrect password given
			nil
		else
			# No user exists yet
			# Validate presence of password and email
			return nil if email.blank? or password.blank?
			create! provider: 'traditional', uid: email, password: password
		end
	end
end
