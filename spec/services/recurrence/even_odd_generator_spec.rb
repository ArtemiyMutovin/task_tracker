require 'rails_helper'

RSpec.describe Recurrence::EvenOddGenerator do
  let(:start_of_month) { Date.new(2024, 1, 1) }

  def task_with(parity:, starts_on: start_of_month)
    build(:task, :even_days, starts_on: starts_on,
                              recurrence_params: { 'parity' => parity })
  end

  describe '#dates_in_range' do
    context 'even days' do
      let(:task) { task_with(parity: 'even') }
      let(:generator) { described_class.new(task) }

      it 'returns only even calendar days' do
        dates = generator.dates_in_range(Date.new(2024, 1, 1), Date.new(2024, 1, 6))
        expect(dates.map(&:day)).to all(be_even)
        expect(dates.map(&:day)).to eq([2, 4, 6])
      end
    end

    context 'odd days' do
      let(:task) { task_with(parity: 'odd') }
      let(:generator) { described_class.new(task) }

      it 'returns only odd calendar days' do
        dates = generator.dates_in_range(Date.new(2024, 1, 1), Date.new(2024, 1, 6))
        expect(dates.map(&:day)).to all(be_odd)
        expect(dates.map(&:day)).to eq([1, 3, 5])
      end
    end

    context 'respects starts_on' do
      let(:task) { task_with(parity: 'even', starts_on: Date.new(2024, 1, 5)) }
      let(:generator) { described_class.new(task) }

      it 'does not return dates before starts_on' do
        dates = generator.dates_in_range(Date.new(2024, 1, 1), Date.new(2024, 1, 10))
        expect(dates.min).to be >= Date.new(2024, 1, 5)
      end
    end
  end
end
