require 'rails_helper'

RSpec.describe Occurrences::ListService do
  let(:date_from) { Date.new(2024, 1, 1) }
  let(:date_to) { Date.new(2024, 1, 7) }

  subject(:service) { described_class.new(date_from: date_from, date_to: date_to) }

  describe '#call' do
    context 'with one-time tasks' do
      let!(:task_in_range) { create(:task, due_date: Date.new(2024, 1, 3)) }
      let!(:task_out_of_range) { create(:task, due_date: Date.new(2024, 2, 1)) }

      it 'returns only tasks in range' do
        result = service.call
        task_ids = result.map(&:task_id)
        expect(task_ids).to include(task_in_range.id)
        expect(task_ids).not_to include(task_out_of_range.id)
      end

      it 'uses task status' do
        task_in_range.update!(status: 'done')
        result = service.call
        occurrence = result.find { |o| o.task_id == task_in_range.id }
        expect(occurrence.status).to eq('done')
      end
    end

    context 'with recurring tasks' do
      let!(:daily_task) do
        create(:task, :daily,
               starts_on: Date.new(2024, 1, 1),
               recurrence_params: { 'interval' => 1 })
      end

      it 'expands recurring task into occurrences' do
        result = service.call
        dates = result.select { |o| o.task_id == daily_task.id }.map(&:occurrence_date)
        expect(dates.size).to eq(7)
      end

      it 'defaults occurrence status to pending' do
        result = service.call
        occurrence = result.find { |o| o.task_id == daily_task.id }
        expect(occurrence.status).to eq('pending')
      end

      it 'applies override status from task_occurrences' do
        create(:task_occurrence, task: daily_task,
               occurrence_date: Date.new(2024, 1, 3), status: 'done')
        result = service.call
        jan3 = result.find { |o| o.task_id == daily_task.id && o.occurrence_date == Date.new(2024, 1, 3) }
        expect(jan3.status).to eq('done')
      end

      it 'keeps other occurrences as pending' do
        create(:task_occurrence, task: daily_task,
               occurrence_date: Date.new(2024, 1, 3), status: 'done')
        result = service.call
        jan4 = result.find { |o| o.task_id == daily_task.id && o.occurrence_date == Date.new(2024, 1, 4) }
        expect(jan4.status).to eq('pending')
      end
    end

    context 'with status filter' do
      let!(:task_done) { create(:task, :done, due_date: Date.new(2024, 1, 3)) }
      let!(:task_pending) { create(:task, due_date: Date.new(2024, 1, 4)) }

      it 'filters by status' do
        result = described_class.new(date_from: date_from, date_to: date_to, status: 'done').call
        task_ids = result.map(&:task_id)
        expect(task_ids).to include(task_done.id)
        expect(task_ids).not_to include(task_pending.id)
      end
    end

    context 'with tag filter' do
      let!(:tag) { create(:tag) }
      let!(:tagged_task) { create(:task, due_date: Date.new(2024, 1, 3), tags: [tag]) }
      let!(:untagged_task) { create(:task, due_date: Date.new(2024, 1, 4)) }

      it 'filters by tag_ids' do
        result = described_class.new(date_from: date_from, date_to: date_to, tag_ids: [tag.id]).call
        task_ids = result.map(&:task_id)
        expect(task_ids).to include(tagged_task.id)
        expect(task_ids).not_to include(untagged_task.id)
      end
    end
  end
end
