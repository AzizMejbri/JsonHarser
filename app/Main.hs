{-# LANGUAGE LambdaCase #-}

module Main where

import Data.Char (isDigit, isHexDigit, isOctDigit, ord, isSpace)
import JsonUtils (fromHex, isBinaryDigit, isFloatMember, startsWith, skipSpaces, (<|>))
import qualified Data.Map as Map
import Data.List (intercalate)
import Control.Monad (guard)

data JsonValue
  = JsonNull
  | JsonString String
  | JsonInt Int
  | JsonBool Bool
  | JsonFloat Double
  | JsonArray [JsonValue]
  | JsonObject (Map.Map String JsonValue)
  deriving (Show, Eq)

type JsonParser = String -> Maybe (JsonValue, String)

skipComments :: String -> String
skipComments s = case s of
    '/' : '/' : xs -> skipToNewline xs
    _ -> s
  where
    skipToNewline xs = 
        let (_, rest) = span (/= '\n') xs
        in if null rest then "" else tail rest  

skipWhitespaceAndComments :: String -> String
skipWhitespaceAndComments s = 
    let s1 = skipSpaces s
    in if s1 /= s
        then skipWhitespaceAndComments s1  -- Keep skipping after spaces
        else case s1 of
            '/' : '/' : xs -> skipWhitespaceAndComments (skipToNewline xs)
            _ -> s1
  where
    skipToNewline xs = 
        let (_, rest) = span (/= '\n') xs
        in if null rest then "" else tail rest

parseWS :: (String -> Maybe (a, String)) -> String -> Maybe (a, String)
parseWS parser str = 
    let str' = skipWhitespaceAndComments str
    in case parser str' of
        Just (token, rest) -> Just (token, skipWhitespaceAndComments rest)
        Nothing -> Nothing

parseNull :: JsonParser
parseNull = parseWS $ \case
  'n':'u':'l':'l':xs -> Just (JsonNull, xs)
  _ -> Nothing

parseBool :: JsonParser
parseBool = parseWS $ \str -> 
    case startsWith "true" str of
        (True, rest) -> Just (JsonBool True, rest)
        _ -> case startsWith "false" str of
            (True, rest) -> Just (JsonBool False, rest)
            _ -> Nothing

parseStringValue :: String -> Maybe (String, String)
parseStringValue = parseWS $ \case
  '"' : xs -> 
      let (token, rest) = span (/= '"') xs
      in case rest of
          '"' : remaining -> Just (token, remaining)
          _ -> Nothing
  _ -> Nothing

parseInt :: JsonParser
parseInt = parseWS $ \case
  '0' : 'b' : xs -> 
      case span isBinaryDigit xs of
          ("", rest) -> Just (JsonInt 0, rest)
          (token, rest) -> Just (JsonInt (foldl (\acc c -> acc * 2 + (ord c - ord '0')) 0 token), rest)
  '0' : 'x' : xs -> 
      case span isHexDigit xs of
          ("", rest) -> Just (JsonInt 0, rest)
          (token, rest) -> Just (JsonInt (foldl (\acc c -> acc * 16 + fromHex c) 0 token), rest)
  '0' : 'o' : xs -> 
      case span isOctDigit xs of
          ("", rest) -> Just (JsonInt 0, rest)
          (token, rest) -> Just (JsonInt (foldl (\acc c -> acc * 8 + (ord c - ord '0')) 0 token), rest)
  s -> 
      case span isDigit s of
          ("", _) -> Nothing
          (token, rest) -> Just (JsonInt (foldl (\acc c -> acc * 10 + (ord c - ord '0')) 0 token), rest)

parseFloat :: JsonParser
parseFloat = parseWS $ \str ->
    -- Try to read as Double first
    case reads str :: [(Double, String)] of
        [(n, rest)] -> 
            -- Make sure we actually parsed a float (has decimal point or exponent)
            let strBefore = take (length str - length rest) str
            in if '.' `elem` strBefore || 'e' `elem` strBefore || 'E' `elem` strBefore
                then Just (JsonFloat n, rest)
                else Nothing  -- It was an integer, not a float
        _ -> Nothing

parseList :: JsonParser -> String -> Maybe ([JsonValue], String)
parseList elemParser = parseList' []
  where
    parseList' acc s = 
        case elemParser s of
            Nothing -> Just (reverse acc, s)  -- End of list
            Just (first, rest) -> 
                case skipWhitespaceAndComments rest of
                    ',' : s' -> parseList' (first:acc) (skipWhitespaceAndComments s')
                    _ -> Just (reverse (first:acc), rest)

parseArray :: JsonParser
parseArray = parseWS $ \case
  '[' : rest -> 
      case parseList parseJsonValue rest of
          Just (items, ']' : remaining) -> Just (JsonArray items, remaining)
          _ -> Nothing
  _ -> Nothing

-- Parse a key-value pair for objects
parseKeyValue :: String -> Maybe ((String, JsonValue), String)
parseKeyValue s = do
    (key, rest1) <- parseStringValue s
    case skipWhitespaceAndComments rest1 of
        ':' : rest2 -> do
            (value, rest3) <- parseJsonValue (skipWhitespaceAndComments rest2)
            Just ((key, value), rest3)
        _ -> Nothing

parseObjectItems :: String -> Maybe ([(String, JsonValue)], String)
parseObjectItems = parseObjectItems' []
  where
    parseObjectItems' acc s = 
        case parseKeyValue s of
            Nothing -> Just (reverse acc, s)  -- End of object
            Just (first, rest) -> 
                case skipWhitespaceAndComments rest of
                    ',' : s' -> parseObjectItems' (first:acc) (skipWhitespaceAndComments s')
                    _ -> Just (reverse (first:acc), rest)

parseObject :: JsonParser
parseObject = parseWS $ \case
  '{' : rest -> 
      case parseObjectItems rest of
          Just (items, '}' : remaining) -> Just (JsonObject (Map.fromList items), remaining)
          _ -> Nothing
  _ -> Nothing

parseJsonValue :: JsonParser
parseJsonValue s = 
    parseNull s <|>
    parseBool s <|>
    (do (str, rest) <- parseStringValue s; return (JsonString str, rest)) <|>
    parseFloat s <|>  -- Try float first
    parseInt s <|>
    parseArray s <|>
    parseObject s

-- Parse a complete JSON document
parseJson :: String -> Either String JsonValue
parseJson str = 
    let processed = skipWhitespaceAndComments str
    in case parseJsonValue processed of
        Just (value, remaining) -> 
            let remaining' = skipWhitespaceAndComments remaining
            in if null remaining'
                then Right value
                else Left $ "Unexpected content after JSON: '" ++ take 30 remaining' ++ "'..."
        Nothing -> Left "Failed to parse JSON"

prettyPrint :: JsonValue -> Int -> String
prettyPrint = go 
  where
    indentStr n = replicate (n * 2) ' '
    
    go JsonNull _ = "null"
    go (JsonString s) _ = "\"" ++ s ++ "\""
    go (JsonInt n) _ = show n
    go (JsonBool True) _ = "true"
    go (JsonBool False) _ = "false"
    go (JsonFloat f) _ = show f
    go (JsonArray arr) n =
        if null arr
        then "[]"
        else "[\n" ++ intercalate ",\n" (map (\x -> indentStr (n+1) ++ go x (n+1)) arr) ++ "\n" ++ indentStr n ++ "]"
    go (JsonObject obj) n =
        if Map.null obj
        then "{}"
        else "{\n" ++ intercalate ",\n" (map (\(k, v) -> indentStr (n+1) ++ "\"" ++ k ++ "\": " ++ go v (n+1)) (Map.toList obj)) ++ "\n" ++ indentStr n ++ "}"


main :: IO ()
main = do
    contents <- readFile "test.json"
    case parseJson contents of
        Right json -> do
            putStrLn "Success!"
            putStrLn $ "Parsed value: " ++ show json
            putStrLn "\nPretty printed:"
            putStrLn $ prettyPrint json 0
        Left err -> putStrLn $ "Error: " ++ err
    
