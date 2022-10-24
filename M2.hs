module M2 where

-- The NOINLINE comment is here to tell GHC not to inline this value, so that
-- we can change it without triggering downstream rebuilds.
greetTarget :: String
{-# NOINLINE greetTarget #-}
greetTarget = "world"
