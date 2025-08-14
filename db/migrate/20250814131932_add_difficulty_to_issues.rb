class AddDifficultyToIssues < ActiveRecord::Migration[7.2]
  def change
    add_column :issues, :difficulty, :string
    add_index :issues, :difficulty
  end
end
