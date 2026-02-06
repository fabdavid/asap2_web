namespace :slurm do
  desc "Initialize SLURM accounts for all users in the database"
  task init_accounts: :environment do
    puts "Initializing SLURM accounts for all users..."
    
    # Get all unique user IDs from projects (users who have created projects)
    user_ids = Project.distinct.pluck(:user_id).compact.sort
    
    if user_ids.empty?
      puts "No users found in projects table."
      return
    end
    
    puts "Found #{user_ids.count} unique user IDs: #{user_ids.inspect}"
    
    created_count = 0
    failed_count = 0
    
    user_ids.each do |user_id|
      account_name = "user_#{user_id}"
      puts "Creating account: #{account_name}..."
      
      begin
        # Try to create account using sacctmgr
        create_cmd = "docker exec slurmctld sacctmgr -i add account #{account_name} 2>&1"
        result = `#{create_cmd}`
        
        if $?.success?
          puts "  ✓ Created account: #{account_name}"
          created_count += 1
        else
          # If sacctmgr fails, try direct database insertion
          puts "  ⚠ sacctmgr failed, trying direct database insertion..."
          db_result = create_account_via_db(account_name)
          if db_result
            puts "  ✓ Created account via database: #{account_name}"
            created_count += 1
          else
            puts "  ✗ Failed to create account: #{account_name}"
            puts "    Error: #{result.strip}"
            failed_count += 1
          end
        end
      rescue => e
        puts "  ✗ Exception creating account #{account_name}: #{e.message}"
        failed_count += 1
      end
    end
    
    puts "\nSummary:"
    puts "  Created: #{created_count}"
    puts "  Failed: #{failed_count}"
    puts "  Total: #{user_ids.count}"
  end
  
  desc "Create SLURM account for a specific user ID"
  task :create_account, [:user_id] => :environment do |t, args|
    user_id = args[:user_id]&.to_i
    
    unless user_id && user_id > 0
      puts "Usage: rails slurm:create_account[USER_ID]"
      puts "Example: rails slurm:create_account[5]"
      exit 1
    end
    
    account_name = "user_#{user_id}"
    puts "Creating SLURM account: #{account_name}..."
    
    create_cmd = "docker exec slurmctld sacctmgr -i add account #{account_name} 2>&1"
    result = `#{create_cmd}`
    
    if $?.success?
      puts "✓ Successfully created account: #{account_name}"
    else
      puts "✗ Failed to create account via sacctmgr, trying database..."
      if create_account_via_db(account_name)
        puts "✓ Successfully created account via database: #{account_name}"
      else
        puts "✗ Failed to create account: #{account_name}"
        puts "Error: #{result.strip}"
        exit 1
      end
    end
  end
  
  desc "List all SLURM accounts"
  task list_accounts: :environment do
    puts "Listing SLURM accounts..."
    
    list_cmd = "docker exec slurmctld sacctmgr show account --noheader --parsable2 2>&1"
    result = `#{list_cmd}`
    
    if $?.success? && !result.strip.empty?
      puts result
    else
      puts "Failed to list accounts via sacctmgr, trying database..."
      list_accounts_via_db
    end
  end
  
  private
  
  def create_account_via_db(account_name)
    # Create account directly in SLURM database
    # This is a workaround when sacctmgr doesn't work
    begin
      creation_time = Time.now.to_i
      mod_time = creation_time
      
      # Insert account into acct_table
      db_cmd = <<~SQL
        docker exec slurmdb mysql -u slurm -pslurm slurm_acct_db -e "
        INSERT IGNORE INTO acct_table (creation_time, mod_time, deleted, name, description, organization)
        VALUES (#{creation_time}, #{mod_time}, 0, '#{account_name}', 'Account for user #{account_name}', 'asap_cluster');
        " 2>&1
      SQL
      
      result = `#{db_cmd}`
      
      if $?.success?
        # Also create association for root user (uid 0) with this account
        # This allows jobs submitted as root to use the account
        # Get parent_acct id from root account (id_assoc = 2 based on the structure)
        parent_id = 1  # Root account parent
        
        assoc_cmd = <<~SQL
          docker exec slurmdb mysql -u slurm -pslurm slurm_acct_db -e "
          INSERT IGNORE INTO asap_cluster_assoc_table 
          (creation_time, mod_time, deleted, user, acct, \\\`partition\\\`, parent_acct, id_parent, lft, rgt, shares, is_def)
          VALUES 
          (#{creation_time}, #{mod_time}, 0, 'root', '#{account_name}', '', 'root', #{parent_id}, 1, 1, 1, 0);
          " 2>&1
        SQL
        
        assoc_result = `#{assoc_cmd}`
        return $?.success?
      else
        Rails.logger.error("Failed to create account in database: #{result}")
        return false
      end
    rescue => e
      Rails.logger.error("Failed to create account via database: #{e.message}")
      false
    end
  end
  
  def list_accounts_via_db
    begin
      db_cmd = "docker exec slurmdb mysql -u slurm -pslurm slurm_acct_db -e 'SELECT name, description FROM acct_table;' 2>&1"
      result = `#{db_cmd}`
      if $?.success?
        puts result
      else
        puts "Failed to list accounts from database"
      end
    rescue => e
      puts "Error listing accounts: #{e.message}"
    end
  end
end

