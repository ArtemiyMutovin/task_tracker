class TaskBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :description, :status, :due_date,
         :starts_on, :ends_on, :recurrence_type, :recurrence_params,
         :created_at, :updated_at

  view :with_tags do
    association :tags, blueprint: TagBlueprint
  end
end
