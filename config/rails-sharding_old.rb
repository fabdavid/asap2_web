
Rails::Sharding.setup do |config|
 # If true one connection will be established per shard (in every shard group) on startup.
  # If false the user must call Shards::ConnectionHandler.establish_connection(shard_group, shard_name) manually at least once before using each shard.
  config.establish_all_connections_on_setup = true

  # If true the method #using_shard will be mixed in ActiveRecord scopes. Put this to false if you don't want the gem to modify ActiveRecord
  config.extend_active_record_scope = true

  # If true the query logs of ActiveRecord will be tagged with the corresponding shard you're querying
  config.add_shard_tag_to_query_logs = true

  # Specifies where to find the definition of the shards configurations
  config.shards_config_file = 'config/shards.yml'

  # Specifies where to find the migrations for each shard group
  config.shards_migrations_dir = 'db/shards_migrations'

  # Specifies where to find the schemas for each shard group
  config.shards_schemas_dir = 'db/shards_schemas'
end
