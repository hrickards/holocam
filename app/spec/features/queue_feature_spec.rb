require "rails_helper"

feature "Timeslots queue", js: true do
	before do
		# TODO: Can we access controller helpers here to be DRY?
		@qm = TimedQueue::QueueManager.instance
	end


	def visit_queue
		visit '/'
	end

	def add_me_to_queue
		within('#queue') do
			click_button I18n.t('queue.add_me')
		end
	end

	def remove_me_from_queue
		within('#queue') do
			click_button I18n.t('queue.remove_me')
		end
	end

	def check_queue_empty
		within('#queue') do
			expect(page).to have_content I18n.t('queue.queue_empty')
		end
	end

	def check_queue_not_empty
		within('#queue') do
			expect(page).to have_content I18n.t('queue.queue_length_label')
			expect(page).to have_content I18n.t('queue.queue_eta_label')
		end
	end

	def check_on_queue
		within('#queue') do
			expect(page).to have_content I18n.t('queue.remove_me')
			expect(page).to have_content I18n.t('queue.eta_label')
			expect(page).to have_content I18n.t('queue.position_label')
		end
	end

	def check_on_now
		within('#queue') do
			expect(page).to have_content I18n.t('queue.on_now')
			expect(page).to have_content I18n.t('queue.remove_me')
		end
	end

	def check_off_queue
		within('#queue') do
			expect(page).to have_content I18n.t('queue.add_me')
		end
	end

	def check_cant_add_to_queue
		within('#queue') do
			expect(page).to_not have_content I18n.t('queue.add_me')
		end
	end

	def add_to_queue
		page.click_button I18n.t('queue.add_me')
	end

	def remove_from_queue
		page.click_button I18n.t('queue.remove_me')
	end

	# Pop items from the queue until the current user is on
	def step_queue_til_on_now(current_user)
		until (@qm.current_user?(current_user) or @qm.queue_empty?)
			@qm.step
		end
	end

	# Pop items from the queue until the current user is no longer on the queue
	def step_queue_til_removed(current_user)
		while (@qm.in_queue?(current_user) and not @qm.queue_empty?)
			@qm.step
		end
	end

	def prefill_queue
		# Some users we can use to test with
		users = 5.times.map { |i| FactoryGirl.create :testuser }
		# Initialize queue with data
		users.each { |user| @qm.add(user) }
	end

	context "when ogged in" do
		background do
			@email = Faker::Internet.email
			@password = Faker::Internet.password
			@current_user = FactoryGirl.create :testuser, provider: "traditional", uid: @email, password: @password
			# Log in
			visit '/signup'
			within('#session') do
				fill_in I18n.t('label.email'), with: @email
				fill_in I18n.t('label.password'), with: @password
			end
			click_button I18n.t('button.sign_up')
		end

		context "when queue is empty" do
			scenario "when initially visiting page" do
				visit_queue
				check_queue_empty
				check_off_queue
			end

			scenario "when adding to queue" do
				visit_queue
				add_to_queue
				check_queue_not_empty
				check_on_now
			end
		end

		context "when queue is not empty" do
			background do
				prefill_queue
			end

			scenario "when initially visiting page" do
				visit_queue
				check_queue_not_empty
				check_off_queue
			end

			scenario "when adding to queue" do
				visit_queue
				add_to_queue
				check_queue_not_empty
				check_on_queue
			end

			scenario "when removing from queue" do
				visit_queue
				add_to_queue
				remove_from_queue
				check_off_queue
				check_queue_not_empty
			end

			scenario "when adding to queue and waiting to come on" do
				visit_queue
				add_to_queue
				step_queue_til_on_now(@current_user)
				check_on_now
				check_queue_not_empty
			end

			scenario "when adding to queue and waiting to die" do
				visit_queue
				add_to_queue
				step_queue_til_removed(@current_user)
				check_off_queue
				check_queue_empty
			end
		end
	end

	context "when logged out" do
		context "when queue empty" do
			scenario "when visiting queue" do
				visit_queue
				check_queue_empty
				check_cant_add_to_queue
			end
		end

		context "when queue is not empty" do
			background do
				prefill_queue
			end

			scenario "when visiting queue" do
				visit_queue
				check_queue_not_empty
				check_cant_add_to_queue
			end
		end
	end
end
