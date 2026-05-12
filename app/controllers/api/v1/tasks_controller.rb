module Api
  module V1
    class TasksController < BaseController
      def index
        tasks = Task.includes(:tags).order(created_at: :desc)
        tasks = tasks.where(status: params[:status]) if params[:status].present?

        if date_range_params?
          date_from = Date.iso8601(params[:date_from])
          date_to   = Date.iso8601(params[:date_to])
          tasks = tasks.with_due_date_in(date_from, date_to)
        end

        page     = [ params.fetch(:page, 1).to_i, 1 ].max
        per_page = [ [ params.fetch(:per_page, Pagy::OPTIONS[:limit]).to_i, 1 ].max,
                    Pagy::OPTIONS[:max_limit] ].min

        pagy  = Pagy::Offset.new(count: tasks.count, page: page, limit: per_page)
        tasks = pagy.records(tasks)

        response.set_header("X-Total-Count", pagy.count.to_s)
        response.set_header("X-Total-Pages", pagy.last.to_s)
        response.set_header("X-Page", pagy.page.to_s)
        response.set_header("X-Per-Page", pagy.limit.to_s)

        render json: TaskBlueprint.render(tasks, view: :with_tags)
      rescue Date::Error
        render json: { error: "Invalid date format. Use YYYY-MM-DD" }, status: :bad_request
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
        base = params.require(:task).permit(
          :title, :description, :status, :due_date,
          :starts_on, :ends_on, :recurrence_type
        )
        base[:recurrence_params] = permitted_recurrence_params if params.dig(:task, :recurrence_params)
        base
      end

      # Whitelist recurrence_params keys by the declared recurrence_type.
      # Falls back to the existing task type for partial PATCH updates.
      def permitted_recurrence_params
        rp = params[:task][:recurrence_params]
        rt = params.dig(:task, :recurrence_type) || @task&.recurrence_type
        case rt
        when "daily"          then rp.permit(:interval).to_h
        when "monthly"        then rp.permit(:day).to_h
        when "even_odd"       then rp.permit(:parity).to_h
        when "specific_dates" then rp.permit(dates: []).to_h
        else                       {}
        end
      end

      def date_range_params?
        params[:date_from].present? && params[:date_to].present?
      end
    end
  end
end
