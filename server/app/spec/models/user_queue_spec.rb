require 'rails_helper'

RSpec.describe TimedQueue::UserQueue, type: :model do
	# Setup testing queue
	let(:queue) { TimedQueue::UserQueue.new('timeslots') }

	# Setup user
	let(:user) { FactoryGirl.create(:testuser) }

	# Prefill the queue with data
	def prefill_queue
		num_items = rand(2..50)
		num_items.times do
			queue.push FactoryGirl.create(:testuser)
		end
		return num_items
	end

	# Add user to the end of the queue
	describe "push" do
		shared_examples_for "common_push" do
			it "adds user to queue" do
				expect { queue.push(user) }.to change(queue, :length).by(1)
			end

			it "doesn't allow us to add the user twice in succession" do
				queue.push(user)
				expect { queue.push(user) }.to_not change(queue, :length)
			end

			it "doesn't allow us to add the user twice with other people in between" do
				queue.push(user)
				prefill_queue
				expect { queue.push(user) }.to_not change(queue, :length)
			end
		end

		context "when queue is empty" do
			it_behaves_like "common_push"

			# not in queue_empty because it would be needlessly complicated: push(a) => pop=a
			# is only true if the queue is empty
			it "allows us to add the user to the queue if they used to be in it" do
				queue.push(user)
				queue.pop
				expect { queue.push(user) }.to change(queue, :length).by(1)
			end
		end

		context "when queue is not empty" do
			before(:each) { prefill_queue }
			it_behaves_like "common_push"
		end
	end

	# Remove first user from the start of the queue
	describe "pop" do
		context "when queue is empty" do
			it "returns nil" do
				expect(queue.pop).to eql(nil)
			end
		end

		context "when queue is not empty" do
			it "should return the users added in FIFO order" do
				# We take a new random list of test users
				users = rand(50).times.map { FactoryGirl.create(:testuser) }
				# and split them up into two groups
				users = users.in_groups(2, nil)
				first_users = users.first
				last_users = users.last

				# We add each of the first users in turn
				first_users.each { |u| queue.push(u) }

				# and then remove a portion of them, checking they're in FIFO order
				num_to_pop = rand(0..first_users.length)
				num_to_pop.times do |i|
					expect(queue.pop).to eql(first_users[i])
				end

				# We add our second batch of users
				last_users.each { |u| queue.push(u) }

				# and then remove all remaining users, checking they're in FIFO order
				num_first_left = first_users.length - num_to_pop
				num_first_left.times do |i|
					expect(queue.pop).to eql(first_users[num_to_pop + i])
				end
				last_users.length.times do |i|
					expect(queue.pop).to eql(last_users[i])
				end
			end
		end
	end

	# Number of items in queue
	describe "length" do
		context "when queue is empty" do
			it "returns zero" do
				expect(queue.length).to eql(0)
			end
		end

		context "when queue is not empty" do
			before(:each) do
				@num_items = prefill_queue
			end

			it "returns the correct length" do
				expect(queue.length).to eql(@num_items)
			end

			it "returns the correct length after some popping" do
				num_popped = rand(@num_items)
				num_popped.times { queue.pop }
				expect(queue.length).to eql(@num_items - num_popped)
			end
		end
	end

	# Whether queue is empty or not
	describe "empty?" do
		context "when queue is empty" do
			it "returns true" do
				expect(queue.empty?).to eql(true)
			end

			context "when queue was nonempty then popped until empty" do
				before(:each) do
					@num_items = prefill_queue
					@num_items.times { queue.pop }
				end

				it "returns true" do
					expect(queue.empty?).to eql(true)
				end
			end
		end

		context "when queue is not empty" do
			before(:each) do
				prefill_queue
			end

			it "returns false" do
				expect(queue.empty?).to eql(false)
			end
		end
	end

	# Tests in_queue?, remove, position and get methods
	describe "user specific behaviour" do
		shared_examples_for "nil_argument_methods" do
			it "returns that the nil user is not in the queue" do
				expect(queue.in_queue?(nil)).to eql(false)
			end
			it "cannot remove the nil user from the queue" do
				expect(queue.remove(nil)).to eql(false)
			end
			it "doesn't do anything when we try and remove the nil user" do
				expect { queue.remove(nil) }.not_to change(queue, :length)
			end
			it "should return the queue position of the nil user as nil" do
				expect(queue.position(nil)).to eql(nil)
			end
			it "should return the nil'th user as nil" do
				expect(queue.get(nil)).to eql(nil)
			end
		end

		shared_examples_for "user_in_queue" do
			it "returns that the user is in the queue" do
				expect(queue.in_queue?(user)).to eql(true)
			end
			it "can remove the user from the queue and return true" do
				expect(queue.remove(user)).to eql(true)
				expect(queue.in_queue?(user)).to eql(false)
			end
			it "only removes one item at a time" do
				expect { queue.remove(user) }.to change(queue, :length).by(-1)
			end
			it "returns the user from their position correctly" do
				expect(queue.get(queue.position(user))).to eq(user)
			end
			it "returns nil if we query for a user out of range of the queue" do
				expect(queue.get(queue.length)).to eq(nil)
				expect(queue.get(-1)).to eq(nil)
			end
		end

		shared_examples_for "user_not_in_queue" do
			it "returns that the user is not in the queue" do
				expect(queue.in_queue?(user)).to eql(false)
			end
			it "returns false on attempting to remove the user from the queue" do
				expect(queue.remove(user)).to eql(false)
			end
			it "doesn't actually remove anything from the queue" do
				expect { queue.remove(user) }.to_not change(queue, :length)
			end
			it "should return our queue position as nil" do
				expect(queue.position(user)).to eq(nil)
			end
		end

		context "when user at start of queue" do
			before(:each) do
				queue.push(user)
				prefill_queue
			end
			it_behaves_like "nil_argument_methods"
			it_behaves_like "user_in_queue"
			it "should return our queue position as 0" do
				expect(queue.position(user)).to eq(0)
			end
		end

		context "when user at end of queue" do
			before(:each) do
				prefill_queue
				queue.push(user)
			end
			it_behaves_like "nil_argument_methods"
			it_behaves_like "user_in_queue"
			it "should return our queue position as the list length - 1" do
				expect(queue.position(user)).to eq(queue.length - 1)
			end
		end

		# The main test of position
		context "when user at middle of queue" do
			before(:each) do
				initial_count = prefill_queue
				queue.push(user)
				# Remove some items from the queue and update our calculated position
				delta = rand(1...initial_count)
				delta.times { queue.pop }
				prefill_queue
				@expected_position = initial_count - delta
			end
			it_behaves_like "nil_argument_methods"
			it_behaves_like "user_in_queue"
			it "should return our queue position correctly" do
				expect(queue.position(user)).to eq(@expected_position)
			end
		end

		context "when queue empty" do
			it_behaves_like "nil_argument_methods"
			it_behaves_like "user_not_in_queue"
		end

		context "when user used to be in queue" do
			before(:each) do
				queue.push(user)
				queue.pop
				prefill_queue
			end
			it_behaves_like "nil_argument_methods"
			it_behaves_like "user_not_in_queue"
		end

		context "when user never in queue" do
			before(:each) do
				prefill_queue
			end
			it_behaves_like "nil_argument_methods"
			it_behaves_like "user_not_in_queue"
		end
	end
end
