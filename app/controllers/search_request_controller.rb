require "ostruct"
require "json"
require "json_generator"
require "string_analizer"

class SearchRequestController < ApplicationController
  # POST /search
  
  include Generator
  include StringAnalizer
  def generate
    queryString = params.require(:query)
    jsonedQuery = parse(queryString)
    render json: jsonedQuery
  end
end
