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
    occurrence&.status || (task.recurring? ? 'pending' : task.status)
  end

  def title
    occurrence&.title || task.title
  end

  def description
    occurrence&.description || task.description
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
end
