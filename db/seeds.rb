Tag::SYSTEM_NAMES.each do |name|
  Tag.find_or_create_by!(name: name) { |t| t.system = true }
end

puts "Created system tags: #{Tag::SYSTEM_NAMES.join(', ')}"
