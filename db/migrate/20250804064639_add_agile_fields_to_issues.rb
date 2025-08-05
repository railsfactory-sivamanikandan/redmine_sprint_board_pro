class AddAgileFieldsToIssues < ActiveRecord::Migration[7.2]
  def change
    add_column :issues, :story_points, :integer
    add_column :issues, :sprint_id, :integer
    add_column :issues, :board_position, :integer
  end
end
