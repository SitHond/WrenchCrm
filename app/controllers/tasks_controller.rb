class TasksController < ApplicationController
  before_action :set_task, only: %i[ edit update destroy toggle ]

  def index
    scope = Task.includes(:assignee, :subject)
    scope = scope.for_user(current_user) unless params[:who] == "all"
    scope = case params[:state]
    when "done" then scope.done.order(done_at: :desc)
    else scope.open.by_due
    end
    @pagy, @tasks = pagy(scope, limit: 50)
  end

  def create
    task = Task.new(task_params)
    if task.save
      redirect_back fallback_location: tasks_path, notice: t("tasks.created")
    else
      redirect_back fallback_location: tasks_path, alert: task.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    if @task.update(task_params)
      redirect_to tasks_path, notice: t("flash.updated", model: Task.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle
    @task.toggle!
    redirect_back fallback_location: tasks_path, status: :see_other
  end

  def destroy
    if @task.deletable_by?(current_user)
      @task.destroy
      redirect_back fallback_location: tasks_path, notice: t("flash.destroyed", model: Task.model_name.human), status: :see_other
    else
      redirect_back fallback_location: tasks_path, alert: t("flash.forbidden"), status: :see_other
    end
  end

  private
    def set_task
      @task = Task.find(params[:id])
    end

    def task_params
      permitted = params.expect(task: [ :title, :description, :assignee_id, :due_on, :subject_type, :subject_id ])
      permitted.delete(:subject_type) unless Task::SUBJECT_TYPES.include?(permitted[:subject_type])
      permitted
    end
end
