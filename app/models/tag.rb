class Tag < ApplicationRecord
  SYSTEM_NAMES = %w[отчетность операции звонок].freeze

  has_many :task_tags, dependent: :destroy
  has_many :tasks, through: :task_tags

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :system, inclusion: { in: [true, false] }

  before_update :protect_system_tag
  before_destroy :protect_system_tag

  private

  def protect_system_tag
    if system?
      throw :abort
    end
  end
end
