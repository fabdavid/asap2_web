class ClaVotesController < ApplicationController
  before_action :set_cla_vote, only: [:show, :edit, :update, :destroy]

  # GET /cla_votes
  # GET /cla_votes.json
  def index
    @cla_votes = ClaVote.all
  end

  # GET /cla_votes/1
  # GET /cla_votes/1.json
  def show
  end

  # GET /cla_votes/new
  def new
    @cla_vote = ClaVote.new
  end

  # GET /cla_votes/1/edit
  def edit
  end

  # POST /cla_votes
  # POST /cla_votes.json
  def create
    @cla_vote = ClaVote.new(cla_vote_params)

    respond_to do |format|
      if @cla_vote.save
        format.html { redirect_to @cla_vote, notice: 'Cla vote was successfully created.' }
        format.json { render :show, status: :created, location: @cla_vote }
      else
        format.html { render :new }
        format.json { render json: @cla_vote.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cla_votes/1
  # PATCH/PUT /cla_votes/1.json
  def update
    respond_to do |format|
      if @cla_vote.update(cla_vote_params)
        format.html { redirect_to @cla_vote, notice: 'Cla vote was successfully updated.' }
        format.json { render :show, status: :ok, location: @cla_vote }
      else
        format.html { render :edit }
        format.json { render json: @cla_vote.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cla_votes/1
  # DELETE /cla_votes/1.json
  def destroy
    @cla_vote.destroy
    respond_to do |format|
      format.html { redirect_to cla_votes_url, notice: 'Cla vote was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cla_vote
      @cla_vote = ClaVote.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cla_vote_params
      params.fetch(:cla_vote, {})
    end
end
