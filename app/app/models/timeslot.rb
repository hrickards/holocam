class Timeslot < ActiveRecord::Base
  belongs_to :user

	validates :user, presence: true
	validates :start_time, presence: true
	validates :end_time, presence: true
	validate :check_in_future, on: :create # We still want to be able to modify timeslots in the past!
	validate :check_valid_time_interval
	# Split up into two methods as implementation is very different on create and update
	validate :check_monotonic_create, on: :create
	validate :check_monotonic_update, on: :update

	# Some small (insignificant) period of time we can use to avoid floating point errors
	EPSILON = (1e-2).seconds

	# Length of a standard timeslot
	STANDARD_LENGTH = 2.minutes

	# Length of time period between start and end times
	def length
		end_time - start_time
	end

	# Number of time slots where the start is (to some small epsilon accuracy) in the future
	# Assumes that the number of timeslots starting before now is small compared to the number of timeslots starting after now
	# (a valid assumption because a worker repeatedly cleans up those starting before now)
	# Assumes timeslots are monotonically increasing which we guarantee by validation
	# TODO: Cache this for a small number of milliseconds
	def self.queue_length
		return 0 if Timeslot.count.zero?

		start_index = 0
		# Find first timeslot where start is greater than now
		threshold_time = Time.now - EPSILON
		threshold_timeslot = Timeslot.all.each_with_index.find { |timeslot, index| timeslot.start_time > threshold_time }
		return 0 if threshold_timeslot.nil?

		Timeslot.count - threshold_timeslot.last
	end

	# If a timeslot containing the current time exists, return it
	def self.current_slot
		# We want the timeslot with end_time > Time.now and start_time < Time.now
		# It's guaranteed that if timeslot i has end_time > Time.now, then i+1 will have start_time > Time.now 
		# So we only need to check the first timeslot with end_time > Time.now
		threshold_time = Time.now - EPSILON
		possible_timeslot = Timeslot.find { |timeslot| timeslot.end_time > threshold_time }
		return (possible_timeslot.present? and possible_timeslot.start_time < Time.now + EPSILON) ? possible_timeslot : nil
	end

	# Create a new timeslot starting as soon as possible
	# TODO: Calculate the optimum length of the timeslot, rather than hardcoding it
	def self.add_to_queue(user)
		last_timeslot = Timeslot.last
		if last_timeslot.present? and last_timeslot.end_time > (Time.now - EPSILON)
			start_time = last_timeslot.end_time
		else
			start_time = Time.now + EPSILON
		end
		return Timeslot.create! user: user, start_time: start_time, end_time: start_time + STANDARD_LENGTH
	end

	# Check that a given timeslot is 'in the future'
	def check_in_future
		if start_time.present? and start_time < (Time.now - EPSILON)
			errors.add(:start_time, "can't be in the past")
		end
	end

	# Check that the timeslot ends after it starts
	def check_valid_time_interval
		if start_time.present? and end_time.present? and end_time < start_time + EPSILON
			errors.add(:end_time, "can't be before start_time")
		end
	end

	# Check that the new/updated timeslot 'fits in' to the order correctly, that is:
	#  - start time >= prev end time
	#  - end time <= next start time
	#  provided both of those are defined
	#  To do this we define next/prev helpers that order by ID (and hence timeslot
	#  because monotonicity is guaranteed)
	def next
		Timeslot.where("id > ?", id).first
	end
	def prev
		Timeslot.order(id: :desc).where("id < ?", id).first
	end
	def check_monotonic_update
		prev_timeslot = prev
		next_timeslot = self.next

		if prev_timeslot.present? and prev_timeslot.end_time > start_time
			errors.add(:start_time, "can't be before previous end_time")
		end

		if next_timeslot.present? and next_timeslot.start_time < end_time
			errors.add(:end_time, "can't be after next start_time")
		end
	end

	# Do the same thing when we're adding a new record, only here our job is much
	# easier: we just need to compare to the last Timeslot
	def check_monotonic_create
		prev_timeslot = Timeslot.last
		if prev_timeslot.present? and prev_timeslot.end_time > start_time
			errors.add(:start_time, "can't be before previous end_time")
		end
	end
end
