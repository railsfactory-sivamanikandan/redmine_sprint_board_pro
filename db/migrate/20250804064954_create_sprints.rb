class CreateSprints < ActiveRecord::Migration[7.2]
  def change
    create_table :sprints do |t|
      t.string :name
      t.date :start_date
      t.date :end_date
      t.integer :project_id
      t.boolean :completed, default: false

      t.timestamps
    end
  end
end
