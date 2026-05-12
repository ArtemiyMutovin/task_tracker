module Recurrence
  class GeneratorFactory
    GENERATORS = {
      "daily" => DailyGenerator,
      "monthly" => MonthlyGenerator,
      "specific_dates" => SpecificDatesGenerator,
      "even_odd" => EvenOddGenerator
    }.freeze

    def self.build(task)
      klass = GENERATORS[task.recurrence_type]
      raise ArgumentError, "Unknown recurrence type: #{task.recurrence_type}" unless klass

      klass.new(task)
    end
  end
end
