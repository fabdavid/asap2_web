class TodosController < ApplicationController
  before_action :set_todo, only: [:show, :edit, :update, :destroy]

  include ApplicationHelper
  
  layout "welcome"

  # GET /todos
  # GET /todos.json
  def index
  end

  def get_cards
    todos = Todo.where(:todo_type_id => ((params[:todo_type_id]) ? params[:todo_type_id] : [1, 2])).order("validated desc, status_id desc, nber_votes desc").all
    
    @h_thumbs = {}
    if current_user
      TodoVote.where(:user_id => current_user.id).each do |tv|
        @h_thumbs[tv.todo_id]=1
      end
    end

    @h_statuses = {}
    Status.all.map{|s| @h_statuses[s.id]=s}

    @todo_cards = []
    @done_cards = []

    h_todo_statuses={
      1 => 'Pending',
      2 => "Ongoing",
      3 => "Done"
    }

    todos.select{|td| td.status_id != 1 or current_user}.each do |todo|
      
      h_card = {
        :card_id => "todo_card-#{todo.id}",
        :card_class => "todo_card",
        :body => "<div class='float-right'>#{display_status_todo(@h_statuses[todo.status_id], h_todo_statuses)}</div><h5 class='card-title'>#{todo.title}</h5><p class='card-text'>#{todo.description}</p>",
        :footer => "<span>Last update: #{display_date2(todo.updated_at)}</span>" + ((current_user) ? ("<div class='float-right'>" +
((admin? or current_user.id == todo.user_id) ? "<button type='button' onclick=\"window.location='#{edit_todo_path(todo)}'\" class='btn btn-primary btn-sm'>Edit</button> " : "") +  
"<button id='thumb_#{todo.id}_#{(@h_thumbs[todo.id]) ? 0 : 1}' type='button' class='btn btn-primary btn-sm thumb' #{(todo.user_id == current_user.id) ? 'disabled' : ''}>     
   <span class='fa fa-thumbs-up'></span>  
   <span>#{todo.nber_votes}</span>   
</button></div>") : "<div class='float-right'><span class='fa fa-thumbs-up'></span><span>#{todo.nber_votes}</span></div>")
      }
      if todo.status_id == 3
        @done_cards.push(h_card)
      else
        @todo_cards.push(h_card)
      end
    end
  end
  
  def add_del_thumb
      
    if current_user
      h_thumb = {
        :todo_id => params[:todo_id],
        :user_id => current_user.id
      }
      if params[:add] == '1'
        thumb = TodoVote.new(h_thumb)
        thumb.save
      else
        thumb = TodoVote.where(h_thumb).first
        thumb.delete
      end
      todo = Todo.where(:id => params[:todo_id]).first
      todo.update_attributes(:nber_votes => TodoVote.where(:todo_id => todo.id).count)
    end
    
    get_cards()
    render :partial => "roadmap"
    
  end
  
  
  def get_roadmap
    
    get_cards()
    render :partial => "roadmap"

  end

  # GET /todos/1
  # GET /todos/1.json
  def show
  end

  # GET /todos/new
  def new
    @todo = Todo.new
  end

  # GET /todos/1/edit
  def edit
  end

  # POST /todos
  # POST /todos.json
  def create
    @todo = Todo.new(todo_params)

    @todo.user_id = current_user.id
    @todo.validated = true if admin?

    respond_to do |format|
      if @todo.save
        format.html { redirect_to @todo, notice: 'Todo was successfully created.' }
        format.json { render :show, status: :created, location: @todo }
      else
        format.html { render :new }
        format.json { render json: @todo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /todos/1
  # PATCH/PUT /todos/1.json
  def update
    
    params[:validated] = true if admin?

    respond_to do |format|
      if @todo.update(todo_params)
        format.html { redirect_to @todo, notice: 'Todo was successfully updated.' }
        format.json { render :show, status: :ok, location: @todo }
      else
        format.html { render :edit }
        format.json { render json: @todo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /todos/1
  # DELETE /todos/1.json
  def destroy
    @todo.destroy
    respond_to do |format|
      format.html { redirect_to todos_url, notice: 'Todo was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_todo
      @todo = Todo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def todo_params
      #      #      params.fetch(:todo, {})
      params.fetch(:todo).permit(:title, :description, :status_id, :todo_type_id) 
    end

    def authorize
     admin? or (@todo  or (current_user and p.user_id == current_user.id))
  end
end
