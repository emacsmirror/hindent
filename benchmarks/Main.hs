{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Benchmark the pretty printer.
module Main where

import Control.DeepSeq
import Criterion
import Criterion.Main
import qualified Data.ByteString as S
import qualified Data.ByteString.Char8 as S8
import qualified Data.ByteString.UTF8 as UTF8
import HIndent
import HIndent.Internal.Test.Markdone

-- | Main benchmarks.
main :: IO ()
main = do
  bytes <- S.readFile "BENCHMARKS.md"
  !forest <- fmap force (parse (tokenize bytes))
  defaultMain (toCriterion forest)

-- | Convert the Markdone document to Criterion benchmarks.
toCriterion :: [Markdone] -> [Benchmark]
toCriterion = go
  where
    go (Section name children:next) =
      bgroup (S8.unpack name) (go children) : go next
    go (PlainText desc:CodeFence lang code:next) =
      if lang == "haskell"
        then bench
               (UTF8.toString desc)
               (nf
                  (either (error . show) id
                     . reformat HIndent.defaultConfig defaultExtensions Nothing)
                  code)
               : go next
        else go next
    go (PlainText {}:next) = go next
    go (CodeFence {}:next) = go next
    go [] = []
