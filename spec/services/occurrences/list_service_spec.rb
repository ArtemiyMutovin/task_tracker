require 'rails_helper'

RSpec.describe Occurrences::ListService do
  let(:date_from) { Date.new(2024, 1, 1) }
  let(:date_to)   { Date.new(2024, 1, 7) }

  subject(:service) { described_class.new(date_from: date_from, date_to: date_to) }

  describe '#call' do
    context 'with one-time tasks' do
      let!(:task_in_range)     { create(:task, due_date: Date.new(2024, 1, 3)) }
      let!(:task_out_of_range) { create(:task, due_date: Date.new(2024, 2, 1)) }

      it 'returns only tasks in range' do
        result = service.call
        task_ids = result.map(&:task_id)
        expect(task_ids).to include(task_in_range.id)
        expect(task_ids).not_to include(task_out_of_range.id)
      end

      it 'uses task status for one-time tasks' do
        task_in_range.update!(status: 'done')
        occurrence = service.call.find { |o| o.task_id == task_in_range.id }
        expect(occurrence.status).to eq('done')
      end

      it 'honors override for the one-time due_date' do
        create(:task_occurrence,
               task: task_in_range,
               occurrence_date: task_in_range.due_date,
               status: 'in_progress',
               title: 'Override title')
        occurrence = service.call.find { |o| o.task_id == task_in_range.id }
        expect(occurrence.status).to eq('in_progress')
        expect(occurrence.title).to eq('Override title')
      end

      it 'hides cancelled override for one-time task by default' do
        create(:task_occurrence, :cancelled_occurrence,
               task: task_in_range, occurrence_date: task_in_range.due_date)
        ids = service.call.map(&:task_id)
        expect(ids).not_to include(task_in_range.id)
      end
    end

    context 'with recurring tasks' do
      let!(:daily_task) do
        create(:task, :daily, starts_on: Date.new(2024, 1, 1), recurrence_params: { 'interval' => 1 })
      end

      it 'expands recurring task into 7 occurrences for a 7-day window' do
        dates = service.call.select { |o| o.task_id == daily_task.id }.map(&:occurrence_date)
        expect(dates.size).to eq(7)
      end

      it 'defaults occurrence status to pending' do
        occurrence = service.call.find { |o| o.task_id == daily_task.id }
        expect(occurrence.status).to eq('pending')
      end

      it 'applies override status from task_occurrences for that date only' do
        create(:task_occurrence, task: daily_task, occurrence_date: Date.new(2024, 1, 3), status: 'done')
        result = service.call
        jan3 = result.find { |o| o.task_id == daily_task.id && o.occurrence_date == Date.new(2024, 1, 3) }
        jan4 = result.find { |o| o.task_id == daily_task.id && o.occurrence_date == Date.new(2024, 1, 4) }
        expect(jan3.status).to eq('done')
        expect(jan4.status).to eq('pending')
      end

      it 'does not load task_occurrences outside the requested date range' do
        create(:task_occurrence, task: daily_task, occurrence_date: Date.new(2023, 12, 31), status: 'done')
        occurrences = daily_task.association(:task_occurrences)
        service.call
        preloaded_dates = occurrences.target.map(&:occurrence_date)
        expect(preloaded_dates).not_to include(Date.new(2023, 12, 31))
      end
    end

    context 'with status filter' do
      let!(:task_done)    { create(:task, :done, due_date: Date.new(2024, 1, 3)) }
      let!(:task_pending) { create(:task, due_date: Date.new(2024, 1, 4)) }

      it 'filters by status' do
        result = described_class.new(date_from: date_from, date_to: date_to, status: 'done').call
        task_ids = result.map(&:task_id)
        expect(task_ids).to include(task_done.id)
        expect(task_ids).not_to include(task_pending.id)
      end
    end

    context 'with tag filter' do
      let!(:tag)          { create(:tag) }
      let!(:tagged_task)  { create(:task, due_date: Date.new(2024, 1, 3), tags: [ tag ]) }
      let!(:untagged_task) { create(:task, due_date: Date.new(2024, 1, 4)) }

      it 'filters by tag_ids' do
        result = described_class.new(date_from: date_from, date_to: date_to, tag_ids: [ tag.id ]).call
        task_ids = result.map(&:task_id)
        expect(task_ids).to include(tagged_task.id)
        expect(task_ids).not_to include(untagged_task.id)
      end

      it 'handles comma-separated tag_ids string' do
        tag2 = create(:tag)
        task2 = create(:task, due_date: Date.new(2024, 1, 5), tags: [ tag2 ])
        result = described_class.new(
          date_from: date_from, date_to: date_to,
          tag_ids: [ "#{tag.id},#{tag2.id}" ]
        ).call
        task_ids = result.map(&:task_id)
        expect(task_ids).to include(tagged_task.id, task2.id)
      end
    end

    context 'with cancelled occurrences' do
      let!(:daily_task) do
        create(:task, :daily, starts_on: Date.new(2024, 1, 1), recurrence_params: { 'interval' => 1 })
      end

      before do
        create(:task_occurrence, :cancelled_occurrence, task: daily_task, occurrence_date: Date.new(2024, 1, 3))
      end

      it 'excludes cancelled occurrences by default' do
        result = service.call
        cancelled = result.find { |o| o.task_id == daily_task.id && o.occurrence_date == Date.new(2024, 1, 3) }
        expect(cancelled).to be_nil
        expect(result.size).to eq(6)
      end

      it 'includes cancelled occurrences when include_cancelled: true' do
        result = described_class.new(
          date_from: date_from, date_to: date_to, include_cancelled: true
        ).call
        expect(result.size).to eq(7)
        cancelled = result.find { |o| o.task_id == daily_task.id && o.occurrence_date == Date.new(2024, 1, 3) }
        expect(cancelled.cancelled).to be(true)
      end
    end
  end
end
