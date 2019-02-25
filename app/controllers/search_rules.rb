module SearchRules 
  QUOT = "$quoted"
  SIGNES = {
    '=' => "$eq",
    '!' => "$not",
    '>' => "$gt",
    '<' => "$lt",
    '>=' => "$gte",
    '<=' => "$lte"
  }
  INCLUSION_RULES = {
    "AND" => "$and",
    "OR" => "$or",
    "and" => "$and",
    "or" => "$or"
  }
  RULES = {
    "EQ" => "$eq",
    "NOT" => "$not",
    "GT" => "$gt",
    "LT" => "$lt",
    "GTE" => "$gte",
    "LTE" => "$lte",
    "LEN" => "$len"
  }

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