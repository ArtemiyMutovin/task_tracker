require 'swagger_helper'

RSpec.describe 'api/v1/occurrences', type: :request do
  path '/api/v1/occurrences' do
    get 'List occurrences for a date range' do
      tags 'Occurrences'
      produces 'application/json'
      parameter name: :date_from, in: :query, type: :string, format: :date, required: true
      parameter name: :date_to, in: :query, type: :string, format: :date, required: true
      parameter name: :status, in: :query, type: :string, required: false,
                enum: TaskStatuses::STATUSES
      parameter name: :tag_ids, in: :query, type: :array, items: { type: :integer },
                required: false, description: 'Filter by tag IDs'
      parameter name: :include_cancelled, in: :query, type: :boolean, required: false,
                description: 'Include cancelled occurrences (default: false)'

      response '200', 'List of occurrences (expands recurring tasks)' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Occurrence' }
        let(:date_from) { '2025-01-01' }
        let(:date_to)   { '2025-01-07' }
        let!(:task) do
          create(:task, :daily,
                 starts_on: Date.new(2025, 1, 1),
                 recurrence_params: { 'interval' => 1 })
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(7)
        end
      end

      response '400', 'Missing date_from or date_to' do
        schema '$ref' => '#/components/schemas/Error'
        let(:date_from) { nil }
        let(:date_to)   { nil }
        run_test!
      end

      response '400', 'Date range exceeds maximum' do
        schema '$ref' => '#/components/schemas/Error'
        let(:date_from) { '2025-01-01' }
        let(:date_to)   { '2026-06-01' }
        run_test!
      end

      response '400', 'Invalid date format' do
        schema '$ref' => '#/components/schemas/Error'
        let(:date_from) { 'not-a-date' }
        let(:date_to)   { '2025-01-07' }
        run_test!
      end
    end
  end

  path '/api/v1/tasks/{task_id}/occurrences/{date}' do
    parameter name: :task_id, in: :path, type: :integer
    parameter name: :date, in: :path, type: :string, format: :date,
              description: 'The specific occurrence date (YYYY-MM-DD)'

    patch 'Update a specific occurrence' do
      tags 'Occurrences'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          occurrence: {
            type: :object,
            properties: {
              status: { type: :string, enum: TaskStatuses::STATUSES },
              title: { type: :string },
              description: { type: :string },
              cancelled: { type: :boolean }
            }
          }
        }
      }

      response '200', 'Occurrence updated' do
        schema '$ref' => '#/components/schemas/Occurrence'
        let(:task)    { create(:task, :daily, starts_on: Date.new(2025, 1, 1), recurrence_params: { 'interval' => 1 }) }
        let(:task_id) { task.id }
        let(:date)    { '2025-01-03' }
        let(:body)    { { occurrence: { status: 'done' } } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('done')
          expect(data['occurrence_date']).to eq('2025-01-03')
        end
      end

      response '422', 'Validation failed' do
        schema '$ref' => '#/components/schemas/Errors'
        let(:task)    { create(:task, :daily, starts_on: Date.new(2025, 1, 1), recurrence_params: { 'interval' => 1 }) }
        let(:task_id) { task.id }
        let(:date)    { '2025-01-03' }
        let(:body)    { { occurrence: { status: 'invalid_status' } } }
        run_test!
      end

      response '404', 'Task not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:task_id) { 0 }
        let(:date)    { '2025-01-03' }
        let(:body)    { { occurrence: { status: 'done' } } }
        run_test!
      end
    end

    delete 'Reset a specific occurrence to template defaults' do
      tags 'Occurrences'

      response '204', 'Occurrence reset' do
        let(:task)    { create(:task, :daily, starts_on: Date.new(2025, 1, 1), recurrence_params: { 'interval' => 1 }) }
        let(:task_id) { task.id }
        let(:date)    { '2025-01-03' }
        before { create(:task_occurrence, task: task, occurrence_date: Date.new(2025, 1, 3), status: 'done') }
        run_test!
      end

      response '404', 'No override exists for this date' do
        schema '$ref' => '#/components/schemas/Error'
        let(:task)    { create(:task, :daily, starts_on: Date.new(2025, 1, 1), recurrence_params: { 'interval' => 1 }) }
        let(:task_id) { task.id }
        let(:date)    { '2025-01-03' }
        run_test!
      end

      response '404', 'Task not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:task_id) { 0 }
        let(:date)    { '2025-01-03' }
        run_test!
      end
    end
  end
end
