require 'swagger_helper'

RSpec.describe 'api/v1/tags', type: :request do
  path '/api/v1/tags' do
    get 'List all tags' do
      tags 'Tags'
      produces 'application/json'

      response '200', 'List of tags' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Tag' }
        let!(:tag) { create(:tag) }
        run_test!
      end
    end

    post 'Create a tag' do
      tags 'Tags'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: { tag: { type: :object, properties: { name: { type: :string } }, required: [ 'name' ] } }
      }

      response '201', 'Tag created' do
        schema '$ref' => '#/components/schemas/Tag'
        let(:body) { { tag: { name: 'новый тег' } } }
        run_test!
      end

      response '422', 'Validation failed' do
        schema '$ref' => '#/components/schemas/Errors'
        let(:body) { { tag: { name: '' } } }
        run_test!
      end
    end
  end

  path '/api/v1/tags/{id}' do
    parameter name: :id, in: :path, type: :integer

    get 'Get a tag' do
      tags 'Tags'
      produces 'application/json'

      response '200', 'Tag found' do
        schema '$ref' => '#/components/schemas/Tag'
        let(:id) { create(:tag).id }
        run_test!
      end

      response '404', 'Tag not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 0 }
        run_test!
      end
    end

    delete 'Delete a tag' do
      tags 'Tags'

      response '204', 'Tag deleted' do
        let(:id) { create(:tag).id }
        run_test!
      end

      response '403', 'System tag cannot be deleted' do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { create(:tag, :system, name: 'отчетность').id }
        run_test!
      end

      response '404', 'Tag not found' do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
