class TaskOccurrence < ApplicationRecord
  include TaskStatuses

  belongs_to :task

  validates :occurrence_date, presence: true, uniqueness: { scope: :task_id }
  validates :status, inclusion: { in: STATUSES }
  validates :cancelled, inclusion: { in: [ true, false ] }
  validates :title, length: { maximum: 255 }, allow_blank: true
  validates :description, length: { maximum: 5000 }, allow_blank: true
end
