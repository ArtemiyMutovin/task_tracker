module Recurrence
  class BaseGenerator
    def initialize(task)
      @task = task
    end

    def dates_in_range(date_from, date_to)
      raise NotImplementedError, "#{self.class}#dates_in_range is not implemented"
    end

    private

    def effective_range(date_from, date_to)
      start = [ @task.starts_on, date_from ].max
      finish = @task.ends_on ? [ @task.ends_on, date_to ].min : date_to
      [ start, finish ]
    end
  end
end
