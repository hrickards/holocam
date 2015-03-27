require 'rails_helper'

# TODO
# Timeslot factory is in users.rb because it relies on the user factory
# Is there a better way to do this? (Hint: probably)
FactoryGirl.reload

RSpec.describe Timeslot, type: :model do
	describe "#valid?" do
		context "when timeslot is normal" do
			let(:timeslot) { FactoryGirl.build(:timeslot) }
			it 'is valid' do
				expect(timeslot).to be_valid
			end
		end


		context "when user is nil" do
			let(:timeslot) { FactoryGirl.build(:timeslot, user: nil) }
			it 'is not valid' do
				expect(timeslot).to_not be_valid
			end
		end

		context "when start is nil" do
			let(:timeslot) { FactoryGirl.build(:timeslot, start_time: nil) }
			it 'is not valid' do
				expect(timeslot).to_not be_valid
			end
		end

		context "when end is nil" do
			let(:timeslot) { FactoryGirl.build(:timeslot, end_time: nil) }
			it 'is not valid' do
				expect(timeslot).to_not be_valid
			end
		end

		context "when timeslots are overlapping" do
			let(:start_time) { Faker::Time.between(Time.now, 24.hours.from_now) }
			let(:first_overlap) { Faker::Time.between(start_time, start_time + 24.hours) }
			let(:second_overlap) { Faker::Time.between(start_time, first_overlap) }
			let(:end_time) { Faker::Time.between(first_overlap, first_overlap + 24.hours) }
			
			let(:first_timeslot) { FactoryGirl.build(:timeslot, start_time: start_time, end_time: first_overlap) }
			let(:second_timeslot) { FactoryGirl.build(:timeslot, start_time: second_overlap, end_time: end_time) }

			it 'is not valid' do
				first_timeslot.save
				expect(second_timeslot).to_not be_valid
			end
		end

		context "when we modify a timeslot to be overlapping" do
			let(:first_start) { Faker::Time.between(Time.now, 12.hours.from_now) }
			let(:first_end) { Faker::Time.between(first_start, 24.hours.from_now) }
			let(:second_start) { Faker::Time.between(24.hours.from_now, 48.hours.from_now) }
			let(:second_end) { Faker::Time.between(second_start, second_start + 24.hours) }

			let(:first_timeslot) { FactoryGirl.build(:timeslot, start_time: first_start, end_time: first_end ) }
			let(:second_timeslot) { FactoryGirl.build(:timeslot, start_time: second_start, end_time: second_end) }

			it 'is not valid' do
				first_timeslot.save
				second_timeslot.save

				first_timeslot.end_time = Faker::Time.between(second_start, second_end)
				expect(first_timeslot).to_not be_valid
			end
		end

		context "when second timeslot is before first timeslot" do
			let(:first_start) { Faker::Time.between(24.hours.from_now, 48.hours.from_now) }
			let(:first_end) { Faker::Time.between(first_start, first_start + 24.hours) }
			let(:second_start) { Faker::Time.between(Time.now, 12.hours.from_now) }
			let(:second_end) { Faker::Time.between(second_start, 24.hours.from_now) }

			let(:first_timeslot) { FactoryGirl.build(:timeslot, start_time: first_start, end_time: first_end) }
			let(:second_timeslot) { FactoryGirl.build(:timeslot, start_time: second_start, end_time: second_end) }

			it 'is not valid' do
				first_timeslot.save
				expect(second_timeslot).to_not be_valid
			end
		end

		context "when two timeslots are equal" do
			let(:first_timeslot) { FactoryGirl.build(:timeslot) }
			let(:second_timeslot) { FactoryGirl.build(:timeslot, start_time: first_timeslot.start_time, end_time: first_timeslot.end_time) }
			it 'is not valid' do
				first_timeslot.save
				expect(second_timeslot).to_not be_valid
			end
		end

		context "when timeslot ends before it starts" do
			let(:start_time) { Faker::Time.between(24.hours.from_now, 48.hours.from_now) }
			let(:end_time) { Faker::Time.between(Time.now, 24.hours.from_now) }
			let(:timeslot) { FactoryGirl.build(:timeslot, start_time: start_time, end_time: end_time) }
			it 'is not valid' do
				expect(timeslot).to_not be_valid
			end
		end

		context "when timeslot starts before present" do
			let(:start_time) { Faker::Time.between(48.hours.ago, 24.hours.ago) }
			let(:end_time) { Faker::Time.between(Time.now, 24.hours.from_now) }
			let(:timeslot) { FactoryGirl.build(:timeslot, start_time: start_time, end_time: end_time) }
			it 'is not valid' do
				expect(timeslot).to_not be_valid 
			end
		end
	end

	describe "#length" do
		# Length of 1 hour
		let(:timeslot) { FactoryGirl.build(:timeslot, start_time: 1.hour.from_now, end_time: 2.hours.from_now) }
		it "correctly returns the length" do
			# floating point errors
			expect(timeslot.length).to be_within((0.5).seconds).of(1.hour)
		end
	end

	describe "self#queue_length" do
		context "when timeslots are present" do
			let(:num_future_timeslots) { rand(0..50) }
			let(:num_past_timeslots) { rand(0..50) }
			before(:each) do 
				# Force add some timeslots that ended in the past
				# We still want monotonic increasing, so we generate in monotonic decreasing then reverse the list
				past_timeslots = (1..num_past_timeslots).map do |i|
					FactoryGirl.build :timeslot, start_time: i.hours.ago, end_time: (i+1).hours.ago
				end
				past_timeslots.reverse.each do |timeslot|
					timeslot.save validate: false
				end

				# Add (monotonically increasing) timeslots num_timeslots times
				(1..num_future_timeslots).each do |i|
					FactoryGirl.create :timeslot, start_time: i.hours.from_now, end_time: (i+0.5).hours.from_now
				end
			end


			it "correctly returns the queue length" do
				expect(Timeslot.queue_length).to eq(num_future_timeslots)
			end
		end

		context "when all timeslots are in the past" do
			before(:each) do 
				(1..rand(0..50)).each do |i|
					# Force add something that ended in the past to the queue
					prev_timeslot = FactoryGirl.build :timeslot, start_time: 1.hour.ago, end_time: 30.minutes.ago
					prev_timeslot.save validate: false
				end
			end

			it "returns the queue length as 0" do
				expect(Timeslot.queue_length).to eq(0)
			end
		end

		context "when there are no timeslots present" do
			it "returns the queue length as 0" do
				expect(Timeslot.queue_length).to eq(0)
			end
		end
	end

	describe "self#current_slot" do
		context "when both past and future timeslots are present" do
			let(:num_future_timeslots) { rand(0..50) }
			let(:num_past_timeslots) { rand(0..50) }
			before(:each) do 
				# Force add some timeslots that ended in the past
				# We still want monotonic increasing, so we generate in monotonic decreasing then reverse the list
				past_timeslots = (1..num_past_timeslots).map do |i|
					FactoryGirl.build :timeslot, start_time: i.hours.ago, end_time: (i+1).hours.ago
				end
				past_timeslots.reverse.each do |timeslot|
					timeslot.save validate: false
				end

				# Add a timeslot containing the current time
				@timeslot = FactoryGirl.build :timeslot, start_time: 1.minute.ago, end_time: 1.minute.from_now
				@timeslot.save validate: false

				# Add (monotonically increasing) timeslots num_timeslots times
				# Note that none of these include the *current* time
				(1..num_future_timeslots).each do |i|
					FactoryGirl.create :timeslot, start_time: i.hours.from_now, end_time: (i+0.5).hours.from_now
				end
			end

			context "when a timeslot contains the current time" do
				it "returns that timeslot" do
					expect(Timeslot.current_slot).to eq(@timeslot)
				end
			end

			context "when no timeslot contains the current time" do
				before(:each) do
					@timeslot.destroy
				end

				it "returns nil" do
					expect(Timeslot.current_slot).to eq(nil)
				end
			end
		end

		context "when no timeslots are present" do
			it "returns nil" do
				expect(Timeslot.current_slot).to eq(nil)
			end
		end
	end

	describe "self#add_to_queue" do
		let(:user) { FactoryGirl.create(:user) }

		context "when timeslots are present" do
			let(:num_timeslots) { rand(0..50) }
			before(:each) do 
				# Add (monotonically increasing) timeslots num_timeslots times
				# Note that none of these include the *current* time
				(1..num_timeslots).each do |i|
					FactoryGirl.create :timeslot, start_time: i.hours.from_now, end_time: (i+0.5).hours.from_now
				end
				@max_last_time = (num_timeslots+0.5).hours.from_now
			end

			it "adds a timeslot" do
				expect { Timeslot.add_to_queue(user) }.to change(Timeslot, :count).by(1)
			end

			it "adds a timeslot starting at the end of the last timeslot" do
				expect(Timeslot.add_to_queue(user).start_time).to be_within((0.5).seconds).of(@max_last_time)
			end

			context "when some of timeslots present already are user's" do
				it "should not add a timeslot" do
					Timeslot.add_to_queue(user)
					expect { Timeslot.add_to_queue(user) }.to_not change(Timeslot, :count)
				end
			end
		end


		context "when timeslots are present, but all are in the past" do
			let(:num_timeslots) { rand(0..50) }
			before(:each) do 
				# Force add some timeslots that ended in the past
				# We still want monotonic increasing, so we generate in monotonic decreasing then reverse the list
				past_timeslots = (1..num_timeslots).map do |i|
					FactoryGirl.build :timeslot, start_time: i.hours.ago, end_time: (i+0.5).hours.ago
				end
				past_timeslots.reverse.each do |timeslot|
					timeslot.save validate: false
				end
			end

			it "adds a timeslot" do
				expect { Timeslot.add_to_queue(user) }.to change(Timeslot, :count).by(1)
			end

			it "adds a timeslot starting now" do
				expect(Timeslot.add_to_queue(user).start_time).to be_within((0.5).seconds).of(Time.now)
			end
		end

		context "when no timeslots are present" do
			it "adds a timeslot" do
				expect { Timeslot.add_to_queue(user) }.to change(Timeslot, :count).by(1)
			end

			it "adds a timeslot starting now" do
				expect(Timeslot.add_to_queue(user).start_time).to be_within((0.5).seconds).of(Time.now)
			end
		end
	end

	describe "self#find_in_queue" do
		let(:user) { FactoryGirl.create(:user) }
		context "when nil user passed" do
			before(:each) do 
				FactoryGirl.create :timeslot, start_time: 1.minute.from_now, end_time: 3.minutes.from_now
				Timeslot.add_to_queue(user)
			end

			it "returns nil" do
				expect(Timeslot.find_in_queue(nil)).to eql(nil)
			end
		end

		context "when user in queue" do
			before(:each) do 
				FactoryGirl.create :timeslot, start_time: 1.minute.from_now, end_time: 3.minutes.from_now
				@timeslot = Timeslot.add_to_queue(user)
			end

			it "returns the timeslot" do
				expect(Timeslot.find_in_queue(user)).to eql(@timeslot)
			end
		end

		context "when user used to be in queue" do
			before(:each) do 
				timeslot = FactoryGirl.build :timeslot, start_time: 1.minute.ago, end_time: 3.minutes.ago, user: user
				timeslot.save validate: false
				FactoryGirl.create :timeslot, start_time: 1.minute.from_now, end_time: 3.minutes.from_now
			end

			it "returns nil" do
				expect(Timeslot.find_in_queue(user)).to eql(nil)
			end
		end

		context "when user was never in queue" do
			before(:each) do 
				FactoryGirl.create :timeslot, start_time: 1.minute.from_now, end_time: 3.minutes.from_now
			end

			it "returns nil" do
				expect(Timeslot.find_in_queue(user)).to eql(nil)
			end
		end
	end

	describe "self#in_queue?" do
		let(:user) { FactoryGirl.create(:user) }
		context "when nil user passed" do
			before(:each) do 
				FactoryGirl.create :timeslot, start_time: 1.minute.from_now, end_time: 3.minutes.from_now
				Timeslot.add_to_queue(user)
			end

			it "returns nil" do
				expect(Timeslot.in_queue?(nil)).to eql(nil)
			end
		end

		context "when user in queue" do
			before(:each) do 
				FactoryGirl.create :timeslot, start_time: 1.minute.from_now, end_time: 3.minutes.from_now
				Timeslot.add_to_queue(user)
			end

			it "returns true" do
				expect(Timeslot.in_queue?(user)).to eql(true)
			end
		end

		context "when user used to be in queue" do
			before(:each) do 
				timeslot = FactoryGirl.build :timeslot, start_time: 1.minute.ago, end_time: 3.minutes.ago, user: user
				timeslot.save validate: false
				FactoryGirl.create :timeslot, start_time: 1.minute.from_now, end_time: 3.minutes.from_now
			end

			it "returns false" do
				expect(Timeslot.in_queue?(user)).to eql(false)
			end
		end

		context "when user was never in queue" do
			before(:each) do 
				FactoryGirl.create :timeslot, start_time: 1.minute.from_now, end_time: 3.minutes.from_now
			end

			it "returns false" do
				expect(Timeslot.in_queue?(user)).to eql(false)
			end
		end
	end

	describe "self#remove_from_queue" do
		let(:user) { FactoryGirl.create(:user) }
		context "when nil user passed" do
			before(:each) do 
				FactoryGirl.create :timeslot, start_time: 1.minute.from_now, end_time: 3.minutes.from_now
				Timeslot.add_to_queue(user)
			end

			it "returns nil" do
				expect(Timeslot.remove_from_queue(nil)).to eql(nil)
			end
		end

		context "when user in queue" do
			before(:each) do 
				FactoryGirl.create :timeslot, start_time: 1.minute.from_now, end_time: 3.minutes.from_now
				@timeslot = Timeslot.add_to_queue(user)
			end

			it "returns the timeslot" do
				expect(Timeslot.remove_from_queue(user)).to eql(@timeslot)
			end
			it "removes the timeslot from the queue" do
				expect { Timeslot.remove_from_queue(user) }.to change(Timeslot, :count).by(-1)
			end
		end

		context "when user used to be in queue" do
			before(:each) do 
				timeslot = FactoryGirl.build :timeslot, start_time: 1.minute.ago, end_time: 3.minutes.ago, user: user
				timeslot.save validate: false
				FactoryGirl.create :timeslot, start_time: 1.minute.from_now, end_time: 3.minutes.from_now
			end

			it "returns nil" do
				expect(Timeslot.remove_from_queue(nil)).to eql(nil)
			end
			it "doesn't change the queue" do
				expect { Timeslot.remove_from_queue(user) }.to_not change(Timeslot, :count)
			end
		end

		context "when user was never in queue" do
			before(:each) do 
				FactoryGirl.create :timeslot, start_time: 1.minute.from_now, end_time: 3.minutes.from_now
			end

			it "returns nil" do
				expect(Timeslot.remove_from_queue(nil)).to eql(nil)
			end
			it "doesn't change the queue" do
				expect { Timeslot.remove_from_queue(user) }.to_not change(Timeslot, :count)
			end
		end
	end

end
