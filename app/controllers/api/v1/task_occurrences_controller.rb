module Api
  module V1
    class TaskOccurrencesController < BaseController
      def index
        unless date_range_present?
          return render json: { error: "date_from and date_to are required" }, status: :bad_request
        end

        occurrences = Occurrences::ListService.new(
          date_from: Date.parse(params[:date_from]),
          date_to: Date.parse(params[:date_to]),
          status: params[:status],
          tag_ids: params[:tag_ids]
        ).call

        render json: OccurrenceBlueprint.render(occurrences)
      rescue Date::Error
        render json: { error: "Invalid date format. Use YYYY-MM-DD" }, status: :bad_request
      end

      def update
        result = Occurrences::UpdateService.new(task, Date.parse(params[:date]), occurrence_params).call
        if result.success?
          render json: OccurrenceBlueprint.render(result.object)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      rescue Date::Error
        render json: { error: "Invalid date format. Use YYYY-MM-DD" }, status: :bad_request
      end

      private

      def task
        @task ||= Task.find(params[:task_id])
      end

      def occurrence_params
        params.require(:occurrence).permit(:status, :title, :description, :cancelled)
      end

      def date_range_present?
        params[:date_from].present? && params[:date_to].present?
      end
    end
  end
end
