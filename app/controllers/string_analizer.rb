require 'search_rules'
module StringAnalizer
  include SearchRules
  
  DefaultRule = SearchRules::INCLUSION_RULES["AND"]
  DefaultSign = SearchRules::SIGNES['='] 
  
  @@termsAndSigns = []
  @@rulesAndParen = []
  
  @@block = {}
  
  
  #runs through the search string to isolate quoted terms 
  #if they are more than 1 word.
  #Conciders only outer quotes. Nested quotes are ignored
  # takes an array of words
  def isolateQuotedTerms(words)
    quotedWordsStack = []
    processedWords = []
    wordCount = 0
    while(wordCount < words.length) do
      sign = ""
      word = words[wordCount]
      lastCharacter = word[word.length-1]
      if(SearchRules::SIGNES.include?(word[0]))
        sign = word.slice!(0,1)    
      end
      firstCharacter = word[0]
      word = sign + word
      if(firstCharacter == "\"") 
        quotedWordsStack << word
      elsif(lastCharacter == "\"")    
        quotedWordsStack << word
        joinedPhrase = quotedWordsStack.join(" ")
        processedWords << joinedPhrase
        quotedWordsStack.clear
      elsif(!quotedWordsStack.empty?)
        quotedWordsStack << word
      else
        processedWords << word
      end
      wordCount = wordCount+1
    end
     quotedWordsStack.empty? ? processedWords:processedWords.concat(quotedWordsStack)  
  end
  
  def getSign
    if(SearchRules::SIGNES.include?(@@termsAndSigns.last))
      SearchRules::SIGNES[@@termsAndSigns.pop]
    else
      DefaultSign
    end  
  end
  
  def getInclRule
    if(SearchRules::INCLUSION_RULES.include?(@@rulesAndParen.last))
      SearchRules::INCLUSION_RULES[@@rulesAndParen.pop]
    else
      DefaultRule
    end
  end
  
  def getSignedTerm(term, signedHash)
    sign = getSign
    if(signedHash.has_key?(sign))
      signedHash[sign].unshift(term)
    else
      signedHash.merge!({sign => [term]})      
    end
    signedHash
  end
  
  def enterSignedTerm(term, rule, sign)
    hasFoundSign = false
    @@block[rule].map do |signedTerms|
      if(signedTerms[sign])
        signedTerms[sign].unshift(term)
        hasFoundSign = true
      end
    end
    if !hasFoundSign then @@block[rule] << {sign => [term]} end
  end
  
  def createBlock(term, rule, sign)
    if(rule && @@block.has_key?(rule))
      enterSignedTerm(term, rule, sign)
    elsif(rule)
      @@block.merge!({rule => [{sign => [term]}]})
    else
      @@block.merge!({sign => [term]})
    end  
  end
  
  def processBlock
    rule = nil
    while(@@rulesAndParen.last != "(")
      leftTerm = @@termsAndSigns.pop
      leftTermSign = getSign
      if SearchRules::INCLUSION_RULES.include?(@@rulesAndParen.last)
        rule = @@rulesAndParen.pop
      else
        logger.error("Could not find an inclusion rule")
      end
      createBlock(leftTerm, rule, leftTermSign)               
    end  
    rightTerm = @@termsAndSigns.pop
    rightTermSign = getSign
    createBlock(rightTerm, rule, rightTermSign) 
    @@rulesAndParen.pop
    @@termsAndSigns << @@block
    p @@termsAndSigns
    @@block.clear
  end
  
  def processCharacters(word)
    shavedWord = ""
    word.split('').map do |char|
      if(char == "(") 
        @@rulesAndParen << char
      elsif(SearchRules::SIGNES.include?(char))
        @@termsAndSigns << char
      elsif(char == ")") 
        @@termsAndSigns << shavedWord
        processBlock
        shavedWord = nil
      elsif(char == "\"")
        #do not do anything
      else
        shavedWord = shavedWord + char
      end
    end
    if(shavedWord)
      @@termsAndSigns << shavedWord
    end
  end
  
  def parse(rawInputString)
    @@block.clear
    words = isolateQuotedTerms(rawInputString.split(" "))
    words.each_with_index.map do |word, idx|
      if(SearchRules::INCLUSION_RULES.include?(word))
        @@rulesAndParen << word
      else
        processCharacters(word)
        if(idx < words.length - 1 && !SearchRules::INCLUSION_RULES.include?(words[idx + 1]))
          @@rulesAndParen << "and"
        end
      end
    end
    
    rule = SearchRules::INCLUSION_RULES[@@rulesAndParen.pop]  
    rightTerm = @@termsAndSigns.pop
    rightTermSign = getSign
    createBlock(rightTerm, rule, rightTermSign) 
    p "!!!"
    p rightTerm
    p @@termsAndSigns
    p @@block   
    while(!@@termsAndSigns.empty?)
      leftTerm = @@termsAndSigns.pop
      leftTermSign = getSign
      createBlock(leftTerm, rule, leftTermSign)                    
    end
    p "Here!!"
    p @@block
    @@block.to_json
  end
end