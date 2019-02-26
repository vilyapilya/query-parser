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
  
  context "splitIntoTokens" do 
    it("should correclty define all tokens") do 
      expectedResult =  ["!", "a", "<=", "b", "or", "=", "o"]
      expect(dummy.splitIntoTokens("!a <=b or =o")).to eq(expectedResult)
    end
    it("should return am empty array if the string is empty") do 
      expectedResult = []
      expect(dummy.splitIntoTokens("")).to eq(expectedResult)
    end
  end  
  
  context "insertDefaultEqualOperators" do 
    it("should insert = before operands with no other unary op or before (") do 
      input = ["a", "<=", "b", "or", "=", "o", "("]
      expectedOutput = ["=", "a", "<=", "b", "or", "=", "o", "=", "("]
       expect(dummy.insertDefaultEqualOperators(input)).to eq(expectedOutput)
    end
  end
  
  context "insertDefaultAndOperators" do 
    it("should inserr 'and' before operands if not other binary op is defined") do 
      input = ["=","a","=","b"]
      expectedOutput = ["=", "a", "AND", "=", "b"]
      expect(dummy.insertDefaultAndOperators(input)).to eq(expectedOutput)
    end
    it("should work with ()") do 
      input = ["=", "(", "=","a","=","b", ")", "=", "p"]
      expectedOutput = ["=", "(", "=", "a", "AND", "=", "b", ")", "AND", "=", "p"]
      expect(dummy.insertDefaultAndOperators(input)).to eq(expectedOutput)
    end
  end
  
  context "convertToPostfix" do 
    it("") do
      input = ["=", "a", "and", "=", "b"]
      expctedOutput = ["a", "=", "b", "=", "and"]
      expect(dummy.convertToPostfix(input)).to eq(expctedOutput)
    end
    it("should work with ()") do
      input = ["=", "(", "=", "a", "AND", "=", "b", ")", "AND", "=", "p"]
      expctedOutput = ["a", "=", "b", "=", "AND", "=", "p", "=", "AND"]
      expect(dummy.convertToPostfix(input)).to eq(expctedOutput)
    end
  end
  
  context "evaluate" do 
    it("creates a hasf out of the post fix expression, combinnign operands with operators") do 
      input =["a", "=", "b", "=", "AND", "=", "p", "=", "AND"]
      expctedOutput = {"$and"=>[{"$eq"=>{"$and"=>[{"$eq"=>"a"}, {"$eq"=>"b"}]}}, {"$eq"=>"p"}]}
      expect(dummy.evaluate(input)).to eq(expctedOutput)
    end
  end
  
  context "parse" do
    it("should process a single term with implicit sign correctly") do  
      input = "test"
      expctedOutput = {"$eq"=>"test"}
      expect(dummy.parse(input)).to eq(expctedOutput)
    end
    it("should process a single term with explicit sign correctly") do
      input = "!test"
      expctedOutput = {"$not"=>"test"}
      expect(dummy.parse(input)).to eq(expctedOutput)
    end
    it("should process multiple terms with implicit rule and a sign") do
      input ="test <3"
      expctedOutput = {"$and"=>[{"$eq"=>"test"}, {"$lt"=>"3"}]}
      expect(dummy.parse(input)).to eq(expctedOutput)
    end
    it("should process multiple terms with explicit rule and a sign") do
      input = "test or <3"
      expectedOutput = {"$or"=>[{"$eq"=>"test"}, {"$lt"=>"3"}]}
      expect(dummy.parse(input)).to eq(expectedOutput)
    end
    it("should process multiple terms in multiple layers") do
      input = "c or (t r)"
      expectedOutput = {"$or"=>[{"$eq"=>"c"}, {"$eq"=>{"$and"=>[{"$eq"=>"t"}, {"$eq"=>"r"}]}}]}
      expect(dummy.parse(input)).to eq(expectedOutput)
    end
    it("should handle quoted phrases correclty") do
      input = "!\"text here\" and >0"
      expectedOutput = {"$and"=>[{"$not"=>{"$quoted"=>"text here"}}, {"$gt"=>"0"}]}
      expect(dummy.parse(input)).to eq(expectedOutput)
    end
    it("should work for multiple rules in one layer") do
      input = "a b c"
      expectedOutput = {"$and"=>[{"$and"=>[{"$eq"=>"a"}, {"$eq"=>"b"}]}, {"$eq"=>"c"}]}
      expect(dummy.parse(input)).to eq(expectedOutput)
    end
    it("shoiuld work with mutiple rules in multiple layers") do
      input = "aa !b OR (<45 >=38)"
      expectedOutput = 
      {"$or"=>[{"$and"=>[{"$eq"=>"aa"}, {"$not"=>"b"}]}, 
      {"$eq"=>{"$and"=>[{"$lt"=>"45"}, {"$gte"=>"38"}]}}]}
      expect(dummy.parse(input)).to eq(expectedOutput)
    end
  end
end