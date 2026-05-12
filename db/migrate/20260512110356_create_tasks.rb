class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: 'pending'
      t.date :due_date
      t.date :starts_on
      t.date :ends_on
      t.string :recurrence_type
      t.jsonb :recurrence_params, null: false, default: {}

      t.timestamps
    end

    add_index :tasks, :status
    add_index :tasks, :due_date
    add_index :tasks, :recurrence_type
  end
end
