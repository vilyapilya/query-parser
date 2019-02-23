require "ostruct"
require "json"
require "json_generator"

class SearchRequestController < ApplicationController
  # POST /search
  
  include Generator
  def generate
    queryString = params.require(:query)
    jsonedQuery = transform(queryString)
    render json: jsonedQuery
  end
end
