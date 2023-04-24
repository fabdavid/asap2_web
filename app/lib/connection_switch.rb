# RAILS_ROOT/lib/connection_switch.rb
module ConnectionSwitch
  class << self 
    def with_db(connection_spec_name, version_id)

#      current_conf = "postgresql://postgres:5Evba56@postgres:5434/asap2_development?encoding=utf8&pool=300&timeout=15000"
     databases = YAML.load_file("config/database.yml")
     d = databases[ENV["RAILS_ENV"]]["url"].gsub(/<%\=/, '').gsub(/%>/, "")
     current_conf = eval(d)
    #  current_conf = ActiveRecord::Base.connection_config
    #  current_conf[:database] = 'asap2_development'
    #  current_conf[:pool] = 200
    #  main_conf = db_configurations[:development]
#      Thread.new do
 #     Rails.application.executor.wrap do  

        #      conf = db_configurations[connection_spec_name]
        
      if connection_spec_name == :data_with_version
        conf = "postgresql://postgres:5Evba56@postgres:5434/asap2_data_v#{version_id}?encoding=utf8&pool=100&timeout=15000"
      elsif connection_spec_name == :website_with_version
        conf = "postgresql://postgres:5Evba56@postgres:5434/asap2_development?encoding=utf8&pool=50&timeout=15000"
      end
      
      begin
        
      #  Thread.new do
      #    Rails.application.executor.wrap do
            ActiveRecord::Base.establish_connection(conf).tap do
              Rails.logger.debug "\e[1;35m [ActiveRecord::Base switched database] \e[0m #{ActiveRecord::Base.connection.current_database}"
          puts "\e[1;35m [ActiveRecord::Base switched database] \e[0m #{ActiveRecord::Base.connection.current_database}"

            end if database_changed?(connection_spec_name)
            
            yield
      #    end
      #  end
      rescue => ex
        puts ex, ex.backtrace
      ensure
        ActiveRecord::Base.establish_connection(current_conf).tap do
          Rails.logger.debug "\e[1;35m [ActiveRecord::Base switched database] \e[0m #{ActiveRecord::Base.connection.current_database}"
          puts "\e[1;35m [ActiveRecord::Base switched database] \e[0m #{ActiveRecord::Base.connection.current_database}"
        end #if database_changed?(connection_spec_name, current_conf)
      end
      #           end
          #      end
          
    end
    
    private
    def database_changed?(connection_spec_name, current_conf = nil)
      current_conf = ActiveRecord::Base.connection_config unless current_conf
      current_conf[:database] != db_configurations[connection_spec_name].try(:[], :database)
    end
    
    def db_configurations
      @db_config ||= begin
                       file_name =  "#{Rails.root}/config/database.yml"
                       if File.exists?(file_name) || File.symlink?(file_name)
                         config ||= HashWithIndifferentAccess.new(YAML.load(ERB.new(File.read(file_name)).result))
                       else
                         config ||= HashWithIndifferentAccess.new
                       end
                       
                       config
                     end
    end
end
end
#ActiveRecord.send :extend, ConnectionSwitch
  
