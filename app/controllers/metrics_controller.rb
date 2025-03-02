class MetricsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_metric, except: %i[index new create]

  def index
    @metrics = Metric.all
  end

  def show
  end

  def new
    @metric = Metric.new
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
    @metric = Metric.new(metrics_params)
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
    params.require(:metric).permit(:time, :distance, :date)
  end

  def set_metric
    @metric = Metric.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end
end
