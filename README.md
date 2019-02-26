# README

if you don't have Ruby installed than install: https://github.com/postmodern/ruby-install

pull the repo
go to /search-api
run 'rails s' to start the application
if you have insomnia or any other api testing app, hit 'http://localhost:3000/generate/{quary string}'
it should return the quary in the converted json format

to run tests:
go to /search-api
and run the following comands in your terminal
controller test:
bundle exec rspec spec/controllers/search_request_controller_spec.rb
module logic tests:
bundle exec rspec spec/controllers/string_analizer_spec.rb

