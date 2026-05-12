require 'rails_helper'

RSpec.describe Recurrence::MonthlyGenerator do
  def task_with(starts_on:, day:, ends_on: nil)
    build(:task, :monthly, starts_on: starts_on, ends_on: ends_on,
                           recurrence_params: { 'day' => day })
  end

  describe '#dates_in_range' do
    context 'on the 15th of each month' do
      let(:task) { task_with(starts_on: Date.new(2024, 1, 1), day: 15) }
      let(:generator) { described_class.new(task) }

      it 'returns 15th of each month in range' do
        dates = generator.dates_in_range(Date.new(2024, 1, 1), Date.new(2024, 3, 31))
        expect(dates).to eq([Date.new(2024, 1, 15), Date.new(2024, 2, 15), Date.new(2024, 3, 15)])
      end

      it 'excludes the 15th if it is before starts_on' do
        task = task_with(starts_on: Date.new(2024, 1, 20), day: 15)
        generator = described_class.new(task)
        dates = generator.dates_in_range(Date.new(2024, 1, 1), Date.new(2024, 2, 28))
        expect(dates).to eq([Date.new(2024, 2, 15)])
      end
    end

    context 'on the 31st (short months)' do
      let(:task) { task_with(starts_on: Date.new(2024, 1, 1), day: 31) }
      let(:generator) { described_class.new(task) }

      it 'clamps to last day of month for short months' do
        dates = generator.dates_in_range(Date.new(2024, 2, 1), Date.new(2024, 2, 29))
        expect(dates).to eq([Date.new(2024, 2, 29)])
      end
    end

    context 'with ends_on' do
      let(:task) { task_with(starts_on: Date.new(2024, 1, 1), day: 1, ends_on: Date.new(2024, 2, 28)) }
      let(:generator) { described_class.new(task) }

      it 'stops at ends_on month' do
        dates = generator.dates_in_range(Date.new(2024, 1, 1), Date.new(2024, 5, 31))
        expect(dates).to eq([Date.new(2024, 1, 1), Date.new(2024, 2, 1)])
      end
    end
  end
end
