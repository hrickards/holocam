# Implementation of a FIFO queue storing users using redis
# Heavily tested in user_queue_spec
#
# The requirement that makes this more complicated than just a linked list is:
# we need to poll for a user's current position in the queue *much* more frequently
# than updating the queue.
#
# Base level is a linked list containing user IDs, however this alone is inefficient.
# We can push and pop from this list with O(1), however finding an element in the list
# is O(n^2) (O(m) just to access the element at position m).
#
# Instead, we use a hash to keep track of each user's position in the queue (user ID as
# key, and index in our linked list as value). We can access this hash, and hence find out
# the position of a user, with O(1). It then becomes the updating of the queue that is slow.
#
# Pushing is still quick: it's O(1) to push to the linked list, and O(1) to update the one
# relevant hash entry. Popping and removing are slower, though. The actual popping itself
# requires O(1), and the removing O(n). But then we have to decrement (a large part of) the
# hash, which requires O(n) (we can access the keys in O(n), and each decrement is O(1)).
#
# In summary, we can poll the position of a user in the queue in O(1), can push to the
# queue with O(1), but to pop or remove requires O(n).
module TimedQueue
	class UserQueue
		def initialize(queue_name)
			# Slug used for Redis key names
			queue_slug = queue_name.parameterize

			# Initialize new Redis-backed linked lists and hashes
			@list = RedisList.new "queue_#{queue_slug}_list"
			@hash = RedisHash.new "queue_#{queue_slug}_hash"
		end

		# Length of queue
		def length
			@list.length
		end
		def empty?
			length.zero?
		end

		# Add to end of queue
		def push(user)
			# Note that we only push if the user's not already in the queue
			return false if user.nil? or user.id.nil? or in_queue?(user)

			list_length = @list.push(user.id)
			# Always returns true as user.id always a new key
			@hash.set(user.id, list_length-1)
		end

		# Remove from start of queue
		def pop
			user_id = @list.pop
			return nil if user_id.nil?

			# Remove user from position hash
			@hash.delete user_id

			# Update hash entries for all elements
			decrement_position_values @list.values

			# Return user from their id
			User.find user_id
		end

		# Given a user, check if they're in the queue
		# i.e. if they're in the hash
		def in_queue?(user)
			not (user.nil? or user.id.nil?) and @hash.include?(user.id)
		end

		# Return the position of a user in the queue
		# i.e. the value they have in the hash
		def position(user)
			return nil if user.nil? or user.id.nil?
			pos = @hash.get(user.id)
			pos.nil? ? nil : pos.to_i  # convert to integer ignoring nils
		end

		# Get the user at a given position in the queue
		def get(index)
			return nil if index.nil? or index < 0 or index >= @list.length
			user_id = @list.get(@list.length-1 - index)
			return nil if user_id.nil?
			User.find user_id
		end

		# Remove a user from the queue
		# i.e. remove them from the list and hash
		# and update everyone after them's hash entry
		# Comparatively slow compared to all other methods
		# Return whether we removed them successfully
		def remove(user)
			return false if user.nil? or user.id.nil? or not in_queue?(user)

			# Even though we delete from the list by value, we need the index
			# of the user for updating position values
			user_index = @hash.get(user.id).to_i

			# Remove from hash and list
			@hash.delete user.id
			@list.remove user.id

			# Update new hash entries for everything after the user in the queue
			decrement_position_values @list.values_after(user_index)

			true
		end

		private
		# For each id in the passed list, decrement it's position
		def decrement_position_values(ids)
			ids.each do |id|
				@hash.decrement id
			end
		end
	end
end
