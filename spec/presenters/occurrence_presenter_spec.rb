require 'rails_helper'

RSpec.describe OccurrencePresenter do
  let(:task) { build_stubbed(:task, title: 'Template title', description: 'Template description') }
  let(:date) { Date.new(2025, 1, 5) }

  describe '#title and #description' do
    it 'falls back to the template when no override exists' do
      presenter = described_class.new(task: task, occurrence_date: date)
      expect(presenter.title).to eq('Template title')
      expect(presenter.description).to eq('Template description')
    end

    it 'falls back to the template when override fields are nil' do
      override = build_stubbed(:task_occurrence, task: task, occurrence_date: date, title: nil, description: nil)
      presenter = described_class.new(task: task, occurrence_date: date, occurrence: override)
      expect(presenter.title).to eq('Template title')
      expect(presenter.description).to eq('Template description')
    end

    it 'preserves an explicit empty-string override' do
      override = build_stubbed(:task_occurrence, task: task, occurrence_date: date, title: '', description: '')
      presenter = described_class.new(task: task, occurrence_date: date, occurrence: override)
      expect(presenter.title).to eq('')
      expect(presenter.description).to eq('')
    end

    it 'uses non-empty override values' do
      override = build_stubbed(:task_occurrence, task: task, occurrence_date: date, title: 'Custom', description: 'Custom desc')
      presenter = described_class.new(task: task, occurrence_date: date, occurrence: override)
      expect(presenter.title).to eq('Custom')
      expect(presenter.description).to eq('Custom desc')
    end
  end
end
