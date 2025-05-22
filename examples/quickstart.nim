import npeg, strutils, tables

type Dict = Table[string, int]

let parser = peg("pairs", d: Dict):
  pairs <- pair * *(',' * pair) * !1
  word <- +Alpha
  number <- +Digit
  pair <- >word * '=' * >number:
    d[$1] = parseInt($2)

var words: Dict
doAssert parser.match("one=1,two=2,three=3,four=4", words).ok
echo words

# Output:
# {"two": 2, "three": 3, "one": 1, "four": 4}