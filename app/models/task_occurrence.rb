class TaskOccurrence < ApplicationRecord
  include TaskStatuses

  belongs_to :task

  validates :occurrence_date, presence: true, uniqueness: { scope: :task_id }
  validates :status, inclusion: { in: STATUSES }
  validates :cancelled, inclusion: { in: [true, false] }
end
