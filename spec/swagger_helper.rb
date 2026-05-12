require 'rails_helper'

RSpec.configure do |config|
  config.swagger_root = Rails.root.join('swagger').to_s

  config.swagger_docs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Task Tracker API',
        version: 'v1',
        description: 'API for medical personnel task tracker'
      },
      paths: {},
      components: {
        schemas: {
          Error: {
            type: :object,
            properties: {
              error: { type: :string }
            }
          },
          Errors: {
            type: :object,
            properties: {
              errors: { type: :array, items: { type: :string } }
            }
          },
          Tag: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              system: { type: :boolean },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[id name system]
          },
          Task: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              description: { type: :string, nullable: true },
              status: { type: :string, enum: TaskStatuses::STATUSES },
              due_date: { type: :string, format: :date, nullable: true },
              starts_on: { type: :string, format: :date, nullable: true },
              ends_on: { type: :string, format: :date, nullable: true },
              recurrence_type: {
                type: :string,
                enum: Task::RECURRENCE_TYPES,
                nullable: true
              },
              recurrence_params: { type: :object },
              tags: { type: :array, items: { '$ref' => '#/components/schemas/Tag' } },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[id title status]
          },
          Occurrence: {
            type: :object,
            properties: {
              id: { type: :integer, nullable: true },
              task_id: { type: :integer },
              occurrence_date: { type: :string, format: :date },
              status: { type: :string, enum: TaskStatuses::STATUSES },
              title: { type: :string },
              description: { type: :string, nullable: true },
              cancelled: { type: :boolean },
              recurrence_type: { type: :string, nullable: true },
              tags: { type: :array, items: { '$ref' => '#/components/schemas/Tag' } }
            },
            required: %w[task_id occurrence_date status title cancelled]
          }
        }
      },
      servers: [{ url: 'http://localhost:3000' }]
    }
  }

  config.swagger_format = :yaml
end
