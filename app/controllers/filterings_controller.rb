class FilteringsController < ApplicationController
  before_action :set_filtering, only: [:show, :edit, :update, :destroy]

  # GET /filterings
  # GET /filterings.json
  def index
    @filterings = Filtering.all
  end

  # GET /filterings/1
  # GET /filterings/1.json
  def show
  end

  # GET /filterings/new
  def new
    @filtering = Filtering.new
  end

  # GET /filterings/1/edit
  def edit
  end

  # POST /filterings
  # POST /filterings.json
  def create
    @filtering = Filtering.new(filtering_params)

    respond_to do |format|
      if @filtering.save
        format.html { redirect_to @filtering, notice: 'Filtering was successfully created.' }
        format.json { render :show, status: :created, location: @filtering }
      else
        format.html { render :new }
        format.json { render json: @filtering.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /filterings/1
  # PATCH/PUT /filterings/1.json
  def update
    respond_to do |format|
      if @filtering.update(filtering_params)
        format.html { redirect_to @filtering, notice: 'Filtering was successfully updated.' }
        format.json { render :show, status: :ok, location: @filtering }
      else
        format.html { render :edit }
        format.json { render json: @filtering.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /filterings/1
  # DELETE /filterings/1.json
  def destroy
    @filtering.destroy
    respond_to do |format|
      format.html { redirect_to filterings_url, notice: 'Filtering was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_filtering
      @filtering = Filtering.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def filtering_params
      params.fetch(:filtering, {})
    end
end
