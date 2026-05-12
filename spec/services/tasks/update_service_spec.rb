require 'rails_helper'

RSpec.describe Tasks::UpdateService do
  describe '#call' do
    context 'non-recurring task' do
      let(:task) { create(:task, title: 'Old', due_date: Date.new(2025, 1, 1)) }

      it 'updates the task' do
        result = described_class.new(task, { title: 'New' }).call
        expect(result).to be_success
        expect(result.object.title).to eq('New')
      end

      it 'returns failure on invalid params' do
        result = described_class.new(task, { title: '' }).call
        expect(result).to be_failure
        expect(result.errors).to be_present
      end
    end

    context 'when recurrence rule changes' do
      let(:base_date) { Date.new(2025, 1, 1) }
      let(:task) { create(:task, :daily, starts_on: base_date, recurrence_params: { 'interval' => 1 }) }

      before do
        create(:task_occurrence, task: task, occurrence_date: base_date + 2, status: 'done')
        create(:task_occurrence, task: task, occurrence_date: base_date + 4, status: 'done')
      end

      it 'removes stale overrides when interval changes' do
        described_class.new(task, { recurrence_params: { 'interval' => 3 } }).call
        remaining_dates = task.task_occurrences.pluck(:occurrence_date)
        remaining_dates.each do |date|
          days_diff = (date - base_date).to_i
          expect(days_diff % 3).to eq(0), "#{date} is not aligned to interval 3"
        end
      end

      it 'clears all overrides when converting to one-time' do
        described_class.new(task, { recurrence_type: nil, due_date: Date.new(2025, 6, 1) }).call
        expect(task.task_occurrences.count).to eq(0)
      end

      it 'clears old recurrence_params when type changes' do
        described_class.new(task, { recurrence_type: 'monthly', recurrence_params: { 'day' => 15 } }).call
        expect(task.reload.recurrence_params).to eq({ 'day' => 15 })
        expect(task.recurrence_params.key?('interval')).to be(false)
      end

      it 'clears recurrence_params when type changes without new params' do
        described_class.new(task, { recurrence_type: 'monthly', recurrence_params: { 'day' => 1 } }).call
        expect(task.reload.recurrence_params.key?('interval')).to be(false)
      end
    end

    context 'when due_date changes on a one-time task' do
      let(:task) { create(:task, due_date: Date.new(2026, 3, 15), status: 'pending') }

      before do
        create(:task_occurrence, task: task, occurrence_date: Date.new(2026, 3, 15), status: 'done')
      end

      it 'removes orphaned overrides at the old due_date' do
        described_class.new(task, { due_date: Date.new(2026, 4, 1) }).call
        remaining = task.task_occurrences.pluck(:occurrence_date)
        expect(remaining).not_to include(Date.new(2026, 3, 15))
      end

      it 'preserves an override that happens to match the new due_date' do
        create(:task_occurrence, task: task, occurrence_date: Date.new(2026, 4, 1), status: 'in_progress')
        described_class.new(task, { due_date: Date.new(2026, 4, 1) }).call
        remaining = task.task_occurrences.pluck(:occurrence_date)
        expect(remaining).to eq([ Date.new(2026, 4, 1) ])
      end
    end
  end
end
