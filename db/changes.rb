fus = Fu.all
fus.map{|fu| p = fu.project; fu.update_attributes({:user_id => (p.sandbox == false) ? p.user_id : nil}) if p}

