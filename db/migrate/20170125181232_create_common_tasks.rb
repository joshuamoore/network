class CreateCommonTasks < ActiveRecord::Migration
  def change
    create_table :common_tasks do |t|
      t.string :name
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
