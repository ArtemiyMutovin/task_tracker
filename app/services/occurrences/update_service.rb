module Occurrences
  class UpdateService
    def initialize(task, date, params)
      @task = task
      @date = date
      @params = params.slice(:status, :title, :description, :cancelled)
    end

    def call
      occurrence = @task.task_occurrences.find_or_initialize_by(occurrence_date: @date)
      occurrence.assign_attributes(@params)
      occurrence.status ||= 'pending'

      if occurrence.save
        ServiceResult.new(success: true, object: build_presenter(occurrence))
      else
        ServiceResult.new(success: false, errors: occurrence.errors.full_messages)
      end
    end

    private

    def build_presenter(occurrence)
      OccurrencePresenter.new(
        task: @task,
        occurrence_date: @date,
        occurrence: occurrence
      )
    end
  end
end
