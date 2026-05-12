module Tasks
  class CreateService
    def initialize(params)
      @params = params
    end

    def call
      task = Task.new(@params)
      if task.save
        ServiceResult.new(success: true, object: task)
      else
        ServiceResult.new(success: false, errors: task.errors.full_messages)
      end
    end
  end
end
