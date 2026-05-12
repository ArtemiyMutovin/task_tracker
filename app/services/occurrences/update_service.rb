module Occurrences
  class UpdateService
    def initialize(task, date, params)
      @task = task
      @date = date
      @params = params.slice(:status, :title, :description, :cancelled)
    end

    def call
      return failure(["Date #{@date} does not match this task's schedule"]) unless date_valid?
      return failure(["cancelled occurrences cannot have a non-cancelled status"]) unless cancelled_status_consistent?

      normalize_params
      occurrence = find_or_upsert_occurrence
      ServiceResult.new(success: true, object: build_presenter(occurrence))
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    def failure(errors)
      ServiceResult.new(success: false, errors: errors)
    end

    def date_valid?
      if @task.recurring?
        Recurrence::GeneratorFactory.build(@task).dates_in_range(@date, @date).include?(@date)
      else
        @task.due_date == @date
      end
    end

    def cancelled_param
      ActiveModel::Type::Boolean.new.cast(@params[:cancelled])
    end

    def cancelled_status_consistent?
      return true unless cancelled_param == true
      status = @params[:status]
      status.nil? || status == 'cancelled'
    end

    def normalize_params
      @params[:cancelled] = cancelled_param unless @params[:cancelled].nil?
      @params[:status] = 'cancelled' if cancelled_param == true && @params[:status].nil?
    end

    def find_or_upsert_occurrence
      retries = 0
      begin
        occurrence = @task.task_occurrences.find_or_initialize_by(occurrence_date: @date)
        occurrence.assign_attributes(@params)
        occurrence.status ||= 'pending'
        occurrence.save!
        occurrence
      rescue ActiveRecord::RecordNotUnique
        raise if (retries += 1) >= 2
        retry
      end
    end

    def build_presenter(occurrence)
      OccurrencePresenter.new(task: @task, occurrence_date: @date, occurrence: occurrence)
    end
  end
end
