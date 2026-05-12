module Api
  module V1
    class TaskOccurrencesController < BaseController
      MAX_OCCURRENCE_WINDOW_DAYS = 366

      def index
        unless date_range_present?
          return render json: { error: "date_from and date_to are required" }, status: :bad_request
        end

        date_from = Date.iso8601(params[:date_from])
        date_to   = Date.iso8601(params[:date_to])

        if (date_to - date_from).to_i > MAX_OCCURRENCE_WINDOW_DAYS
          return render json: {
            error: "Date range cannot exceed #{MAX_OCCURRENCE_WINDOW_DAYS} days"
          }, status: :bad_request
        end

        occurrences = Occurrences::ListService.new(
          date_from: date_from,
          date_to: date_to,
          status: params[:status],
          tag_ids: params[:tag_ids],
          include_cancelled: include_cancelled?
        ).call

        render json: OccurrenceBlueprint.render(occurrences)
      rescue Date::Error
        render json: { error: "Invalid date format. Use YYYY-MM-DD" }, status: :bad_request
      end

      def update
        date   = Date.iso8601(params[:date])
        result = Occurrences::UpdateService.new(task, date, occurrence_params).call
        if result.success?
          render json: OccurrenceBlueprint.render(result.object)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      rescue Date::Error
        render json: { error: "Invalid date format. Use YYYY-MM-DD" }, status: :bad_request
      end

      def destroy
        date       = Date.iso8601(params[:date])
        occurrence = task.task_occurrences.find_by(occurrence_date: date)
        return render json: { error: "No override exists for this date" }, status: :not_found unless occurrence

        occurrence.destroy!
        head :no_content
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

      def include_cancelled?
        params.fetch(:include_cancelled, 'false').to_s != 'false'
      end
    end
  end
end
