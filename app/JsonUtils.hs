module JsonUtils 
  (
    toInt,
    fromHex,
    isBinaryDigit,
    isFloatMember,
    (<|>),
    startsWith,
    skipSpaces
  ) where
import Data.Char (ord, isDigit, isSpace, toLower)

toInt :: Char -> Int
toInt c = ord c - ord '0' 

-- Improved fromHex using pattern matching with toLower
fromHex :: Char -> Int
fromHex c = case toLower c of
    '0' -> 0
    '1' -> 1
    '2' -> 2
    '3' -> 3
    '4' -> 4
    '5' -> 5
    '6' -> 6
    '7' -> 7
    '8' -> 8
    '9' -> 9
    'a' -> 10
    'b' -> 11
    'c' -> 12
    'd' -> 13
    'e' -> 14
    'f' -> 15
    _ -> error $ "Invalid hex digit: " ++ show c

isBinaryDigit :: Char -> Bool
isBinaryDigit c = c == '0' || c == '1'

-- Enhanced to handle scientific notation (e, E, +, -)
isFloatMember :: Char -> Bool
isFloatMember '.' = True 
isFloatMember 'e' = True
isFloatMember 'E' = True
isFloatMember '+' = True
isFloatMember '-' = True
isFloatMember x = isDigit x

infixl 3 <|>
(<|>) :: Maybe a -> Maybe a -> Maybe a 
(Just x) <|> _ = Just x 
Nothing <|> y = y

startsWith :: String -> String -> (Bool, String)
startsWith pattern str
    | pattern == take n str = (True, drop n str)
    | otherwise = (False, "")
    where 
      n = length pattern 

-- New function: skip whitespace (spaces, tabs, newlines)
skipSpaces :: String -> String
skipSpaces = dropWhile isSpace

