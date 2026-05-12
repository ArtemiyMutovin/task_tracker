module Recurrence
  class EvenOddGenerator < BaseGenerator
    def dates_in_range(date_from, date_to)
      start, finish = effective_range(date_from, date_to)
      return [] if start > finish

      parity = @task.recurrence_params["parity"]
      dates = []
      current = start

      while current <= finish
        dates << current if matches_parity?(current.day, parity)
        current += 1
      end

      dates
    end

    private

    def matches_parity?(day, parity)
      parity == "even" ? day.even? : day.odd?
    end
  end
end
