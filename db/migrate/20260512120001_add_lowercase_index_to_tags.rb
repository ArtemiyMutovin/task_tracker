class AddLowercaseIndexToTags < ActiveRecord::Migration[7.2]
  def up
    remove_index :tags, :name
    execute 'CREATE UNIQUE INDEX index_tags_on_lower_name ON tags (LOWER(name))'
  end

  def down
    execute 'DROP INDEX IF EXISTS index_tags_on_lower_name'
    add_index :tags, :name, unique: true
  end
end
