require 'rails_helper'

RSpec.describe TimedQueue::QueueManager, type: :model do
	# Setup testing queue manager
	let(:qm) { TimedQueue::QueueManager.instance }

	# Setup users
	let(:user) { FactoryGirl.create(:testuser) }
	let(:user2) { FactoryGirl.create(:testuser) }
	let(:user3) { FactoryGirl.create(:testuser) }

	# Prefill the queue with data
	def fill_queue(num_items)
		num_items.times do
			qm.add FactoryGirl.create(:testuser)
		end
		return num_items
	end
	def fill_queue_random
		fill_queue rand(2..50)
	end

	context "queue empty" do
		describe "current_user" do
			it "returns nil" do
				expect(qm.current_user).to eq(nil)
			end
		end
		describe "current_user?" do
			it "returns false when passed a valid user" do
				expect(qm.current_user?(user)).to eq(false)
			end
			it "returns false when passed nil" do
				expect(qm.current_user?(nil)).to eq(false)
			end
		end
		describe "queue_length" do
			it "returns 0" do
				expect(qm.queue_length).to eq(0)
			end
		end
		describe "queue_empty?" do
			it "returns true" do
				expect(qm.queue_empty?).to eq(true)
			end
		end
		describe "in_queue?" do
			it "returns false when given a user" do
				expect(qm.in_queue?(user)).to eq(false)
			end
			it "returns false when given nil" do
				expect(qm.in_queue?(nil)).to eq(false)
			end
		end
		describe "queue_eta" do
			it "returns 0" do
				expect(qm.queue_eta).to eq(0)
			end
		end
		describe "position" do
			it "returns nil when passed a valid user" do
				expect(qm.position(user)).to eq(nil)
			end
			it "returns nil when passed nil" do
				expect(qm.position(nil)).to eq(nil)
			end
		end
		describe "eta" do
			it "returns nil when passed a valid user" do
				expect(qm.eta(user)).to eq(nil)
			end
			it "returns nil when passed nil" do
				expect(qm.eta(nil)).to eq(nil)
			end
		end
		describe "step" do
			it "returns nil" do
				expect(qm.step).to eq(nil)
			end
			it "does not affect queue length" do
				expect { qm.step }.to_not change(qm, :queue_length)
			end
		end
		describe "add" do
			context "when nil passed" do
				it "returns nil" do
					expect(qm.add(nil)).to eq(nil)
				end
				it "does not affect queue length" do
					expect { qm.add(nil) }.to_not change(qm, :queue_length)
				end
			end
			context "when a valid user passed" do
				it "returns the queue position: 0" do
					expect(qm.add(user)).to eq(0)
				end
				it "increases the queue length to 1" do
					expect { qm.add(user) }.to change(qm, :queue_length).by(1)
				end
			end
		end
		describe "remove" do
			context "when nil passed" do
				it "returns false" do
					expect(qm.remove(nil)).to eq(false)
				end
				it "does not affect queue length" do
					expect { qm.remove(nil) }.to_not change(qm, :queue_length)
				end
			end
			context "when a valid user passed" do
				it "returns false" do
					expect(qm.remove(user)).to eq(false)
				end
				it "does not affect queue length" do
					expect { qm.remove(user) }.to_not change(qm, :queue_length)
				end
			end
		end
	end

	context "queue not empty" do
		before(:each) do
			qm.add(user)
			qm.add(user2)
			num_added = fill_queue_random
			@queue_length = num_added + 2
		end
		describe "current_user" do
			it "returns the current user" do
				expect(qm.current_user).to eq(user)
			end
		end
		describe "current_user?" do
			it "returns true when passed the current user" do
				expect(qm.current_user?(user)).to eq(true)
			end
			it "returns false when passed another user" do
				expect(qm.current_user?(user2)).to eq(false)
			end
			it "returns false when passed nil" do
				expect(qm.current_user?(nil)).to eq(false)
			end
		end
		describe "queue_length" do
			it "returns the queue length" do
				expect(qm.queue_length).to eq(@queue_length)
			end
		end
		describe "queue_empty?" do
			it "returns false" do
				expect(qm.queue_empty?).to eq(false)
			end
		end
		describe "in_queue?" do
			it "returns true when given a user in the queue" do
				expect(qm.in_queue?(user2)).to eq(true)
			end
			it "returns false when given a user not in the queue" do
				expect(qm.in_queue?(user3)).to eq(false)
			end
			it "returns false when given nil" do
				expect(qm.in_queue?(nil)).to eq(false)
			end
		end
		describe "queue_eta" do
			it "it returns a non-zero ETA" do
				expect(qm.queue_eta).to be > 0
			end
		end
		describe "position" do
			it "returns 0 when passed the current user" do
				expect(qm.position(user)).to eq(0)
			end
			it "returns the position of the user when passed another user in the queue" do
				expect(qm.position(user2)).to eq(1)
			end
			it "returns nil when passed another user not in the queue" do
				expect(qm.position(FactoryGirl.create(:user))).to eq(nil)
			end
			it "returns nil when passed nil" do
				expect(qm.position(nil)).to eq(nil)
			end
		end
		describe "eta" do
			it "returns 0 when passed the current user" do
				expect(qm.eta(user)).to eq(0)
			end
			it "returns a nonzero ETA when passed another user in the queue" do
				expect(qm.eta(user2)).to be > 0
			end
			it "returns nil when passed a user not in the queue" do
				expect(qm.eta(user3)).to eq(nil)
			end
			it "returns nil when passed nil" do
				expect(qm.eta(nil)).to eq(nil)
			end
		end
		describe "step" do
			it "returns the user now at the head of the queue" do
				expect(qm.step).to eq(user2)
			end
			it "decreases queue length by 1" do
				expect { qm.step }.to change(qm, :queue_length).by(-1)
			end
		end
		describe "add" do
			context "when nil passed" do
				it "returns nil" do
					expect(qm.add(nil)).to eq(nil)
				end
				it "does not affect queue length" do
					expect { qm.add(nil) }.to_not change(qm, :queue_length)
				end
			end
			context "when a valid user passed" do
				it "returns the queue position of the user" do
					expect(qm.add(user3)).to eq(qm.queue_length-1)
				end
				it "increases the queue length by 1" do
					expect { qm.add(user3) }.to change(qm, :queue_length).by(1)
				end
			end
		end
		describe "remove" do
			context "when nil passed" do
				it "returns false" do
					expect(qm.remove(nil)).to eq(false)
				end
				it "does not affect queue length" do
					expect { qm.remove(nil) }.to_not change(qm, :queue_length)
				end
			end
			context "when a valid user in the queue passed" do
				it "returns true" do
					expect(qm.remove(user)).to eq(true)
				end
				it "removes the user from the queue" do
					expect { qm.remove(user) }.to change(qm, :queue_length).by(-1)
					expect(qm.in_queue?(user)).to eq(false)
				end
			end
			context "when a valid user not in the queue passed" do
				it "returns false" do
					expect(qm.remove(user3)).to eq(false)
				end
				it "does not affect the queue length" do
					expect { qm.remove(user3) }.to_not change(qm, :queue_length)
				end
			end
		end
	end
end
