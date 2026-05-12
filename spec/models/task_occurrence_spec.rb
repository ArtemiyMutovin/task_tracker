require 'rails_helper'

RSpec.describe TaskOccurrence, type: :model do
  describe 'associations' do
    it { should belong_to(:task) }
  end

  describe 'validations' do
    subject { build(:task_occurrence) }

    it { should validate_presence_of(:occurrence_date) }
    it { should validate_uniqueness_of(:occurrence_date).scoped_to(:task_id) }
    it { should validate_inclusion_of(:status).in_array(TaskStatuses::STATUSES) }

    it 'validates cancelled is boolean' do
      occurrence = build(:task_occurrence, cancelled: nil)
      expect(occurrence).not_to be_valid
    end
  end
end
