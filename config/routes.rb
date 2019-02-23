Rails.application.routes.draw do
  match 'generate/:query' => 'search_request#generate', :via => [:post]
end
