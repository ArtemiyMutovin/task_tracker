require 'rails_helper'

RSpec.describe Task, type: :model do
  subject(:task) { build(:task) }

  describe 'associations' do
    it { should have_many(:task_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:task_tags) }
    it { should have_many(:task_occurrences).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_inclusion_of(:status).in_array(TaskStatuses::STATUSES) }
    it { should validate_inclusion_of(:recurrence_type).in_array(Task::RECURRENCE_TYPES).allow_nil }

    context 'non-recurring task' do
      it 'requires due_date' do
        task = build(:task, due_date: nil)
        expect(task).not_to be_valid
        expect(task.errors[:due_date]).to include("can't be blank")
      end

      it 'is valid with due_date' do
        task = build(:task, due_date: Date.today)
        expect(task).to be_valid
      end
    end

    context 'recurring task' do
      it 'requires starts_on' do
        task = build(:task, :daily, starts_on: nil)
        expect(task).not_to be_valid
        expect(task.errors[:starts_on]).to include("can't be blank")
      end

      context 'daily recurrence' do
        it 'requires positive integer interval' do
          task = build(:task, :daily, recurrence_params: { 'interval' => 0 })
          expect(task).not_to be_valid
        end

        it 'is valid with interval: 1' do
          task = build(:task, :daily, recurrence_params: { 'interval' => 1 })
          expect(task).to be_valid
        end
      end

      context 'monthly recurrence' do
        it 'requires day between 1 and 31' do
          task = build(:task, :monthly, recurrence_params: { 'day' => 32 })
          expect(task).not_to be_valid
        end

        it 'is valid with day: 15' do
          task = build(:task, :monthly, recurrence_params: { 'day' => 15 })
          expect(task).to be_valid
        end
      end

      context 'specific_dates recurrence' do
        it 'requires non-empty dates array' do
          task = build(:task, :specific_dates, recurrence_params: { 'dates' => [] })
          expect(task).not_to be_valid
        end

        it 'requires valid date strings' do
          task = build(:task, :specific_dates, recurrence_params: { 'dates' => ['not-a-date'] })
          expect(task).not_to be_valid
        end
      end

      context 'even_odd recurrence' do
        it 'requires parity to be even or odd' do
          task = build(:task, :even_days, recurrence_params: { 'parity' => 'bad' })
          expect(task).not_to be_valid
        end
      end
    end
  end

  describe '#recurring?' do
    it 'returns false for one-time tasks' do
      expect(build(:task)).not_to be_recurring
    end

    it 'returns true for recurring tasks' do
      expect(build(:task, :daily)).to be_recurring
    end
  end

  describe 'scopes' do
    let!(:one_time) { create(:task, due_date: Date.today) }
    let!(:recurring) { create(:task, :daily) }

    it '.recurring returns only recurring tasks' do
      expect(Task.recurring).to include(recurring)
      expect(Task.recurring).not_to include(one_time)
    end

    it '.one_time returns only non-recurring tasks' do
      expect(Task.one_time).to include(one_time)
      expect(Task.one_time).not_to include(recurring)
    end

    describe '.with_due_date_in' do
      let!(:task_today) { create(:task, due_date: Date.today) }
      let!(:task_tomorrow) { create(:task, due_date: Date.today + 1) }
      let!(:task_past) { create(:task, due_date: Date.today - 10) }

      it 'returns tasks within the date range' do
        results = Task.with_due_date_in(Date.today, Date.today + 1)
        expect(results).to include(task_today, task_tomorrow)
        expect(results).not_to include(task_past)
      end
    end
  end
end
