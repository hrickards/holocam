require 'singleton'

# Singleton managing a UserQueue instance
module TimedQueue
	class QueueManager
		include Singleton
		# Length of each session
		# TODO: Dynamic?
		TIME_PERIOD = 2.minutes

		def initialize
			@queue = UserQueue.new 'timeslots'
		end

		# Add a user to the queue
		def add(user)
			@queue.push user
			return position(user)
		end

		# Remove the person currently at the head of the queue
		def step
			@queue.pop
			current_user
		end

		# Remove a specific user from the queue
		def remove(user)
			@queue.remove(user)
		end

		# Return the length of the queue
		def queue_length
			@queue.length
		end
		def queue_empty?
			@queue.empty?
		end

		# Return the user currently at the head of the queue
		def current_user
			@queue.get 0
		end
		def current_user?(user)
			(not user.nil?) and user == current_user
		end

		# Whether a user is in the queue at any point
		def in_queue?(user)
			@queue.in_queue? user
		end

		# Return the position of a user within the queue
		def position(user)
			@queue.position(user)
		end

		# Return the estimated time for all of the queue to run
		def queue_eta
			TIME_PERIOD * queue_length
		end
		# Estimated time for a user to be 'up'
		def eta(user)
			pos = position(user)
			return nil if pos.nil?
			pos * TIME_PERIOD
		end
	end
end
