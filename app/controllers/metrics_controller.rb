class MetricsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_metric, only: %i[show edit update destroy]

  def index
    date_range = params[:selected_date_range]

    if params[:selected_date_range].present?
      start_at, end_at = DateParser.parse_date_range(date_range, current_user)

      @metrics = Metric.search('*', '', {
                                 filter_by: "user_id:=#{current_user.id} && date:[#{start_at.to_i}..#{end_at.to_i}]",
                                 sort_by: 'date:desc',
                                 per_page: params[:per_page] || 250,
                                 page: params[:page] || 1
                               })
    else
      @metrics = Metric.search('*', '', {
                                 filter_by: "user_id:=#{current_user.id}",
                                 sort_by: 'date:desc',
                                 per_page: params[:per_page] || 250,
                                 page: params[:page] || 1
                               })
    end
  end

  def show
  end

  def new
    @metric = current_user.metrics.new
  end

  def show
  end

  def new
    @metric = current_user.metrics.new
  end

  def edit
  end

  def update
    if @metric.update(metrics_params)
      redirect_to root_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @metric = current_user.metrics.new(metrics_params)
    if @metric.save
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @metric.destroy
    redirect_to root_path
  end

  private

  def metrics_params
    permitted = params.require(:metric).permit(:distance, :date)

    if params[:metric][:duration_hours] && params[:metric][:duration_minutes] && params[:metric][:duration_seconds]
      hours = params[:metric][:duration_hours].to_i
      minutes = params[:metric][:duration_minutes].to_i
      seconds = params[:metric][:duration_seconds].to_i
    end

    permitted[:time] = hours * 3600 + minutes * 60 + seconds
    permitted
  end

  def set_metric
    @metric = current_user.metrics.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end
end
