class NotesController < ApplicationController
  before_action :set_notable, only: :create
  before_action :set_note, only: %i[ edit update destroy ]

  def create
    note = @notable.notes.new(note_params.merge(author: current_user))
    if note.save
      redirect_to @notable, notice: t("flash.created", model: Note.model_name.human)
    else
      redirect_to @notable, alert: note.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    if @note.update(note_params)
      redirect_to @note.notable, notice: t("flash.updated", model: Note.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @note.destroy
    redirect_to @note.notable, notice: t("flash.destroyed", model: Note.model_name.human), status: :see_other
  end

  private
    def set_notable
      @notable =
        if params[:client_id] then Client.find(params[:client_id])
        elsif params[:vehicle_id] then Vehicle.find(params[:vehicle_id])
        elsif params[:lead_id] then Lead.find(params[:lead_id])
        else WorkOrder.find(params[:work_order_id])
        end
    end

    def set_note
      @note = Note.find(params[:id])
      redirect_to @note.notable, alert: t("flash.forbidden") unless @note.editable_by?(current_user)
    end

    def note_params
      params.expect(note: [ :body, :private ])
    end
end
