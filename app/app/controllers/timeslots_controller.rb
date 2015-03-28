class TimeslotsController < ApplicationController
	# GET /queue.json
  def index
		# Build up a JSON response
		# For documentation, see functional tests in timeslots_controller_spec
		@data = {}
		@data[:queue_length] = queue_manager.queue_length
		@data[:queue_empty] = queue_manager.queue_empty?
		@data[:queue_eta] = queue_manager.queue_eta unless @data[:queue_empty]
		if signed_in?
			if queue_manager.in_queue?(current_user)
				@data[:in_queue] = true
				@data[:position] = queue_manager.position current_user
				@data[:eta] = queue_manager.eta current_user
			else
				@data[:in_queue] = false
			end
		end

		render json: @data
  end

	# POST /queue
  def create
		if signed_in?
			queue_manager.add current_user
			redirect_to root_url, notice: I18n.t('notice.added_to_queue')
		else
			redirect_to root_url, alert: I18n.t('error.must_be_signed_in')
		end
  end

	# DESTROY /queue
  def destroy
		if signed_in?
			if queue_manager.in_queue?(current_user)
				queue_manager.remove current_user
				redirect_to root_url, notice: I18n.t('notice.removed_from_queue')
			else
				redirect_to root_url, alert: I18n.t('error.not_in_queue')
			end
		else
			redirect_to root_url, alert: I18n.t('error.must_be_signed_in')
		end
  end
end
