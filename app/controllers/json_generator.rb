require 'search_rules'
module Generator 
  include SearchRules
  
  DefaultRule = SearchRules::INCLUSION_RULES["AND"]
  DefaultSign = SearchRules::SIGNES['='] 
  
  def isLengthConstrain?(word) 
    pattern = Regexp.new("^len[(]\\d+[)]$").freeze
    pattern.match?(word)
  end
  
  def extractLengthConstrain(word)
    word.gsub("/(\(.*?\))/").to_i
  end
  
  #checks if a terms is a len or quoted and 
  #creates enters to the stack with according symbols
  #sign - a sign of a term (e.g "=", ">")
  #tern - a string 
  #signedTermStack - a collection of processed terms ([{"$eq" => "a"}])
  def enterTerm(sign, term, signedTermStack)
    if(isLengthConstrain?(term))
      len = extractLengthConstrain(term)
      signedTermStack.push({SearchRules::RULES["len"] => len})
    elsif(term.include?(" "))
      signedTermStack.push({sign => {SearchRules::QUOT => trimQuotes(term)}})
    else  
      signedTermStack.push({sign => term})
    end
  end
   
  #Removes the quotes from the string if they exist
  def trimQuotes(phrase)
    if(phrase[0] == "\"" && phrase[phrase.length-1] == "\"")
      phrase.slice(1, phrase.length-2)
    end
  end
  
  #Cobines terms under provided inclusion rules ("and", "or")
  #combinedTerms - a collection of combined terms under a incl rule
  #term - term with a sign
  #inclusionRule - the incl rule ("and"/"or")
  def combineTerms(combinedTerms, inclusionRule, term)   
    if(combinedTerms.has_key?(inclusionRule))
     combinedTerms[inclusionRule] << term
    else
      combinedTerms.merge!({inclusionRule => [term]})
    end
  end
    
  #Removes a sign (e.g. '=', '>') from the string if exists
  #word - a term string
  def removeSignIfExists(word)
    if(SearchRules::SIGNES.has_key?(word[0]))
      word = word.slice(1, word.length)  
    end
    word
  end
  
  #Checks if a term was provided with a sign. If not assigns the 
  #default one
  #word - a term string
  def getTermSign(word)
    if(SearchRules::SIGNES.has_key?(word[0]))
      SearchRules::SIGNES[word[0]]
    else 
      DefaultSign
    end        
  end
  
  #clears the array of signed terms and combines them with
  # an inclusion rule
  #signedTermStack - array of collected terms with signs
  #combinedTerms - collection of combined terms with a inclusion rule
  #rule - the inclusion rule
  def clearStackAndCombineTerms(signedTermStack, combinedTerms, rule)
    while(!signedTermStack.empty?)
      term = signedTermStack.shift
      combineTerms(combinedTerms, rule, term)
    end
  end
    
  #runs through the search string to isolate quoted terms 
  #if they are more than 1 word.
  #Conciders only outer quotes. Nested quotes are ignored
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
  
  def  combineWithCond(left, right, rule, stack)
    lastLayer = stack.last
    if(lastLayer && lastLayer.has_key?(rule))
     lastLayer[rule].concat([left, right])
    elsif(lastLayer)
      lastLayer.merge!({rule => [left, right]})
    else
      stack << {rule => [left, right]}
    end  
  end
  
  def transform(rawQuery)  
    signedTermStack = []
    inclRuleStack = []
    quotedWordsStack = []
    combinedTerms = Hash.new([])
    
    words = isolateQuotedTerms(rawQuery.split(" ")) 
    populatedTerms = words.map do |word|  
     if(SearchRules::INCLUSION_RULES.include?(word))
       inclusionRule = SearchRules::INCLUSION_RULES[word]
       if(signedTermStack.length > 1)
         clearStackAndCombineTerms(signedTermStack, combinedTerms, DefaultRule)
       end   
       inclRuleStack.push(inclusionRule)
     else
       sign = getTermSign(word)
       word = removeSignIfExists(word)
       enterTerm(sign, word, signedTermStack)  
       if(!inclRuleStack.empty?)
         rule = inclRuleStack.shift
         clearStackAndCombineTerms(signedTermStack, combinedTerms, rule) 
         signedTermStack.clear
       end
     end  
   end 
   if(signedTermStack.length > 1)
      clearStackAndCombineTerms(signedTermStack, combinedTerms, DefaultRule) 
   end
   if(combinedTerms.length > 0)
     combinedTerms
   else
     signedTermStack
   end 
 end
end