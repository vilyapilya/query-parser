require 'rails_helper'
require 'json_generator'
require 'string_analizer'

RSpec.configure do |c|
  c.include Generator
  c.include StringAnalizer
end

RSpec.describe SearchRequestController, type: :controller do
  context "getTermSign" do
    it "should return '$eq' when no sign" do
      expect(getTermSign("test")).to eq "$eq"
    end
    it "should return '$gt' when >" do
      expect(getTermSign(">test")).to eq "$gt"
    end
    it "should return '$eq' when =" do
      expect(getTermSign(">test")).to eq "$gt"
    end
  end
  
  context "enterTerm" do
    let(:stackOfTerms) {[{"$eq" => "test"}]}
    it "should check if the term is length" do
    end
    it "should push the entry to the stack" do
      expectedEntry = {"$gt" => ["term"]}
      enterTerm("$gt", "term", stackOfTerms)
      expect(stackOfTerms.length).to eq(2)
      expect(stackOfTerms[1]["$gt"]).to eq("term")
    end    
  end
  context "combineTerms" do
    let(:combinedTerms) {{"$and" => [{"$eq" => "test"}]}}
    it "should add a new inclusion rule if it did not exist" do
      combineTerms(combinedTerms, "$or", "term")
      expect(combinedTerms.length).to eq(2)
      expect(combinedTerms.has_key?("$or")).to be true
    end
    it "should add the term to the existing inclusion rule" do
      newTerm = {"$eq" => "term"}
      combineTerms(combinedTerms, "$and", newTerm)
      expect(combinedTerms.length).to eq(1)
      expect(combinedTerms["$and"].length).to eq(2)
      expect(combinedTerms["$and"].include?(newTerm)).to be true
    end
  end
  context "removeSignIfExists" do
    it "should not change the word if no sign" do
      word = "3"
      exp = "3"  
      expect(removeSignIfExists(word)).to eq(exp)
    end
    it "should remove the sign" do
      word = ">3"
      exp = "3"
      expect(removeSignIfExists(word)).to eq(exp)
    end
  end
  context "clearStackAndCombineTerms" do
    let(:stackOfTerms) {[{"$eq" => "newTerm"}]}
    let(:combinedTerms) {{"$and" => [{"$eq" => "test"}]}}
    it "should empty the stack" do
      clearStackAndCombineTerms(stackOfTerms, combinedTerms, "$and")
      expect(stackOfTerms.length).to eq(0)
    end
    it "should combine the terms with the given incl rule" do
      clearStackAndCombineTerms(stackOfTerms, combinedTerms, "$or")
      expect(combinedTerms.length).to eq(2)
      expect(combinedTerms.include?("$or")).to be true
    end
  end
  
  context "transform" do
    it "should correctly tranform two words with explicit rule and sign" do
      expctedStructure = {"$or" => [{"$gt" => "5"},{"$lt" => "90"}]}
      expect(transform(">5 or <90")).to eq(expctedStructure)
    end
    it "should correctly tranform two words with implict rule and sign" do
      expctedStructure = {"$and" => [{"$eq" => "5"},{"$eq" => "90"}]}
      expect(transform("5 90")).to eq(expctedStructure)
    end
    it "should correctly tranform a single word" do
      expctedStructure = [{"$eq" => "test"}]
      expect(transform("test")).to eq(expctedStructure)
    end
    it "should handle quoted terms as one" do
      expctedStructure = [{"$eq" => {"$quoted"=>"test data here"}}]
      expect(transform("\"test data here\"")).to eq(expctedStructure)
    end
  end
  
  context "trimQuotes" do
    it "should trim the quotes if exist" do
      phrase = "\"test data\""
      expcted = "test data"
      expect(trimQuotes(phrase)).to eq(expcted)
    end
  end
  
  context "isolateQuotedTerms" do
    it"should create a single element out of quoted words" do
      wordsArray = ["\"test", "and", "also", "data\"", "finish"]
      expectedAr = ["\"test and also data\"", "finish" ]
      expect(isolateQuotedTerms(wordsArray)).to eq(expectedAr)
    end
    it"should not change the length if only one word is quoted" do
      wordsArray = ["\"test\"", "simple"]
      expectedAr = ["\"test\"", "simple" ]
      expect(isolateQuotedTerms(wordsArray)).to eq(expectedAr)
    end
    it"should not change if no closing quote" do
      wordsArray = ["\"test", "simple"]
      expectedAr = ["\"test", "simple" ]
      expect(isolateQuotedTerms(wordsArray)).to eq(expectedAr)
    end
    it"should handle signs correcltly" do
      wordsArray = ["!\"test", "simple\""]
      expectedAr = ["!\"test simple\""]
      expect(isolateQuotedTerms(wordsArray)).to eq(expectedAr)
    end
  end
  
  
  
  #############
  #########
  #####
  context "processCharacters" do
    let(:rulesAndParen) {[]}
    it "should put a '(' into signs stack" do
      p termsAndSigns
      # processCharacters("(")    
      # expect(@@rulesAndParen.include?("(")).to be true
    end
    it "should put a sign into sign stack" do
      processCharacters(">!")
      expect(SearchRequestController.termsAndSigns.include?(">") && 
      SearchRequestController.termsAndSigns.include?("!")).to be true
    end
    it "should combine characters into one string" do
      processCharacters("<test")  
      expect(SearchRequestController.termsAndSigns.include?("<") && 
      SearchRequestController.termsAndSigns.include?("test")).to be true
    end
  end
  
  context "parse" do
    let(:rulesAndParen) {[]}
    let(:termsAndSigns) {[]}
    it("should put inclusion rules into rulesAndParen stack") do
      parse("test and data")
      expect(rulesAndParen.include?("$and")).to be true
    end
    it("should process a single term with implicit sign correctly") do
      result = {"$eq"=>["test"]}
      expect(parse("test")).to eq(result)
    end
    it("should process a single term with explicit sign correctly") do
      result = {"$not"=>["test"]}
      expect(parse("!test")).to eq(result)
    end
    it("should process multiple terms with implicit rule and a sign") do
      result = {"$and"=>[{"$eq"=>["test"], "$lt"=>["3"]}]}
      expect(parse("test <3")).to eq(result)
    end
    it("should process multiple terms with explicit rule and a sign") do
      result = {"$or"=>[{"$eq"=>["test"], "$lt"=>["3"]}]}
      expect(parse("test or <3")).to eq(result)
    end
    it("should process multiple terms in multiple layers") do
      result = {"$or"=>[{"$eq"=>["c", {"$and"=>[{"$eq"=>["t", "r"]}]}]}]}
      expect(parse("c or (t r)")).to eq(result)
    end
    it("should handle quoted phrases correclty") do
      result = {"$and"=>[{"$gt"=>["0"], "$not"=>["text here"]}]}
      expect(parse("!\"text here\" and >0")).to eq(result)
    end
    it("should work for multiple rules in one layer") do
      
      p parse("a and b ")
    end
  end
  
end
