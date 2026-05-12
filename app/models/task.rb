class Task < ApplicationRecord
  include TaskStatuses

  RECURRENCE_TYPES = %w[daily monthly specific_dates even_odd].freeze

  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags
  has_many :task_occurrences, dependent: :destroy

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :recurrence_type, inclusion: { in: RECURRENCE_TYPES }, allow_nil: true
  validate :validate_due_date_or_starts_on
  validate :validate_recurrence_params, if: :recurring?

  scope :recurring, -> { where.not(recurrence_type: nil) }
  scope :one_time, -> { where(recurrence_type: nil) }
  scope :with_due_date_in, ->(from, to) { one_time.where(due_date: from..to) }

  def recurring?
    recurrence_type.present?
  end

  private

  def validate_due_date_or_starts_on
    if recurring?
      errors.add(:starts_on, :blank) if starts_on.blank?
    else
      errors.add(:due_date, :blank) if due_date.blank?
    end
  end

  def validate_recurrence_params
    case recurrence_type
    when 'daily'
      validate_daily_params
    when 'monthly'
      validate_monthly_params
    when 'specific_dates'
      validate_specific_dates_params
    when 'even_odd'
      validate_even_odd_params
    end
  end

  def validate_daily_params
    interval = recurrence_params['interval']
    unless interval.is_a?(Integer) && interval >= 1
      errors.add(:recurrence_params, "must include positive integer 'interval'")
    end
  end

  def validate_monthly_params
    day = recurrence_params['day']
    unless day.is_a?(Integer) && day.between?(1, 31)
      errors.add(:recurrence_params, "must include 'day' between 1 and 31")
    end
  end

  def validate_specific_dates_params
    dates = recurrence_params['dates']
    unless dates.is_a?(Array) && dates.present? && dates.all? { |d| parseable_date?(d) }
      errors.add(:recurrence_params, "must include non-empty 'dates' array of valid date strings")
    end
  end

  def validate_even_odd_params
    unless %w[even odd].include?(recurrence_params['parity'])
      errors.add(:recurrence_params, "must include 'parity' as 'even' or 'odd'")
    end
  end

  def parseable_date?(str)
    Date.parse(str.to_s)
    true
  rescue Date::Error, TypeError
    false
  end
end
