class RecurrenceParamsValidator < ActiveModel::Validator
  MAX_INTERVAL = 365
  MAX_DATES    = 366

  def validate(record)
    return unless record.recurring?

    case record.recurrence_type
    when "daily"          then validate_daily(record)
    when "monthly"        then validate_monthly(record)
    when "specific_dates" then validate_specific_dates(record)
    when "even_odd"       then validate_even_odd(record)
    end
  end

  private

  def validate_daily(record)
    interval = record.recurrence_params["interval"]
    unless interval.is_a?(Integer) && interval.between?(1, MAX_INTERVAL)
      record.errors.add(:recurrence_params, "must include 'interval' as an integer between 1 and #{MAX_INTERVAL}")
    end
  end

  def validate_monthly(record)
    day = record.recurrence_params["day"]
    unless day.is_a?(Integer) && day.between?(1, 31)
      record.errors.add(:recurrence_params, "must include 'day' between 1 and 31")
    end
  end

  def validate_specific_dates(record)
    dates = record.recurrence_params["dates"]

    unless dates.is_a?(Array) && dates.present? && dates.all? { |d| iso8601_date?(d) }
      record.errors.add(:recurrence_params, "must include non-empty 'dates' array of valid ISO 8601 date strings")
      return
    end

    if dates.size > MAX_DATES
      record.errors.add(:recurrence_params, "'dates' must contain at most #{MAX_DATES} entries")
    end
  end

  def validate_even_odd(record)
    unless %w[even odd].include?(record.recurrence_params["parity"])
      record.errors.add(:recurrence_params, "must include 'parity' as 'even' or 'odd'")
    end
  end

  def iso8601_date?(str)
    Date.iso8601(str.to_s)
    true
  rescue Date::Error, TypeError
    false
  end
end
