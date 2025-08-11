# frozen_string_literal: true

class AddMissingUniqueIndices < ActiveRecord::Migration[6.0]
  def self.up
    # Add unique index on tags.name
    unless index_exists?(ActsAsTaggableOn.tags_table, :name, unique: true)
      add_index ActsAsTaggableOn.tags_table, :name, unique: true
    end

    # Safely remove index on tag_id if no FK constraint is present
    if index_exists?(ActsAsTaggableOn.taggings_table, :tag_id, name: 'index_taggings_on_tag_id')
      fk_exists = foreign_keys(ActsAsTaggableOn.taggings_table).any? { |fk| fk.options[:column].to_s == "tag_id" }
      remove_index ActsAsTaggableOn.taggings_table, name: 'index_taggings_on_tag_id' unless fk_exists
    end

    # Remove old non-unique context index if it exists
    if index_exists?(ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type context], name: 'taggings_taggable_context_idx')
      remove_index ActsAsTaggableOn.taggings_table, name: 'taggings_taggable_context_idx'
    end

    # Add new unique combined index
    unless index_exists?(ActsAsTaggableOn.taggings_table,
                         %i[tag_id taggable_id taggable_type context tagger_id tagger_type],
                         unique: true, name: 'taggings_idx')
      add_index ActsAsTaggableOn.taggings_table,
                %i[tag_id taggable_id taggable_type context tagger_id tagger_type],
                unique: true, name: 'taggings_idx'
    end
  end

  def self.down
    remove_index ActsAsTaggableOn.tags_table, :name if index_exists?(ActsAsTaggableOn.tags_table, :name, unique: true)

    if index_exists?(ActsAsTaggableOn.taggings_table, name: 'taggings_idx')
      remove_index ActsAsTaggableOn.taggings_table, name: 'taggings_idx'
    end

    unless index_exists?(ActsAsTaggableOn.taggings_table, :tag_id)
      add_index ActsAsTaggableOn.taggings_table, :tag_id
    end

    unless index_exists?(ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type context], name: 'taggings_taggable_context_idx')
      add_index ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type context],
                name: 'taggings_taggable_context_idx'
    end
  end
end