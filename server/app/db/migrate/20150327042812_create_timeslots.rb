class CreateTimeslots < ActiveRecord::Migration
  def change
    create_table :timeslots do |t|
      t.references :user, index: true
      t.timestamp :start
      t.timestamp :end

      t.timestamps
    end
  end
end
