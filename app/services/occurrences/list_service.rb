module Occurrences
  class ListService
    def initialize(date_from:, date_to:, status: nil, tag_ids: nil, include_cancelled: false)
      @date_from = date_from
      @date_to = date_to
      @status = status
      @tag_ids = Array.wrap(tag_ids).flat_map { |v| v.to_s.split(",") }.map(&:to_i).reject(&:zero?)
      @include_cancelled = include_cancelled
    end

    def call
      tasks = load_tasks
      occurrences = expand_occurrences(tasks)
      occurrences = filter_cancelled(occurrences)
      filter_by_status(occurrences)
    end

    private

    def load_tasks
      scope = Task
        .where(recurrence_type: Task::RECURRENCE_TYPES)
        .or(Task.where(recurrence_type: nil, due_date: @date_from..@date_to))

      if @tag_ids.present?
        task_ids = Task.joins(:task_tags)
                       .where(task_tags: { tag_id: @tag_ids })
                       .distinct
                       .pluck(:id)
        scope = scope.where(id: task_ids)
      end

      tasks = scope.includes(:tags).to_a
      preload_occurrences(tasks)
      tasks
    end

    def preload_occurrences(tasks)
      return if tasks.empty?

      occurrences_by_task = TaskOccurrence
        .where(task_id: tasks.map(&:id), occurrence_date: @date_from..@date_to)
        .group_by(&:task_id)

      tasks.each do |task|
        task.association(:task_occurrences).target = occurrences_by_task.fetch(task.id, [])
      end
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
      override = task.task_occurrences.find { |o| o.occurrence_date == task.due_date }
      [ OccurrencePresenter.new(task: task, occurrence_date: task.due_date, occurrence: override) ]
    end

    def filter_cancelled(occurrences)
      return occurrences if @include_cancelled
      occurrences.reject(&:cancelled)
    end

    def filter_by_status(occurrences)
      return occurrences if @status.blank?
      occurrences.select { |o| o.status == @status }
    end
  end
end
