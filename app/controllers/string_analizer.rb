require 'search_rules'
module StringAnalizer
  include SearchRules
  
  @@block = {}
   
  #Finds all defined tokens and puts them into tokenArray
  #rawStr - the input string
  #returns array of tokens that are defined in the string
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
      elsif (rawStr[indx] == "\"")
        token = "\""
        indx = indx + 1
        while (indx < (rawStr.length) && rawStr[indx] != "\"") do
          token = token + rawStr[indx]
          indx = indx + 1
        end
        token = token + "\""
        indx = indx + 1
        tokenArray << token
        token = ""
      elsif(indx+5 < rawStr.length && rawStr[indx..indx+3] == "len(")
        if(token.length > 0)
          tokenArray << token
          token = ""
        end
        while(indx < rawStr.length && rawStr[indx] != ')') do
          token = token + rawStr[indx]
          indx = indx + 1
        end
        token = token + rawStr[indx]
        indx = indx + 1
        tokenArray << token
        token = ""
      elsif(rawStr[indx] == '(' || rawStr[indx] == ')' || rawStr[indx] == '!' || rawStr[indx] == '=' )
        if(token.length > 0)
          tokenArray << token
          token = ""
        end
        tokenArray << rawStr[indx]
        indx = indx + 1
      elsif(rawStr[indx] == '<' || rawStr[indx] == '>')
        if(token.length > 0)
          tokenArray << token
        end
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

  #takes the array of tokens and inserts '=' unless any other unary operator
  #is found in front of an operand or a '('
  # tokensIn - array of already defined tokens
  # returns tokensOut - array with inserted default '='
  def insertDefaultEqualOperators(tokensIn)
    tokensOut = []
    tokensIn.each_with_index.map do |tok, indx|
      if(SearchRules::OPERATORS.include?(tok) || tok == ')')
        # Found an operator or ')' : copy as is
        tokensOut.push(tok)
      else
        # Found 'operand' or '(' : if previous token is not unary operator
        # then insert default '=' operator before it
        if(indx == 0 || !SearchRules::UNARY_OPERATORS.include?(tokensIn[indx-1]))
          tokensOut.push('=')
        end
        tokensOut.push(tok)
      end
    end
    tokensOut
  end
  
  # Assumes that default '=' operators have been already inserted!
  # i.e. every operand is preceded by a unary operator 
  # tokensIn - array with inserted default '='
  # tokensOut - array with inserted default 'and'
  def insertDefaultAndOperators(tokensIn)
    tokensOut = []
    tokensIn.each_with_index.map do |tok, indx|
      if(SearchRules::UNARY_OPERATORS.include?(tok))
        # Found Unary Operator: copy it and check
        # if previous token is not an operator or '(',
        # then insert default 'AND' before it
        if(indx > 0 && !SearchRules::OPERATORS.include?(tokensIn[indx-1]) && tokensIn[indx-1] != '(')
          tokensOut.push('AND')
        end
        tokensOut.push(tok)
      else
        # For all other tokens: copy as is
        tokensOut.push(tok)
      end
    end
    tokensOut
  end
  
  #returns precedence of an operator
  def getPrecedence(op)
    precedence = 0
    if(SearchRules::BINARY_OPERATORS.include?(op))
      precedence = 1
    elsif(SearchRules::UNARY_OPERATORS.include?(op))
      precedence = 2
    end
    precedence
  end
 
  #relocates the elements so their location matches this pattern
  #"left, leftUnary, right, rightUnary, binary Op"
  # tokens - array of all tokens including default ones
  # reurns a postfix expression
  def convertToPostfix(tokens)
    expr = []
    opStack = []
    count = 0
    tokens.map do |tok|
      
      count = count + 1
      
      if(tok == '(')
        opStack.push(tok)
      elsif(tok == ')')
        while(opStack.length > 0 && opStack.last != '(') do
          expr.push(opStack.pop)
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
    while(opStack.length != 0) do
      expr.push(opStack.pop)
    end
    expr
  end
 
  #evaluates postfix expr. Connects operands with their perators
  #pfixExpr - post fix array
  #hash map with binary op as keys and arrays of hashes as values.
  #hashes in the array consists of keys as unary op and operand as values
  def evaluate(pfixExpr)
    hashStack = []
    pfixExpr.map do |tok|
      if(SearchRules::BINARY_OPERATORS.include?(tok))
        rightOperand = hashStack.pop
        leftOperand = hashStack.pop
        hashStack.push({SearchRules::BINARY_OPERATORS[tok] => [leftOperand, rightOperand]})
      elsif(SearchRules::UNARY_OPERATORS.include?(tok))
        rightOperand = hashStack.pop
        hashStack.push({SearchRules::UNARY_OPERATORS[tok] => rightOperand})
      else
        if(tok[0] == "\"" && tok[-1] == "\"")
          hashStack.push({QUOT => tok[1..-2]})
        elsif(tok.length > 5 && tok[0..3] == "len(")
          hashStack.push( {LEN => tok[4..-2].to_i} )
        elsif (tok == "false")
          hashStack.push(false)
        elsif (tok == "true")
          hashStack.push(true)
        else
          hashStack.push(tok)
        end
      end
    end
    hashStack.pop
  end
    
  #clears the resulting block everytime when called.
  #rawInputString takes the string from the url
  #returns hash with evaluated expression
  def parse(rawInputString)
    @@block.clear
    tokensSimple = splitIntoTokens(rawInputString)
    tokensWithEqualOps = insertDefaultEqualOperators(tokensSimple)
    tokensComplete = insertDefaultAndOperators(tokensWithEqualOps)
  
    indx = 0
    tmpStr = ""
    while(indx < tokensComplete.length) do
      tmpStr = tmpStr + tokensComplete[indx] + ", "
      indx = indx + 1
    end      
    tokensPostfix = convertToPostfix(tokensComplete)    
    finalHash = evaluate(tokensPostfix)  
    finalHash
  end
end