require 'rails_helper'

RSpec.describe Task, type: :model do
  subject(:task) { build(:task) }

  describe 'associations' do
    it { should have_many(:task_tags).dependent(:delete_all) }
    it { should have_many(:tags).through(:task_tags) }
    it { should have_many(:task_occurrences).dependent(:delete_all) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(5000) }
    it { should validate_inclusion_of(:status).in_array(TaskStatuses::STATUSES) }
    it { should validate_inclusion_of(:recurrence_type).in_array(Task::RECURRENCE_TYPES).allow_nil }

    context 'non-recurring task' do
      it 'requires due_date' do
        task = build(:task, due_date: nil)
        expect(task).not_to be_valid
        expect(task.errors[:due_date]).to include("can't be blank")
      end

      it 'is valid with due_date' do
        expect(build(:task, due_date: Date.today)).to be_valid
      end
    end

    context 'recurring task' do
      it 'requires starts_on' do
        task = build(:task, :daily, starts_on: nil)
        expect(task).not_to be_valid
        expect(task.errors[:starts_on]).to include("can't be blank")
      end

      it 'rejects due_date presence' do
        task = build(:task, :daily, due_date: Date.today)
        expect(task).not_to be_valid
        expect(task.errors[:due_date]).to be_present
      end

      context 'daily recurrence' do
        it 'requires positive integer interval' do
          expect(build(:task, :daily, recurrence_params: { 'interval' => 0 })).not_to be_valid
        end

        it 'is valid with interval: 1' do
          expect(build(:task, :daily, recurrence_params: { 'interval' => 1 })).to be_valid
        end

        it 'rejects interval above the upper bound' do
          expect(build(:task, :daily, recurrence_params: { 'interval' => 999_999 })).not_to be_valid
        end
      end

      context 'monthly recurrence' do
        it 'requires day between 1 and 31' do
          expect(build(:task, :monthly, recurrence_params: { 'day' => 32 })).not_to be_valid
        end

        it 'is valid with day: 15' do
          expect(build(:task, :monthly, recurrence_params: { 'day' => 15 })).to be_valid
        end
      end

      context 'specific_dates recurrence' do
        it 'requires non-empty dates array' do
          expect(build(:task, :specific_dates, recurrence_params: { 'dates' => [] })).not_to be_valid
        end

        it 'requires valid ISO 8601 date strings' do
          expect(build(:task, :specific_dates, recurrence_params: { 'dates' => [ 'not-a-date' ] })).not_to be_valid
        end

        it 'rejects non-ISO formats like dd-mm-yyyy' do
          expect(build(:task, :specific_dates, recurrence_params: { 'dates' => [ '15-01-2025' ] })).not_to be_valid
        end

        it 'rejects dates arrays exceeding the maximum size' do
          big = (1..400).map { |i| (Date.new(2025, 1, 1) + i).to_s }
          expect(build(:task, :specific_dates, recurrence_params: { 'dates' => big })).not_to be_valid
        end
      end

      context 'even_odd recurrence' do
        it 'requires parity to be even or odd' do
          expect(build(:task, :even_days, recurrence_params: { 'parity' => 'bad' })).not_to be_valid
        end
      end
    end

    context 'ends_on validation' do
      it 'rejects ends_on before starts_on' do
        task = build(:task, :daily, starts_on: Date.new(2025, 6, 1), ends_on: Date.new(2025, 1, 1))
        expect(task).not_to be_valid
        expect(task.errors[:ends_on]).to be_present
      end

      it 'allows ends_on equal to starts_on' do
        task = build(:task, :daily, starts_on: Date.new(2025, 1, 1), ends_on: Date.new(2025, 1, 1))
        expect(task).to be_valid
      end

      it 'allows ends_on after starts_on' do
        task = build(:task, :daily, starts_on: Date.new(2025, 1, 1), ends_on: Date.new(2025, 12, 31))
        expect(task).to be_valid
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
      let!(:task_today)    { create(:task, due_date: Date.today) }
      let!(:task_tomorrow) { create(:task, due_date: Date.today + 1) }
      let!(:task_past)     { create(:task, due_date: Date.today - 10) }

      it 'returns tasks within the date range' do
        results = Task.with_due_date_in(Date.today, Date.today + 1)
        expect(results).to include(task_today, task_tomorrow)
        expect(results).not_to include(task_past)
      end
    end
  end
end
