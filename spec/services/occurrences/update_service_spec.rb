require 'rails_helper'

RSpec.describe Occurrences::UpdateService do
  let(:task) { create(:task, :daily, starts_on: Date.new(2025, 1, 1), recurrence_params: { 'interval' => 1 }) }
  let(:date) { Date.new(2025, 1, 5) }

  describe '#call' do
    it 'creates a new occurrence override' do
      result = described_class.new(task, date, { status: 'done' }).call
      expect(result).to be_success
      expect(result.object.status).to eq('done')
      expect(task.task_occurrences.count).to eq(1)
    end

    it 'updates an existing occurrence' do
      create(:task_occurrence, task: task, occurrence_date: date, status: 'pending')
      result = described_class.new(task, date, { status: 'in_progress' }).call
      expect(result).to be_success
      expect(result.object.status).to eq('in_progress')
      expect(task.task_occurrences.count).to eq(1)
    end

    it 'returns failure on invalid status' do
      result = described_class.new(task, date, { status: 'bogus' }).call
      expect(result).to be_failure
      expect(result.errors).to be_present
    end

    it 'does not affect other dates' do
      described_class.new(task, date, { status: 'done' }).call
      other = Date.new(2025, 1, 6)
      presenter = described_class.new(task, other, { status: 'in_progress' }).call.object
      expect(presenter.status).to eq('in_progress')
      jan5 = task.task_occurrences.find_by(occurrence_date: date)
      expect(jan5.status).to eq('done')
    end

    it 'supports overriding title and description independently' do
      result = described_class.new(task, date, { title: 'Custom title', description: 'Custom desc' }).call
      expect(result).to be_success
      expect(result.object.title).to eq('Custom title')
      expect(result.object.description).to eq('Custom desc')
    end

    it 'supports cancelling a single occurrence' do
      result = described_class.new(task, date, { cancelled: true, status: 'cancelled' }).call
      expect(result).to be_success
      expect(result.object.cancelled).to be(true)
    end

    it 'defaults status to "cancelled" when only cancelled:true is provided' do
      result = described_class.new(task, date, { cancelled: true }).call
      expect(result).to be_success
      occurrence = task.task_occurrences.find_by(occurrence_date: date)
      expect(occurrence.status).to eq('cancelled')
    end

    it 'rejects contradictory cancelled:true with non-cancelled status' do
      result = described_class.new(task, date, { cancelled: true, status: 'done' }).call
      expect(result).to be_failure
      expect(result.errors.join).to match(/cancelled/)
    end

    it 'treats string "true" as cancelled for consistency checks' do
      result = described_class.new(task, date, { cancelled: 'true', status: 'done' }).call
      expect(result).to be_failure
    end

    it 'defaults status to "cancelled" when cancelled is the string "true"' do
      result = described_class.new(task, date, { cancelled: 'true' }).call
      expect(result).to be_success
      occurrence = task.task_occurrences.find_by(occurrence_date: date)
      expect(occurrence.cancelled).to be(true)
      expect(occurrence.status).to eq('cancelled')
    end

    context 'when date does not match the recurrence rule' do
      let(:task) { create(:task, :monthly, starts_on: Date.new(2025, 1, 1), recurrence_params: { 'day' => 15 }) }

      it 'rejects PATCH on a date outside the schedule' do
        result = described_class.new(task, Date.new(2025, 1, 10), { status: 'done' }).call
        expect(result).to be_failure
        expect(result.errors.join).to match(/schedule/)
        expect(task.task_occurrences.count).to eq(0)
      end

      it 'accepts PATCH on a scheduled date' do
        result = described_class.new(task, Date.new(2025, 1, 15), { status: 'done' }).call
        expect(result).to be_success
      end
    end

    context 'when task is one-time' do
      let(:task) { create(:task, due_date: Date.new(2025, 6, 1)) }

      it 'accepts PATCH only on due_date' do
        expect(described_class.new(task, Date.new(2025, 6, 1), { status: 'done' }).call).to be_success
        expect(described_class.new(task, Date.new(2025, 6, 2), { status: 'done' }).call).to be_failure
      end
    end
  end
end
