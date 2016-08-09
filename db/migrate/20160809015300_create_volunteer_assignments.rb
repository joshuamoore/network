class CreateVolunteerAssignments < ActiveRecord::Migration
  def change
    create_table :volunteer_assignments do |t|
      t.integer :member_id
      t.integer :network_event_id
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
