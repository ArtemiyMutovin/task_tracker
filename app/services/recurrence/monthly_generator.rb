module Recurrence
  class MonthlyGenerator < BaseGenerator
    def dates_in_range(date_from, date_to)
      start, finish = effective_range(date_from, date_to)
      return [] if start > finish

      day = @task.recurrence_params["day"]
      dates = []

      current_month = Date.new(start.year, start.month, 1)
      end_month = Date.new(finish.year, finish.month, 1)

      while current_month <= end_month
        clamped_day = [ day, current_month.next_month.prev_day.day ].min
        date = Date.new(current_month.year, current_month.month, clamped_day)
        dates << date if date >= start && date <= finish
        current_month = current_month >> 1
      end

      dates
    end
  end
end
