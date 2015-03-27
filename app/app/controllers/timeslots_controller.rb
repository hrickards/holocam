class TimeslotsController < ApplicationController
	# GET /timeslots.json
  def index
  end

	# POST /timeslots
  def create
		if signed_in?
			Timeslot.add_to_queue current_user
			redirect_to root_url, notice: I18n.t('notice.added_to_queue')
		else
			redirect_to root_url, alert: I18n.t('error.must_be_logged_in')
		end
  end

	# DESTROY /timeslots
  def destroy
		if signed_in?
			if Timeslot.in_queue?(current_user)
				Timeslot.remove_from_queue current_user
				redirect_to root_url, notice: I18n.t('notice.removed_from_queue')
			else
				redirect_to root_url, alert: I18n.t('error.not_in_queue')
			end
		else
			redirect_to root_url, alert: I18n.t('error.must_be_logged_in')
		end
  end
end
