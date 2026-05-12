class OccurrencePresenter
  attr_reader :task, :occurrence_date, :occurrence

  def initialize(task:, occurrence_date:, occurrence: nil)
    @task = task
    @occurrence_date = occurrence_date
    @occurrence = occurrence
  end

  def id
    occurrence&.id
  end

  def task_id
    task.id
  end

  def status
    occurrence&.status || (task.recurring? ? "pending" : task.status)
  end

  # nil on the override means "no override" → fall back to the template.
  # An explicit empty string is treated as an intentional clear.
  def title
    occurrence&.title.nil? ? task.title : occurrence.title
  end

  def description
    occurrence&.description.nil? ? task.description : occurrence.description
  end

  def cancelled
    occurrence&.cancelled? || false
  end

  def tags
    task.tags
  end

  def recurrence_type
    task.recurrence_type
  end

  def recurrence_params
    task.recurrence_params
  end
end
