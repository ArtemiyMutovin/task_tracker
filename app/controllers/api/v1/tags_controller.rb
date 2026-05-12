module Api
  module V1
    class TagsController < BaseController
      def index
        render json: TagBlueprint.render(Tag.order(:name))
      end

      def show
        render json: TagBlueprint.render(tag)
      end

      def create
        new_tag = Tag.new(tag_params)
        if new_tag.save
          render json: TagBlueprint.render(new_tag), status: :created
        else
          render json: { errors: new_tag.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if tag.system?
          render json: { error: "System tags cannot be deleted" }, status: :forbidden
        else
          tag.destroy!
          head :no_content
        end
      end

      private

      def tag
        @tag ||= Tag.find(params[:id])
      end

      def tag_params
        params.require(:tag).permit(:name)
      end
    end
  end
end
