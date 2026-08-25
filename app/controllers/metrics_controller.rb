class MetricsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_metric, except: %i[index new create]

  def index
    @metrics = current_user.metrics
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
