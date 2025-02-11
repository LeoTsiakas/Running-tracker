class MetricsController < ApplicationController
  def index
    @metrics = Metrics.all
  end

  def new
    @metric = Metrics.new
  end
  
  def edit
    @metric = Metrics.find(params[:id])
  end

  def update
    @metric = Metrics.find(params[:id])
    if @metric.update(metrics_params)
      redirect_to root_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @metric = Metrics.new(metrics_params)
    if @metric.save
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def metrics_params
      params.require(:metric).permit(:time, :distance)
    end
end
