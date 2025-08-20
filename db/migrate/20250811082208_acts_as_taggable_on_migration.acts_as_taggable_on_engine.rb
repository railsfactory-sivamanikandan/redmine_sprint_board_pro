# frozen_string_literal: true

# This migration comes from acts_as_taggable_on_engine (originally 1)
class ActsAsTaggableOnMigration < ActiveRecord::Migration[6.0]
  def self.up
    create_table ActsAsTaggableOn.tags_table, if_not_exists: true do |t|
      t.string :name
      t.timestamps
    end

    create_table ActsAsTaggableOn.taggings_table, if_not_exists: true do |t|
      t.references :tag, foreign_key: { to_table: ActsAsTaggableOn.tags_table }

      # You should make sure that the column created is
      # long enough to store the required class names.
      t.references :taggable, polymorphic: true
      t.references :tagger, polymorphic: true

      # Limit is created to prevent MySQL error on index
      # length for MyISAM table type: http://bit.ly/vgW2Ql
      t.string :context, limit: 128

      t.datetime :created_at
    end
    if column_exists?(ActsAsTaggableOn.taggings_table, :context)
      unless index_exists?(ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type context],
                        name: 'taggings_taggable_context_idx')

        add_index ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type context],
                name: 'taggings_taggable_context_idx'
      end
    end
  end

  def self.down
    drop_table ActsAsTaggableOn.taggings_table
    drop_table ActsAsTaggableOn.tags_table
  end
end
