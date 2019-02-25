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

  # def isolateQuotedTerms(words)
  #   quotedWordsStack = []
  #   processedWords = []
  #   wordCount = 0
  #   while(wordCount < words.length) do
  #     sign = ""
  #     word = words[wordCount]
  #     lastCharacter = word[word.length-1]
  #     if(SearchRules::SIGNES.include?(word[0]))
  #       sign = word.slice!(0,1)
  #     end
  #     firstCharacter = word[0]
  #     word = sign + word
  #     if(firstCharacter == "\"") 
  #       quotedWordsStack << word
  #     elsif(lastCharacter == "\"")
  #       quotedWordsStack << word
  #       joinedPhrase = quotedWordsStack.join(" ")
  #       processedWords << joinedPhrase
  #       quotedWordsStack.clear
  #     elsif(!quotedWordsStack.empty?)
  #       quotedWordsStack << word
  #     else
  #       processedWords << word
  #     end
  #     wordCount = wordCount+1
  #   end
  #    quotedWordsStack.empty? ? processedWords:processedWords.concat(quotedWordsStack)  
  # end

  def splitIntoTokens(rawStr)
    tokenArray = []
    indx = 0
    token = ""
    while(indx < rawStr.length) do
      if(rawStr[indx] == ' ')
        if(token.length > 0)
          tokenArray << token
          token = ""
        end
        indx = indx + 1
      elsif (rawStr[indx] == '\"')
        token = ""
        indx = indx + 1
        while (indx < rawStr.length && rawStr[indx] != '\"') do
          token = token + rawStr[indx]
          indx = indx + 1
        end
        tokenArray << token
        indx = indx + 1
        token = ""
      elsif(rawStr[indx] == '(' || rawStr[indx] == ')' || rawStr[indx] == '!' || rawStr[indx] == '=' )
        tokenArray << rawStr[indx]
        indx = indx + 1
      elsif(rawStr[indx] == '<' || rawStr[indx] == '>')
        token = rawStr[indx]
        indx = indx + 1
        if(indx < rawStr.length && rawStr[indx] == '=')
          token = token + rawStr[indx]
          indx = indx + 1
        end
        tokenArray << token
        token = ""
      else
        token = token + rawStr[indx]
        indx = indx + 1
      end
    end
    if (token.length > 0)
      tokenArray << token
    end

      tokenArray
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
    while(@@rulesAndParen.length && @@rulesAndParen.last != "(")
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
    last = @@rulesAndParen.pop
    if last != "("
      logger.error("Missing '(' in rulesAndParen stack.")
    end
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
  
  def getPrecedence(op)
    precedence = 0
    if(SearchRules::BINARY_OPERATORS.include?(op))
      precedence = 1
    elsif(SearchRules::UNARY_OPERATORS.include?(op))
      precedence = 2
    end
    precedence
  end

  def convertToPostfix(tokens)
    expr = []
    opStack = []
    count = 0
    tokens.map do |tok|
      p ("#{count} tok #{tok}")
      count = count + 1
      
      if(tok == '(')
        opStack.push(tok)
      elsif(tok == ')')
        while(opStack.length > 0 && opStack.last != '(') do
          expr.push(opStack.pop)
          p ("expr.push #{count}")
          count = count + 1
        end
        opStack.pop
      #elsif(SearchRules::UNARY_OPERATORS.include?(tok) || SearchRules::BINARY_OPERATORS.include?(tok))
      elsif(SearchRules::OPERATORS.include?(tok))
        # an operator
        if(opStack.length == 0 || opStack.last == '(')
          opStack.push(tok)
        else
          while(opStack.length > 0 && opStack.last != '(') do
            if (getPrecedence(tok) <= getPrecedence(opStack.last))
              expr.push(opStack.pop)
            else
              break
            end
          end
          opStack.push(tok)
          
        end
      else
        # an operand
        expr.push(tok)
      end
    end
    
    p "last loop in convert"
    
    while(opStack.length != 0) do
      expr.push(opStack.pop)
    end
    
    p "finishing convert"
    expr
  end
  
  def parse(rawInputString)
    @@block.clear
    #words = isolateQuotedTerms(rawInputString.split(" "))
    
    p "raw input"
    p rawInputString
    
    words2 = splitIntoTokens(rawInputString)
    
    p "tokenized:"
    indx = 0
    while(indx < words2.length) do
      p words2[indx]
      indx = indx + 1
    end
    
    pfix = convertToPostfix(words2)
    p "postfix:"
    indx = 0
    while(indx < pfix.length) do
      p pfix[indx]
      indx = indx + 1
    end
    
    
    
    # words.each_with_index.map do |word, idx|
    #   if(SearchRules::INCLUSION_RULES.include?(word))
    #     @@rulesAndParen << word
    #   else
    #     processCharacters(word)
    #     if(idx < words.length - 1 && !SearchRules::INCLUSION_RULES.include?(words[idx + 1]))
    #       @@rulesAndParen << "and"
    #     end
    #   end
    # end
    
    # if(!@@block.empty?)
    #   @@termsAndSigns << @@block 
    #   @@block.clear
    # end
    # #byebug
    # while(!@@termsAndSigns.empty?)
    #   rule = SearchRules::INCLUSION_RULES[@@rulesAndParen.pop]  
    #   rightTerm = @@termsAndSigns.pop
    #   rightTermSign = getSign
    #   createBlock(rightTerm, rule, rightTermSign) 
    # 
    #   leftTerm = @@termsAndSigns.pop
    #   if leftTerm
    #     leftTermSign = getSign
    #     createBlock(leftTerm, rule, leftTermSign)  
    #   end                      
    # end
    
    @@block
  end
end