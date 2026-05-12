module Occurrences
  class ListService
    def initialize(date_from:, date_to:, status: nil, tag_ids: nil)
      @date_from = date_from
      @date_to = date_to
      @status = status
      @tag_ids = tag_ids
    end

    def call
      tasks = load_tasks
      occurrences = expand_occurrences(tasks)
      filter_by_status(occurrences)
    end

    private

    def load_tasks
      scope = Task.includes(:tags, :task_occurrences)
      scope = scope.joins(:task_tags).where(task_tags: { tag_id: @tag_ids }).distinct if @tag_ids.present?
      scope
    end

    def expand_occurrences(tasks)
      tasks.flat_map do |task|
        task.recurring? ? expand_recurring(task) : expand_one_time(task)
      end
    end

    def expand_recurring(task)
      generator = Recurrence::GeneratorFactory.build(task)
      dates = generator.dates_in_range(@date_from, @date_to)
      occurrences_index = task.task_occurrences.index_by(&:occurrence_date)

      dates.map do |date|
        OccurrencePresenter.new(task: task, occurrence_date: date, occurrence: occurrences_index[date])
      end
    end

    def expand_one_time(task)
      return [] unless task.due_date&.between?(@date_from, @date_to)

      [OccurrencePresenter.new(task: task, occurrence_date: task.due_date)]
    end

    def filter_by_status(occurrences)
      return occurrences if @status.blank?

      occurrences.select { |o| o.status == @status }
    end
  end
end
