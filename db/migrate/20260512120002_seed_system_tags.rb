class SeedSystemTags < ActiveRecord::Migration[7.2]
  SYSTEM_TAG_NAMES = %w[отчетность операции звонок].freeze

  def up
    SYSTEM_TAG_NAMES.each do |name|
      execute <<~SQL
        INSERT INTO tags (name, system, created_at, updated_at)
        SELECT '#{name}', true, NOW(), NOW()
        WHERE NOT EXISTS (SELECT 1 FROM tags WHERE LOWER(name) = '#{name}')
      SQL
    end
  end

  def down
    execute "DELETE FROM tags WHERE system = true AND name IN ('отчетность', 'операции', 'звонок')"
  end
end
