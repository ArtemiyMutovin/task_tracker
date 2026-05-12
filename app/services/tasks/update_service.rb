module Tasks
  class UpdateService
    # Any of these params can invalidate previously-stored occurrence overrides:
    # recurrence rule changes invalidate dates outside the new rule; due_date
    # changes (for one-time tasks) invalidate the override at the old date.
    STALE_TRIGGER_KEYS = %w[recurrence_type starts_on ends_on recurrence_params due_date].freeze

    def initialize(task, params)
      @task = task
      @params = params
    end

    def call
      cleanup_needed = stale_trigger_present?
      clear_stale_recurrence_params

      success = false
      ActiveRecord::Base.transaction do
        if @task.update(@params)
          cleanup_stale_occurrences if cleanup_needed
          success = true
        else
          raise ActiveRecord::Rollback
        end
      end

      if success
        ServiceResult.new(success: true, object: @task)
      else
        ServiceResult.new(success: false, errors: @task.errors.full_messages)
      end
    end

    private

    def stale_trigger_present?
      (@params.keys.map(&:to_s) & STALE_TRIGGER_KEYS).any?
    end

    # When recurrence_type changes, clear old recurrence_params so stale keys don't persist.
    # @task.update(@params) will then apply the new recurrence_params (if provided), or leave {}.
    def clear_stale_recurrence_params
      return unless @params.key?(:recurrence_type) || @params.key?("recurrence_type")

      new_type = @params[:recurrence_type] || @params["recurrence_type"]
      return if new_type.to_s == @task.recurrence_type.to_s

      @task.recurrence_params = {}
    end

    def cleanup_stale_occurrences
      if @task.recurring?
        delete_stale_recurring_overrides
      elsif @task.due_date.present?
        # One-time task: keep only the override that matches the (possibly new) due_date.
        @task.task_occurrences.where.not(occurrence_date: @task.due_date).delete_all
      else
        @task.task_occurrences.delete_all
      end
    end

    # Walks each stored override date and asks the generator whether it's still
    # valid. Cheap per-call (one-day window) and avoids materialising the full
    # rule range when overrides span years.
    def delete_stale_recurring_overrides
      generator = Recurrence::GeneratorFactory.build(@task)
      stale_dates = @task.task_occurrences.pluck(:occurrence_date).reject do |date|
        generator.dates_in_range(date, date).include?(date)
      end
      return if stale_dates.empty?

      @task.task_occurrences.where(occurrence_date: stale_dates).delete_all
    end
  end
end
