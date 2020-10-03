{-# LANGUAGE TypeFamilies #-}

module Example where


type family Hello a

type instance Hello Int = String
type instance Hello Bool = Int

exampleMsg :: String
exampleMsg = "Hello! This output proves the example project builds and runs."
