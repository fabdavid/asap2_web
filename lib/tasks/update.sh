## update DrugBank
docker-compose exec website sh -c 'RAILS_ENV=data && rails update_drugbank'
