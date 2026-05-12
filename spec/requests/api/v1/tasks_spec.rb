require 'swagger_helper'

RSpec.describe 'api/v1/tasks', type: :request do
  path '/api/v1/tasks' do
    get 'List tasks' do
      tags 'Tasks'
      produces 'application/json'
      parameter name: :date_from, in: :query, type: :string, format: :date, required: false,
                description: 'Filter by date range start (YYYY-MM-DD). For one-time tasks only.'
      parameter name: :date_to, in: :query, type: :string, format: :date, required: false,
                description: 'Filter by date range end (YYYY-MM-DD). For one-time tasks only.'
      parameter name: :status, in: :query, type: :string, required: false,
                enum: TaskStatuses::STATUSES, description: 'Filter by status'

      response '200', 'List of tasks' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Task' }
        let!(:task) { create(:task) }
        run_test!
      end

      response '200', 'Tasks filtered by date range' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Task' }
        let!(:task) { create(:task, due_date: Date.today) }
        let(:date_from) { Date.today.to_s }
        let(:date_to) { Date.today.to_s }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.map { |t| t['id'] }).to include(task.id)
        end
      end
    end

    post 'Create a task' do
      tags 'Tasks'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          task: {
            type: :object,
            properties: {
              title: { type: :string },
              description: { type: :string },
              status: { type: :string, enum: TaskStatuses::STATUSES },
              due_date: { type: :string, format: :date }
            },
            required: %w[title due_date]
          }
        }
      }

      response '201', 'Task created' do
        schema '$ref' => '#/components/schemas/Task'
        let(:body) { { task: { title: 'New task', due_date: Date.today.to_s } } }
        run_test!
      end

      response '422', 'Validation failed' do
        schema '$ref' => '#/components/schemas/Errors'
        let(:body) { { task: { title: '' } } }
        run_test!
      end
    end
  end

  path '/api/v1/tasks/{id}' do
    parameter name: :id, in: :path, type: :integer

    get 'Get a task' do
      tags 'Tasks'
      produces 'application/json'

      response '200', 'Task found' do
        schema '$ref' => '#/components/schemas/Task'
        let(:id) { create(:task).id }
        run_test!
      end

      response '404', 'Task not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 0 }
        run_test!
      end
    end

    patch 'Update a task' do
      tags 'Tasks'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          task: {
            type: :object,
            properties: {
              title: { type: :string },
              description: { type: :string },
              status: { type: :string, enum: TaskStatuses::STATUSES },
              due_date: { type: :string, format: :date }
            }
          }
        }
      }

      response '200', 'Task updated' do
        schema '$ref' => '#/components/schemas/Task'
        let(:id) { create(:task).id }
        let(:body) { { task: { title: 'Updated', status: 'done' } } }
        run_test!
      end

      response '422', 'Validation failed' do
        schema '$ref' => '#/components/schemas/Errors'
        let(:id) { create(:task).id }
        let(:body) { { task: { title: '' } } }
        run_test!
      end
    end

    delete 'Delete a task' do
      tags 'Tasks'

      response '204', 'Task deleted' do
        let(:id) { create(:task).id }
        run_test!
      end

      response '404', 'Task not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 0 }
        run_test!
      end
    end
  end

  path '/api/v1/tasks/{task_id}/tags' do
    parameter name: :task_id, in: :path, type: :integer

    post 'Add tag to task' do
      tags 'Task Tags'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: { tag_id: { type: :integer } },
        required: [ 'tag_id' ]
      }

      response '200', 'Tag added' do
        schema '$ref' => '#/components/schemas/Task'
        let(:task_id) { create(:task).id }
        let(:body) { { tag_id: create(:tag).id } }
        run_test!
      end

      response '404', 'Task or tag not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:task_id) { create(:task).id }
        let(:body) { { tag_id: 0 } }
        run_test!
      end
    end
  end

  path '/api/v1/tasks/{task_id}/tags/{id}' do
    parameter name: :task_id, in: :path, type: :integer
    parameter name: :id, in: :path, type: :integer, description: 'Tag ID'

    delete 'Remove tag from task' do
      tags 'Task Tags'

      response '204', 'Tag removed' do
        let(:task) { create(:task) }
        let(:tag) { create(:tag) }
        let(:task_id) { task.id }
        let(:id) { tag.id }
        before { task.tags << tag }
        run_test!
      end

      response '404', 'Tag not associated with task' do
        schema '$ref' => '#/components/schemas/Error'
        let(:task_id) { create(:task).id }
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
