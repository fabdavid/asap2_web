desc '####################### Update PubMed'
task update_pubmed: :environment do
  puts 'Executing...'

  now = Time.now
  
  Article.all.each do |article|
    Fetch.load_articles(article.pmid)
  end
  
end
