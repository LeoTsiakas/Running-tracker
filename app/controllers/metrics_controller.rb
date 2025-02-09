class MetricsController < ApplicationController
  def index
    @metrics = Metrics.all
  end

  def new
    @metric = Metrics.new
  end

  def create
    @metric = Metrics.new(metrics_params)
    if @metric.save
      redirect_to root_path
    else
      render :new
    end
  end

  private
    def metrics_params
      params.require(:metric).permit(:time, :distance)
    end
end
