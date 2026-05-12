module Api
  module V1
    class TaskTagsController < BaseController
      def create
        tag = Tag.find(tag_id_param)
        TaskTag.find_or_create_by!(task: task, tag: tag)
        render json: TaskBlueprint.render(task.reload, view: :with_tags)
      rescue ActiveRecord::RecordNotUnique
        render json: TaskBlueprint.render(task.reload, view: :with_tags)
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def destroy
        tag = task.tags.find(params[:id])
        task.tags.delete(tag)
        head :no_content
      end

      private

      def task
        @task ||= Task.find(params[:task_id])
      end

      def tag_id_param
        params.require(:tag_id)
      end
    end
  end
end
