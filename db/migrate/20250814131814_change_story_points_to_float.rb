class ChangeStoryPointsToFloat < ActiveRecord::Migration[7.2]
  def change
    change_column :issues, :story_points, :float
  end
end
