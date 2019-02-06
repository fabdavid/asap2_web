desc '####################### test run'
task test_run: :environment do
  puts 'Executing...'

  now = Time.now
  
a = '{"id":null,"project_id":5541,"step_id":2,"std_method_id":7,"attrs_json":"{\"input_matrix\":\"3\",\"fit_model\":\"log\"}","output_json":"{}","num":2,"job_id":null,"pid":null,"error":null,"status_id":1,"run_parents_json":null,"run_children_json":null,"created_at":null,"user_id":1,"req_id":14}'
  b = JSON.parse(a)
r = Run.new(b)
r.save!
end
