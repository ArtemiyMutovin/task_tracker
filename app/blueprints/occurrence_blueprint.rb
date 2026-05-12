class OccurrenceBlueprint < Blueprinter::Base
  field(:id) { |o| o.id }
  field(:task_id) { |o| o.task_id }
  field(:occurrence_date) { |o| o.occurrence_date }
  field(:status) { |o| o.status }
  field(:title) { |o| o.title }
  field(:description) { |o| o.description }
  field(:cancelled) { |o| o.cancelled }
  field(:recurrence_type) { |o| o.recurrence_type }
  field(:tags) { |o| TagBlueprint.render_as_hash(o.tags) }
end
