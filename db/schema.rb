# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_08_02_103650) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cluster_methods", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "label"
    t.text "description"
    t.text "program"
    t.text "attrs_json"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "speed_id", limit: 2
    t.text "link"
    t.text "warning"
  end

  create_table "clusters", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "cluster_method_id"
    t.text "attrs_json"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "label"
    t.integer "status_id"
    t.integer "duration"
    t.integer "num"
    t.integer "dim_reduction_id"
    t.integer "pid"
    t.integer "step_id"
    t.text "error"
    t.integer "job_id"
    t.integer "user_id"
  end

  create_table "courses", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "upload_type"
    t.text "name"
    t.text "status"
    t.text "upload_file_name"
    t.text "upload_content_type"
    t.integer "upload_file_size"
    t.datetime "upload_updated_at"
    t.boolean "visible"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "project_key"
  end

  create_table "db_sets", id: :serial, force: :cascade do |t|
    t.integer "tool_id"
    t.text "label"
    t.text "tag"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "diff_expr_methods", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "label"
    t.text "description"
    t.text "program"
    t.text "link"
    t.integer "speed_id", limit: 2
    t.text "attrs_json"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "creates_av_norm", default: false
    t.boolean "handles_log", default: false
  end

  create_table "diff_exprs", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "diff_expr_method_id"
    t.integer "selection1_id"
    t.integer "selection2_id"
    t.text "attrs_json"
    t.integer "status_id"
    t.integer "duration"
    t.datetime "created_at"
    t.integer "pid"
    t.integer "num"
    t.text "label"
    t.integer "nber_up_genes"
    t.integer "nber_down_genes"
    t.text "md5_sel1"
    t.text "md5_sel2"
    t.integer "nb_cells_sel1"
    t.integer "nb_cells_sel2"
    t.text "error"
    t.text "short_label"
    t.integer "job_id"
    t.integer "user_id"
  end

  create_table "dim_reductions", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "label"
    t.text "description"
    t.text "program"
    t.text "attrs_json"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "speed_id", limit: 2
    t.text "link"
  end

  create_table "filter_methods", id: :integer, default: -> { "nextval('filters_id_seq'::regclass)" }, force: :cascade do |t|
    t.text "name"
    t.text "description"
    t.text "program"
    t.text "attrs_json"
    t.text "label"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "speed_id", limit: 2
    t.text "link"
    t.boolean "handles_log", default: false
  end

  create_table "gene_enrichments", id: :serial, force: :cascade do |t|
    t.integer "num"
    t.text "label"
    t.integer "project_id"
    t.integer "diff_expr_id"
    t.text "attrs_json"
    t.integer "status_id"
    t.integer "duration"
    t.integer "pid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "nber_pathways"
    t.text "error"
    t.integer "job_id"
    t.integer "user_id"
  end

  create_table "gene_names", id: :serial, force: :cascade do |t|
    t.integer "gene_id"
    t.integer "organism_id"
    t.text "value"
    t.index ["organism_id", "value"], name: "genes_organism_id_value_idx"
  end

  create_table "gene_sets", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "project_id"
    t.integer "organism_id"
    t.text "label"
    t.text "original_filename"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "nb_items", default: 3
    t.integer "tool_id"
    t.integer "ref_id"
  end

  create_table "genes", id: :serial, force: :cascade do |t|
    t.text "ensembl_id"
    t.text "name"
    t.text "biotype"
    t.text "chr"
    t.integer "gene_length"
    t.integer "sum_exon_length"
    t.integer "organism_id"
    t.datetime "created_at"
    t.text "alt_names"
    t.index ["ensembl_id"], name: "genes_ensembl_id_idx"
    t.index ["name"], name: "genes_name_idx"
    t.index ["organism_id", "name"], name: "genes_organism_id_name_idx"
  end

  create_table "jobs", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "step_id"
    t.integer "status_id"
    t.text "command_line"
    t.integer "duration"
    t.integer "pid"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "cloned_job_id"
    t.integer "speed_id"
    t.integer "delayed_job_id"
  end

  create_table "norms", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "description"
    t.text "program"
    t.text "attrs_json"
    t.text "label"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "speed_id", limit: 2
    t.text "link"
    t.boolean "output_is_log", default: true
    t.boolean "hidden", default: false
    t.boolean "handles_log", default: false
  end

  create_table "organisms", id: :serial, force: :cascade do |t|
    t.text "name"
    t.integer "tax_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "genrep_key"
    t.text "short_name"
    t.text "tag"
    t.text "go_short_name"
  end

  create_table "project_dim_reductions", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "dim_reduction_id"
    t.integer "status_id"
    t.integer "duration"
    t.datetime "created_at"
    t.text "attrs_json"
    t.integer "pid"
    t.integer "job_id"
    t.integer "user_id"
  end

  create_table "project_steps", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "step_id"
    t.integer "status_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "job_id"
    t.text "error_message"
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.text "name"
    t.string "key", limit: 6
    t.text "input_filename"
    t.text "group_filename"
    t.integer "organism_id", default: 1
    t.integer "norm_id"
    t.text "norm_attrs_json"
    t.integer "filter_id"
    t.text "filter_attrs_json"
    t.integer "step", limit: 2
    t.integer "status_id", default: 1
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "step_id", default: 1
    t.text "parsing_attrs_json"
    t.integer "duration"
    t.integer "delayed_job_id"
    t.text "error_message"
    t.integer "pid"
    t.boolean "public", default: false
    t.integer "filter_method_id"
    t.text "filter_method_attrs_json"
    t.integer "session_id"
    t.integer "cloned_project_id"
    t.boolean "sandbox", default: false
    t.integer "pmid"
    t.integer "nber_genes"
    t.integer "nber_cells"
    t.string "extension", limit: 3, default: "txt"
    t.text "diff_expr_filter_json"
    t.text "gene_enrichment_filter_json"
    t.integer "parsing_job_id"
    t.integer "normalization_job_id"
    t.integer "filtering_job_id"
    t.text "read_access"
    t.text "write_access"
    t.integer "nber_clones", default: 0
  end

  create_table "selections", id: :serial, force: :cascade do |t|
    t.text "label"
    t.integer "manual_num"
    t.integer "obj_id"
    t.integer "obj_num"
    t.integer "nb_items"
    t.integer "project_id"
    t.boolean "edited", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "md5"
    t.integer "selection_type_id", default: 1
    t.integer "user_id"
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "shares", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "user_id"
    t.text "email"
    t.boolean "view_perm", default: false
    t.boolean "analyze_perm", default: false
    t.boolean "clone_perm"
    t.boolean "download_perm"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "export_perm", default: false
  end

  create_table "speeds", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "logo"
  end

  create_table "statuses", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "label"
    t.text "color"
    t.text "img_extension"
  end

  create_table "steps", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "label"
    t.text "obj_name"
    t.text "description"
  end

  create_table "tool_types", id: :serial, force: :cascade do |t|
    t.text "name"
  end

  create_table "tools", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "label"
    t.text "step_ids"
    t.integer "tool_type_id"
    t.text "tag"
  end

  create_table "uploads", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "upload_type"
    t.text "name"
    t.text "status"
    t.text "upload_file_name"
    t.text "upload_content_type"
    t.integer "upload_file_size"
    t.datetime "upload_updated_at"
    t.boolean "visible"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.datetime "release_date"
    t.text "description"
    t.text "tools_json"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "tool_type_id"
    t.integer "step_id"
  end

  add_foreign_key "cluster_methods", "speeds", name: "cluster_methods_speed_id_fkey"
  add_foreign_key "clusters", "cluster_methods", name: "clusters_cluster_method_id_fkey"
  add_foreign_key "clusters", "dim_reductions", name: "clusters_dim_reduction_id_fkey"
  add_foreign_key "clusters", "jobs", name: "clusters_job_id_fkey"
  add_foreign_key "clusters", "projects", name: "clusters_project_id_fkey"
  add_foreign_key "clusters", "statuses", name: "clusters_status_id_fkey"
  add_foreign_key "clusters", "steps", name: "clusters_step_id_fkey"
  add_foreign_key "clusters", "users", name: "clusters_user_id_fkey"
  add_foreign_key "courses", "projects", name: "courses_project_id_fkey"
  add_foreign_key "db_sets", "tools", name: "db_sets_tool_id_fkey"
  add_foreign_key "diff_expr_methods", "speeds", name: "diff_expr_methods_speed_id_fkey"
  add_foreign_key "diff_exprs", "diff_expr_methods", name: "diff_exprs_diff_expr_method_id_fkey"
  add_foreign_key "diff_exprs", "jobs", name: "diff_exprs_job_id_fkey"
  add_foreign_key "diff_exprs", "projects", name: "diff_exprs_project_id_fkey"
  add_foreign_key "diff_exprs", "statuses", name: "diff_exprs_status_id_fkey"
  add_foreign_key "diff_exprs", "users", name: "diff_exprs_user_id_fkey"
  add_foreign_key "dim_reductions", "speeds", name: "dim_reductions_speed_id_fkey"
  add_foreign_key "filter_methods", "speeds", name: "filters_speed_id_fkey"
  add_foreign_key "gene_enrichments", "diff_exprs", name: "gene_enrichments_diff_expr_id_fkey"
  add_foreign_key "gene_enrichments", "jobs", name: "gene_enrichments_job_id_fkey"
  add_foreign_key "gene_enrichments", "projects", name: "gene_enrichments_project_id_fkey"
  add_foreign_key "gene_enrichments", "statuses", name: "gene_enrichments_status_id_fkey"
  add_foreign_key "gene_enrichments", "users", name: "gene_enrichments_user_id_fkey"
  add_foreign_key "gene_names", "genes", name: "gene_names_gene_id_fkey"
  add_foreign_key "gene_names", "organisms", name: "gene_names_organism_id_fkey"
  add_foreign_key "gene_sets", "organisms", name: "gene_sets_organism_id_fkey"
  add_foreign_key "gene_sets", "projects", name: "gene_sets_project_id_fkey"
  add_foreign_key "gene_sets", "tools", name: "gene_sets_tool_id_fkey"
  add_foreign_key "gene_sets", "users", name: "gene_sets_user_id_fkey"
  add_foreign_key "genes", "organisms", name: "genes_organism_id_fkey"
  add_foreign_key "jobs", "speeds", name: "jobs_speed_id_fkey"
  add_foreign_key "jobs", "statuses", name: "jobs_status_id_fkey"
  add_foreign_key "jobs", "steps", name: "jobs_step_id_fkey"
  add_foreign_key "jobs", "users", name: "jobs_user_id_fkey"
  add_foreign_key "norms", "speeds", name: "norms_speed_id_fkey"
  add_foreign_key "project_dim_reductions", "dim_reductions", name: "project_dim_reductions_dim_reduction_id_fkey"
  add_foreign_key "project_dim_reductions", "jobs", name: "project_dim_reductions_job_id_fkey"
  add_foreign_key "project_dim_reductions", "projects", name: "project_dim_reductions_project_id_fkey"
  add_foreign_key "project_dim_reductions", "statuses", name: "project_dim_reductions_status_id_fkey"
  add_foreign_key "project_dim_reductions", "users", name: "project_dim_reductions_user_id_fkey"
  add_foreign_key "project_steps", "jobs", name: "project_steps_job_id_fkey"
  add_foreign_key "project_steps", "projects", name: "project_steps_project_id_fkey"
  add_foreign_key "project_steps", "statuses", name: "project_steps_status_id_fkey"
  add_foreign_key "project_steps", "steps", name: "project_steps_step_id_fkey"
  add_foreign_key "projects", "filter_methods", column: "filter_id", name: "projects_filter_id_fkey"
  add_foreign_key "projects", "filter_methods", name: "projects_filter_method_id_fkey"
  add_foreign_key "projects", "jobs", column: "filtering_job_id", name: "projects_filtering_job_id_fkey"
  add_foreign_key "projects", "jobs", column: "normalization_job_id", name: "projects_normalization_job_id_fkey"
  add_foreign_key "projects", "jobs", column: "parsing_job_id", name: "projects_parsing_job_id_fkey"
  add_foreign_key "projects", "norms", name: "projects_norm_id_fkey"
  add_foreign_key "projects", "organisms", name: "projects_organism_id_fkey"
  add_foreign_key "projects", "statuses", name: "projects_status_id_fkey"
  add_foreign_key "projects", "steps", name: "projects_step_id_fkey"
  add_foreign_key "projects", "users", name: "projects_user_id_fkey"
  add_foreign_key "selections", "projects", name: "selections_project_id_fkey"
  add_foreign_key "selections", "users", name: "selections_user_id_fkey"
  add_foreign_key "shares", "projects", name: "shares_project_id_fkey"
  add_foreign_key "shares", "users", name: "shares_user_id_fkey"
  add_foreign_key "tools", "tool_types", name: "tools_tool_type_id_fkey"
  add_foreign_key "uploads", "projects", name: "uploads_project_id_fkey"
  add_foreign_key "versions", "steps", name: "versions_step_id_fkey"
  add_foreign_key "versions", "tool_types", name: "versions_tool_type_id_fkey"
end
