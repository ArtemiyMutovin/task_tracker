class CreateTaskOccurrences < ActiveRecord::Migration[7.2]
  def change
    create_table :task_occurrences do |t|
      t.references :task, null: false, foreign_key: true
      t.date :occurrence_date, null: false
      t.string :status, null: false, default: 'pending'
      t.string :title
      t.text :description
      t.boolean :cancelled, null: false, default: false

      t.timestamps
    end

    add_index :task_occurrences, %i[task_id occurrence_date], unique: true
    add_index :task_occurrences, :status
  end
end
