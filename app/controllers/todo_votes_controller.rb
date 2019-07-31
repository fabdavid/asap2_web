class TodoVotesController < ApplicationController
  before_action :set_todo_vote, only: [:show, :edit, :update, :destroy]

  # GET /todo_votes
  # GET /todo_votes.json
  def index
    @todo_votes = TodoVote.all
  end

  # GET /todo_votes/1
  # GET /todo_votes/1.json
  def show
  end

  # GET /todo_votes/new
  def new
    @todo_vote = TodoVote.new
  end

  # GET /todo_votes/1/edit
  def edit
  end

  # POST /todo_votes
  # POST /todo_votes.json
  def create
    @todo_vote = TodoVote.new(todo_vote_params)

    respond_to do |format|
      if @todo_vote.save
        format.html { redirect_to @todo_vote, notice: 'Todo vote was successfully created.' }
        format.json { render :show, status: :created, location: @todo_vote }
      else
        format.html { render :new }
        format.json { render json: @todo_vote.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /todo_votes/1
  # PATCH/PUT /todo_votes/1.json
  def update
    respond_to do |format|
      if @todo_vote.update(todo_vote_params)
        format.html { redirect_to @todo_vote, notice: 'Todo vote was successfully updated.' }
        format.json { render :show, status: :ok, location: @todo_vote }
      else
        format.html { render :edit }
        format.json { render json: @todo_vote.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /todo_votes/1
  # DELETE /todo_votes/1.json
  def destroy
    @todo_vote.destroy
    respond_to do |format|
      format.html { redirect_to todo_votes_url, notice: 'Todo vote was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_todo_vote
      @todo_vote = TodoVote.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def todo_vote_params
      params.fetch(:todo_vote, {})
    end
end
