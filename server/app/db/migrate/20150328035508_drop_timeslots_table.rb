class DropTimeslotsTable < ActiveRecord::Migration
  def change
		drop_table :timeslots
  end
end
