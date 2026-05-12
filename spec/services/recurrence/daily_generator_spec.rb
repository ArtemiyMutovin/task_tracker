require 'rails_helper'

RSpec.describe Recurrence::DailyGenerator do
  let(:base_date) { Date.new(2024, 1, 1) }

  def task_with(starts_on:, interval:, ends_on: nil)
    build(:task, :daily, starts_on: starts_on, ends_on: ends_on,
                         recurrence_params: { 'interval' => interval })
  end

  subject(:generator) { described_class.new(task) }

  describe '#dates_in_range' do
    context 'every day (interval: 1)' do
      let(:task) { task_with(starts_on: base_date, interval: 1) }

      it 'returns all days in range' do
        dates = generator.dates_in_range(base_date, base_date + 3)
        expect(dates).to eq([base_date, base_date + 1, base_date + 2, base_date + 3])
      end

      it 'excludes dates before starts_on' do
        dates = generator.dates_in_range(base_date - 5, base_date + 2)
        expect(dates).not_to include(base_date - 1)
        expect(dates).to include(base_date)
      end
    end

    context 'every 2 days (interval: 2)' do
      let(:task) { task_with(starts_on: base_date, interval: 2) }

      it 'returns every other day' do
        dates = generator.dates_in_range(base_date, base_date + 6)
        expect(dates).to eq([base_date, base_date + 2, base_date + 4, base_date + 6])
      end

      it 'aligns correctly when range starts mid-cycle' do
        # starts_on: Jan 1, query from Jan 4 → next aligned date is Jan 5
        dates = generator.dates_in_range(base_date + 3, base_date + 7)
        expect(dates).to eq([base_date + 4, base_date + 6])
      end
    end

    context 'with ends_on' do
      let(:task) { task_with(starts_on: base_date, interval: 1, ends_on: base_date + 2) }

      it 'stops at ends_on' do
        dates = generator.dates_in_range(base_date, base_date + 10)
        expect(dates).to eq([base_date, base_date + 1, base_date + 2])
      end
    end

    context 'when range is outside recurrence window' do
      let(:task) { task_with(starts_on: base_date + 10, interval: 1) }

      it 'returns empty array' do
        dates = generator.dates_in_range(base_date, base_date + 5)
        expect(dates).to be_empty
      end
    end
  end
end
