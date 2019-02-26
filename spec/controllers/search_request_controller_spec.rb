require 'rails_helper'
require 'string_analizer'

RSpec.configure do |c|
  c.include StringAnalizer
end

RSpec.describe SearchRequestController, type: :controller do
  context "generate" do  
    it("shout return 200") do
      request.host = 'localhost:3000'
      get :generate, params: {query: "a"}
      expect(response.status).to eq(200)
    end
  end
  
end
