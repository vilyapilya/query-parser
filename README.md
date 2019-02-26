# README

if you don't have Ruby installed than install: https://github.com/postmodern/ruby-install

<br />pull the repo
<br />go to /search-api
<br />run 'rails s' to start the application
<br />if you have insomnia or any other api testing app, hit 'http://localhost:3000/generate/{quary string}'
<br />it should return the query in the converted json format

<br />to run tests:
<br />go to /search-api
<br />and run the following commands in your terminal
<br />controller test:
<br />bundle exec rspec spec/controllers/search_request_controller_spec.rb
<br />module logic tests:
<br />bundle exec rspec spec/controllers/string_analizer_spec.rb

