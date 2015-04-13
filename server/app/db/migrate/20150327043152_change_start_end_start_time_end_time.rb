class ChangeStartEndStartTimeEndTime < ActiveRecord::Migration
  def change
		rename_column :timeslots, :start, :start_time
		rename_column :timeslots, :end, :end_time
  end
end
