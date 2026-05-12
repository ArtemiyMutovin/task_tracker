module Api
  module V1
    class TasksController < BaseController
      def index
        tasks = Task.includes(:tags).order(created_at: :desc)
        tasks = tasks.where(status: params[:status]) if params[:status].present?
        tasks = tasks.with_due_date_in(Date.parse(params[:date_from]), Date.parse(params[:date_to])) if date_range_params?
        render json: TaskBlueprint.render(tasks, view: :with_tags)
      end

      def show
        render json: TaskBlueprint.render(task, view: :with_tags)
      end

      def create
        result = Tasks::CreateService.new(task_params).call
        if result.success?
          render json: TaskBlueprint.render(result.object, view: :with_tags), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def update
        result = Tasks::UpdateService.new(task, task_params).call
        if result.success?
          render json: TaskBlueprint.render(result.object, view: :with_tags)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        task.destroy!
        head :no_content
      end

      private

      def task
        @task ||= Task.find(params[:id])
      end

      def task_params
        params.require(:task).permit(
          :title, :description, :status, :due_date,
          :starts_on, :ends_on, :recurrence_type,
          recurrence_params: {}
        )
      end

      def date_range_params?
        params[:date_from].present? && params[:date_to].present?
      end
    end
  end
end
