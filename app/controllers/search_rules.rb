module SearchRules 
  QUOT = "$quoted"
  LEN = "$len"

  UNARY_OPERATORS = {
    '=' => "$eq",
    '!' => "$not",
    '>' => "$gt",
    '<' => "$lt",
    '>=' => "$gte",
    '<=' => "$lte"
  }
  BINARY_OPERATORS = {
    "AND" => "$and",
    "OR" => "$or",
    "and" => "$and",
    "or" => "$or"
  }
  
  OPERATORS = UNARY_OPERATORS.merge(BINARY_OPERATORS)
  
end