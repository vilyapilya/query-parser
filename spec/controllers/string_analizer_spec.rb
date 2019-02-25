require 'rails_helper'

class DummyTestClass
  include StringAnalizer
end

RSpec.describe StringAnalizer, type: :module do
  let(:dummy) { DummyTestClass.new }
  let(:termsAndSigns) {[]}
  let(:rulesAndParen) {[]}

  before(:each) { DummyTestClass.class_variable_set :@@termsAndSigns, termsAndSigns }
  before(:each) { DummyTestClass.class_variable_set :@@rulesAndParen, rulesAndParen }

  context "processCharacters" do  
    it "should put a '(' into rules and paren stack" do
      dummy.processCharacters("(")  
      expect(rulesAndParen.include?("(")).to be true
    end
    it "should put a sign into sign stack" do
      dummy.processCharacters(">!")
      expect(termsAndSigns.include?(">") && termsAndSigns.include?("!")).to be true
    end
    it "should combine characters into one string" do
      dummy.processCharacters("<test")  
      expect(termsAndSigns.include?("<") && termsAndSigns.include?("test")).to be true
    end
  end
  
  context "parse" do
    it("should process a single term with implicit sign correctly") do  
      result = {"$eq"=>["test"]}
      expect(dummy.parse("test")).to eq(result)
    end
    it("should process a single term with explicit sign correctly") do
      result = {"$not"=>["test"]}      
      expect(dummy.parse("!test")).to eq(result)
    end
    it("should process multiple terms with implicit rule and a sign") do
      result = {"$and"=>[{"$lt"=>["3"]}, {"$eq"=>["test"]}]}
      expect(dummy.parse("test <3")).to eq(result)
    end
    it("should process multiple terms with explicit rule and a sign") do
      result = {"$or"=>[{"$lt"=>["3"]}, {"$eq"=>["test"]}]}
      expect(dummy.parse("test or <3")).to eq(result)
    end
    it("should process multiple terms in multiple layers") do
      result = {"$or"=>[{"$eq"=>["c"]}], "and"=>[{"$eq"=>["t", "r"]}]}
      p dummy.parse("c or (t r)")
      expect(dummy.parse("c or (t r)")).to eq(result)
    end
    it("should handle quoted phrases correclty") do
      result = {"$and"=>[{"$gt"=>["0"]}, {"$not"=>["text here"]}]}
      expect(dummy.parse("!\"text here\" and >0")).to eq(result)
    end
    it("should work for multiple rules in one layer") do
      result = {"$and" => ["$eq" => ["a", "b", "c"]]}
      expect(dummy.parse("a b c")).to eq(result)
    end
    it(" ") do
      p dummy.parse("aa and !b OR <45")
    end
  end
end