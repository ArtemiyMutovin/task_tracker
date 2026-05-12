require 'rails_helper'

RSpec.describe Recurrence::SpecificDatesGenerator do
  let(:dates_list) { ['2024-01-05', '2024-01-15', '2024-02-10'] }
  let(:task) do
    build(:task, :specific_dates,
          starts_on: Date.new(2024, 1, 1),
          recurrence_params: { 'dates' => dates_list })
  end
  let(:generator) { described_class.new(task) }

  describe '#dates_in_range' do
    it 'returns only dates within the range' do
      dates = generator.dates_in_range(Date.new(2024, 1, 1), Date.new(2024, 1, 31))
      expect(dates).to eq([Date.new(2024, 1, 5), Date.new(2024, 1, 15)])
    end

    it 'returns dates sorted' do
      task = build(:task, :specific_dates,
                   starts_on: Date.new(2024, 1, 1),
                   recurrence_params: { 'dates' => ['2024-01-15', '2024-01-05'] })
      dates = described_class.new(task).dates_in_range(Date.new(2024, 1, 1), Date.new(2024, 1, 31))
      expect(dates).to eq(dates.sort)
    end

    it 'returns empty when no dates in range' do
      dates = generator.dates_in_range(Date.new(2024, 3, 1), Date.new(2024, 3, 31))
      expect(dates).to be_empty
    end

    it 'respects starts_on' do
      task = build(:task, :specific_dates,
                   starts_on: Date.new(2024, 1, 10),
                   recurrence_params: { 'dates' => ['2024-01-05', '2024-01-15'] })
      dates = described_class.new(task).dates_in_range(Date.new(2024, 1, 1), Date.new(2024, 1, 31))
      expect(dates).to eq([Date.new(2024, 1, 15)])
    end
  end
end
