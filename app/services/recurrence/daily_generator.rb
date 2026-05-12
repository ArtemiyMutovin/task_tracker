module Recurrence
  class DailyGenerator < BaseGenerator
    def dates_in_range(date_from, date_to)
      start, finish = effective_range(date_from, date_to)
      return [] if start > finish

      interval = @task.recurrence_params['interval']
      first = aligned_start(start, interval)
      return [] if first > finish

      dates = []
      current = first
      while current <= finish
        dates << current
        current += interval
      end
      dates
    end

    private

    def aligned_start(date_from, interval)
      origin = @task.starts_on
      return origin if origin >= date_from

      days_diff = (date_from - origin).to_i
      remainder = days_diff % interval
      remainder == 0 ? date_from : date_from + (interval - remainder)
    end
  end
end
