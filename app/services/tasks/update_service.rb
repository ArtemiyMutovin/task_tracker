module Tasks
  class UpdateService
    def initialize(task, params)
      @task = task
      @params = params
    end

    def call
      if @task.update(@params)
        ServiceResult.new(success: true, object: @task)
      else
        ServiceResult.new(success: false, errors: @task.errors.full_messages)
      end
    end
  end
end
