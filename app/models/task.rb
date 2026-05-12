class Task < ApplicationRecord
  include TaskStatuses

  RECURRENCE_TYPES = %w[daily monthly specific_dates even_odd].freeze

  has_many :task_tags, dependent: :delete_all
  has_many :tags, through: :task_tags
  has_many :task_occurrences, dependent: :delete_all

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true
  validates :status, inclusion: { in: STATUSES }
  validates :recurrence_type, inclusion: { in: RECURRENCE_TYPES }, allow_nil: true
  validate :validate_due_date_or_starts_on
  validate :validate_ends_on_after_starts_on
  validates_with RecurrenceParamsValidator

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
      errors.add(:due_date, "must be blank for recurring tasks") if due_date.present?
    else
      errors.add(:due_date, :blank) if due_date.blank?
    end
  end

  def validate_ends_on_after_starts_on
    return if ends_on.blank? || starts_on.blank?
    errors.add(:ends_on, "must be on or after starts_on") if ends_on < starts_on
  end
end
