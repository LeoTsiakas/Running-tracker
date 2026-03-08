class MetricsController < ApplicationController
  before_action :set_current_user
  before_action :set_metric, except: %i[index new create]
  before_action :require_user_logged_in

  def index
    @user = User.find_by(id: session[:user_id]) if session[:user_id]
    @metrics = @user.metrics if @user
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
    permitted = params.require(:metric).permit(:distance, :date, :user_id)

    if params[:metric][:duration_hours] && params[:metric][:duration_minutes] && params[:metric][:duration_seconds]
      hours = params[:metric][:duration_hours].to_i
      minutes = params[:metric][:duration_minutes].to_i
      seconds = params[:metric][:duration_seconds].to_i
    end
    
    permitted[:time] = hours * 3600 + minutes * 60 + seconds
    permitted
  end

  def set_metric
    @metric = Metric.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end
end
