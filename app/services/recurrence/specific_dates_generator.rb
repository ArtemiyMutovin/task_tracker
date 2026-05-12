module Recurrence
  class SpecificDatesGenerator < BaseGenerator
    def dates_in_range(date_from, date_to)
      start, finish = effective_range(date_from, date_to)
      return [] if start > finish

      @task.recurrence_params["dates"]
        .map { |d| Date.iso8601(d) }
        .uniq
        .select { |d| d >= start && d <= finish }
        .sort
    end
  end
end
