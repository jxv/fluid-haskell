{-# OPTIONS_GHC -fno-warn-dodgy-imports #-}
{-# LANGUAGE DeriveGeneric #-}
module Fluid.Types
  ( Version(..)
  , Major(..)
  , Minor(..)
  , Pull(..)
  , pullAddress
  , RuntimeError(..)
  , Hooks(..)
  , Limits(..)
  , defLimits
  , defHooks
  --
  , Symbol(..)
  , Type(..)
  , TypeName(..)
  , EnumeralName(..)
  , MemberName(..)
  , Const(..)
  , Infer(..)
  --
  , HasType(..)
  ) where

import qualified Data.HashMap.Lazy as HML
import Control.Monad (mzero)
import Data.Aeson
import Data.Text (Text)
import Data.Text.Conversions (toText)
import Data.String (IsString(..))
import Data.Scientific
import Data.Proxy
import GHC.Generics

newtype Major = Major Int
  deriving (Show, Eq, Generic, Num, Ord, Real, Integral, Enum)

instance FromJSON Major
instance ToJSON Major

newtype Minor = Minor Int
  deriving (Show, Eq, Generic, Num, Ord, Real, Integral, Enum)

instance FromJSON Minor
instance ToJSON Minor

data Pull = Pull
  { protocol :: Text
  , host :: Text
  , path :: Text
  , port :: Int
  } deriving (Show, Eq)

pullAddress :: Pull -> Text
pullAddress Pull{port,host,protocol,path} = mconcat [protocol, "://", host, ":", toText $ show port,  path]

data Version = Version
  { major :: Major
  , minor :: Minor
  } deriving (Show, Eq, Generic)

instance ToJSON Version
instance FromJSON Version

data RuntimeError
  = RuntimeError'UnparsableFormat
  | RuntimeError'UnrecognizedCall TypeName
  | RuntimeError'VariableLimit
  | RuntimeError'LangServiceCallLimit Int
  | RuntimeError'LangLambdaLimit Int
  | RuntimeError'LangExprLimit Int
  | RuntimeError'UnknownVariable Text
  | RuntimeError'IncompatibleType
  | RuntimeError'MissingMatchCase
  | RuntimeError'TooFewArguments
  | RuntimeError'TooManyArguments
  | RuntimeError'NoApiVersion
  | RuntimeError'NoFluidVersion
  | RuntimeError'ApiMajorVersionTooLow
  | RuntimeError'ApiMajorVersionTooHigh
  | RuntimeError'ApiMinorVersionTooHigh
  | RuntimeError'FluidMajorVersionTooLow
  | RuntimeError'FluidMajorVersionTooHigh
  | RuntimeError'FluidMinorVersionTooHigh
  | RuntimeError'UnparsableMeta
  | RuntimeError'UnparsableQuery
  | RuntimeError'NoImplementation
  | RuntimeError'NotMember
  deriving (Show, Eq)

instance ToJSON RuntimeError where
  toJSON = \case
    RuntimeError'UnparsableFormat -> e "UnparsableFormat"
    RuntimeError'UnrecognizedCall n -> object [ "tag" .= String "UnrecognizedCall", "name" .= n ]
    RuntimeError'VariableLimit -> e "VariableLimit"
    RuntimeError'LangExprLimit l -> object [ "tag" .= String "LangExprLimit", "limit" .= l ]
    RuntimeError'LangLambdaLimit l -> object [ "tag" .= String "LangLambdaLimit", "limit" .= l ]
    RuntimeError'LangServiceCallLimit l -> object [ "tag" .= String "LangServiceCallLimit", "limit" .= l ]
    RuntimeError'UnknownVariable m -> object [ "tag" .= String "UnknownVariable", "name" .= m ]
    RuntimeError'IncompatibleType -> e "IncompatibleType"
    RuntimeError'MissingMatchCase -> e "MissingMatchCase"
    RuntimeError'TooFewArguments -> e "TooFewArguments"
    RuntimeError'TooManyArguments -> e "TooManyArguments"
    RuntimeError'NoApiVersion -> e "NoApiVersion"
    RuntimeError'NoFluidVersion -> e "NoFluidVersion"
    RuntimeError'ApiMajorVersionTooHigh -> e "ApiMajorVersionTooHigh"
    RuntimeError'ApiMajorVersionTooLow -> e "ApiMajorVersionTooLow"
    RuntimeError'ApiMinorVersionTooHigh -> e "ApiMinorVersionTooHigh"
    RuntimeError'FluidMajorVersionTooHigh -> e "FluidMajorVersionTooHigh"
    RuntimeError'FluidMajorVersionTooLow -> e "FluidMajorVersionTooLow"
    RuntimeError'FluidMinorVersionTooHigh -> e "FluidMinorVersionTooHigh"
    RuntimeError'UnparsableMeta -> e "UnparsableMeta"
    RuntimeError'UnparsableQuery -> e "UnparsableQuery"
    RuntimeError'NoImplementation -> e "NoImplementation"
    RuntimeError'NotMember -> e "NotMember"
    where
      e s = object [ "tag" .= String s ]

instance FromJSON RuntimeError where
  parseJSON (Object o) = do
    tag <- o .: "tag"
    case tag :: Text of
      "UnparsableFormat" -> pure RuntimeError'UnparsableFormat
      "UnrecognizedCall" -> RuntimeError'UnrecognizedCall <$> o .: "name"
      "VariableLimit" -> pure RuntimeError'VariableLimit
      "LangExprLimit" -> RuntimeError'LangExprLimit <$> o .: "limit"
      "LangLambdaLimit" -> RuntimeError'LangLambdaLimit <$> o .: "limit"
      "LangServiceCallLimit" -> RuntimeError'LangServiceCallLimit <$> o .: "limit"
      "UnknownVariable" -> RuntimeError'UnknownVariable <$> o .: "name"
      "IncompatibleType" -> pure RuntimeError'IncompatibleType
      "MissingMatchCase" -> pure RuntimeError'MissingMatchCase
      "TooFewArguments" -> pure RuntimeError'TooFewArguments
      "TooManyArguments" -> pure RuntimeError'TooManyArguments
      "NoApiVersion" -> pure RuntimeError'NoApiVersion
      "NoFluidVersion" -> pure RuntimeError'NoFluidVersion
      "ApiMajorVersionTooHigh" -> pure RuntimeError'ApiMajorVersionTooHigh
      "ApiMajorVersionTooLow" -> pure RuntimeError'ApiMajorVersionTooLow
      "ApiMinorVersionTooHigh" -> pure RuntimeError'ApiMinorVersionTooHigh
      "FluidMajorVersionTooHigh" -> pure RuntimeError'FluidMajorVersionTooHigh
      "FluidMajorVersionTooLow" -> pure RuntimeError'FluidMajorVersionTooLow
      "FluidMinorVersionTooHigh" -> pure RuntimeError'FluidMinorVersionTooHigh
      "UnparsableMeta" -> pure RuntimeError'UnparsableMeta
      "UnparsableQuery" -> pure RuntimeError'UnparsableQuery
      "NoImplementation" -> pure RuntimeError'NoImplementation
      "NotMember" -> pure RuntimeError'NotMember
      _ -> mzero
  parseJSON _ = mzero

data Limits = Limits
  { variables :: Maybe Int
  , serviceCalls :: Maybe Int
  , lambdas :: Maybe Int
  , expressions :: Maybe Int
  } deriving (Show, Eq, Generic)

instance ToJSON Limits
instance FromJSON Limits

defLimits :: Limits
defLimits = Limits
  { variables = Just 50
  , serviceCalls = Just 50
  , lambdas = Just 10
  , expressions = Just 100
  }

data Hooks m meta meta' = Hooks
  { metaMiddleware :: meta -> m meta'
  , sandboxLimits :: meta' -> m Limits
  }

defHooks :: Monad m => Hooks m meta meta
defHooks = Hooks
  { metaMiddleware = return
  , sandboxLimits = \_ -> return defLimits
  }

--

newtype Symbol = Symbol Text
  deriving (Show, Eq, Ord, FromJSON, ToJSON, ToJSONKey, FromJSONKey, IsString)

data Type = Type
  { n :: TypeName
  , p :: [Type]
  , o :: Maybe Type
  } deriving (Show, Eq)

instance IsString Type where
  fromString s = Type (fromString s) [] Nothing

instance FromJSON Type where
  parseJSON = \case
    String s -> pure $ Type (TypeName s) [] Nothing
    Object o -> do
      n <- o .: "n"
      case (HML.lookup "p" o, HML.lookup "o" o) of
        (Nothing, Nothing) -> pure $ Type n [] Nothing
        (Just (String p), Nothing) -> pure $ Type n [Type (TypeName p) [] Nothing] Nothing
        (Just p, Nothing) -> Type n <$> (parseJSON p) <*> pure Nothing
        (Just (String p), Just output) -> Type n [Type (TypeName p) [] Nothing] <$> (Just <$> parseJSON output)
        (Just p, Just output) -> Type n <$> (parseJSON p) <*> (Just <$> parseJSON output)
        _ -> mzero
    _ -> mzero

instance ToJSON Type where
  toJSON (Type n [] Nothing) = toJSON n
  toJSON (Type n [] (Just o)) = object [ "n" .= n, "o" .= toJSON o ]
  toJSON (Type n [p] Nothing) = object [ "n" .= n, "p" .= toJSON p ]
  toJSON (Type n [p] (Just o)) = object [ "n" .= n, "p" .= toJSON p, "o" .= toJSON o]
  toJSON (Type n ps Nothing) = object [ "n" .= n, "p" .= map toJSON ps ]
  toJSON (Type n ps (Just o)) = object [ "n" .= n, "p" .= map toJSON ps, "o" .= toJSON o ]

newtype TypeName = TypeName Text
  deriving (Show, Eq, Ord, FromJSON, ToJSON, IsString)

newtype EnumeralName = EnumeralName Text
  deriving (Show, Eq, Ord, FromJSON, ToJSON, ToJSONKey, FromJSONKey, IsString)

newtype MemberName = MemberName Text
  deriving (Show, Eq, Ord, FromJSON, ToJSON, ToJSONKey, FromJSONKey, IsString)

data Const
  = Const'Null
  | Const'Bool Bool
  | Const'String Text
  | Const'Number Scientific
  deriving (Show, Eq)

instance ToJSON Const where
  toJSON = \case
    Const'Null -> Null
    Const'Bool b -> Bool b
    Const'String s -> String s
    Const'Number n -> Number n

instance FromJSON Const where
  parseJSON = \case
    Null -> pure $ Const'Null
    Bool b -> pure $ Const'Bool b
    String s -> pure $ Const'String s
    Number n -> pure $ Const'Number n
    _ -> mzero

data Infer
  = Infer'Null
  | Infer'Number Scientific
  deriving (Show, Eq)

instance ToJSON Infer where
  toJSON = \case
    Infer'Null -> Null
    Infer'Number n -> Number n

instance FromJSON Infer where
  parseJSON = \case
    Null -> pure $ Infer'Null
    Number n -> pure $ Infer'Number n
    _ -> mzero

class HasType a where
  getType :: Proxy a -> Type

instance HasType () where
  getType _ = "Unit"

instance HasType Bool where
  getType _ = "Bool"

instance HasType Text where
  getType _ = "String"

instance HasType Int where
  getType _ = "Int"

instance HasType Double where
  getType _ = "Float"

instance HasType a => HasType (Maybe a) where
  getType x = Type "Option" [getType (p x)] Nothing
    where
      p :: Proxy (Maybe a) -> Proxy a
      p _ = Proxy

instance HasType a => HasType [a] where
  getType x = Type "List" [getType (p x)] Nothing
    where
      p :: Proxy [a] -> Proxy a
      p _ = Proxy

instance (HasType e, HasType a) => HasType (Either e a) where
  getType x = Type "Either" [getType (p1 x), getType (p2 x)] Nothing
    where
      p1 :: Proxy (Either e a) -> Proxy e
      p1 _ = Proxy
      p2 :: Proxy (Either e a) -> Proxy a
      p2 _ = Proxy

--

instance (HasType t1, HasType t2) => HasType (t1, t2) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x)] Nothing
     where
       p1 :: Proxy (t1, t2) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2) -> Proxy t2
       p2 _ = Proxy

instance (HasType t1, HasType t2, HasType t3) => HasType (t1, t2, t3) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3) -> Proxy t3
       p3 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4) => HasType (t1, t2, t3, t4) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4) -> Proxy t4
       p4 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5) => HasType (t1, t2, t3, t4, t5) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5) -> Proxy t5
       p5 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6) => HasType (t1, t2, t3, t4, t5, t6) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6) -> Proxy t6
       p6 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7) => HasType (t1, t2, t3, t4, t5, t6, t7) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7) -> Proxy t7
       p7 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8) => HasType (t1, t2, t3, t4, t5, t6, t7, t8) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8) -> Proxy t8
       p8 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9) -> Proxy t9
       p9 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10) -> Proxy t10
       p10 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11) -> Proxy t11
       p11 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12) -> Proxy t12
       p12 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13) -> Proxy t13
       p13 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14) -> Proxy t14
       p14 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15) -> Proxy t15
       p15 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16) -> Proxy t16
       p16 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17) -> Proxy t17
       p17 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18) -> Proxy t18
       p18 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19) -> Proxy t19
       p19 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19, HasType t20) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x), getType (p20 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t19
       p19 _ = Proxy
       p20 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20) -> Proxy t20
       p20 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19, HasType t20, HasType t21) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x), getType (p20 x), getType (p21 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t19
       p19 _ = Proxy
       p20 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t20
       p20 _ = Proxy
       p21 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21) -> Proxy t21
       p21 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19, HasType t20, HasType t21, HasType t22) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x), getType (p20 x), getType (p21 x), getType (p22 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t19
       p19 _ = Proxy
       p20 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t20
       p20 _ = Proxy
       p21 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t21
       p21 _ = Proxy
       p22 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22) -> Proxy t22
       p22 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19, HasType t20, HasType t21, HasType t22, HasType t23) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x), getType (p20 x), getType (p21 x), getType (p22 x), getType (p23 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t19
       p19 _ = Proxy
       p20 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t20
       p20 _ = Proxy
       p21 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t21
       p21 _ = Proxy
       p22 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t22
       p22 _ = Proxy
       p23 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23) -> Proxy t23
       p23 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19, HasType t20, HasType t21, HasType t22, HasType t23, HasType t24) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x), getType (p20 x), getType (p21 x), getType (p22 x), getType (p23 x), getType (p24 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t19
       p19 _ = Proxy
       p20 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t20
       p20 _ = Proxy
       p21 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t21
       p21 _ = Proxy
       p22 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t22
       p22 _ = Proxy
       p23 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t23
       p23 _ = Proxy
       p24 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24) -> Proxy t24
       p24 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19, HasType t20, HasType t21, HasType t22, HasType t23, HasType t24, HasType t25) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x), getType (p20 x), getType (p21 x), getType (p22 x), getType (p23 x), getType (p24 x), getType (p25 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t19
       p19 _ = Proxy
       p20 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t20
       p20 _ = Proxy
       p21 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t21
       p21 _ = Proxy
       p22 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t22
       p22 _ = Proxy
       p23 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t23
       p23 _ = Proxy
       p24 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t24
       p24 _ = Proxy
       p25 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25) -> Proxy t25
       p25 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19, HasType t20, HasType t21, HasType t22, HasType t23, HasType t24, HasType t25, HasType t26) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x), getType (p20 x), getType (p21 x), getType (p22 x), getType (p23 x), getType (p24 x), getType (p25 x), getType (p26 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t19
       p19 _ = Proxy
       p20 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t20
       p20 _ = Proxy
       p21 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t21
       p21 _ = Proxy
       p22 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t22
       p22 _ = Proxy
       p23 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t23
       p23 _ = Proxy
       p24 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t24
       p24 _ = Proxy
       p25 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t25
       p25 _ = Proxy
       p26 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26) -> Proxy t26
       p26 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19, HasType t20, HasType t21, HasType t22, HasType t23, HasType t24, HasType t25, HasType t26, HasType t27) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x), getType (p20 x), getType (p21 x), getType (p22 x), getType (p23 x), getType (p24 x), getType (p25 x), getType (p26 x), getType (p27 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t19
       p19 _ = Proxy
       p20 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t20
       p20 _ = Proxy
       p21 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t21
       p21 _ = Proxy
       p22 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t22
       p22 _ = Proxy
       p23 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t23
       p23 _ = Proxy
       p24 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t24
       p24 _ = Proxy
       p25 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t25
       p25 _ = Proxy
       p26 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t26
       p26 _ = Proxy
       p27 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27) -> Proxy t27
       p27 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19, HasType t20, HasType t21, HasType t22, HasType t23, HasType t24, HasType t25, HasType t26, HasType t27, HasType t28) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x), getType (p20 x), getType (p21 x), getType (p22 x), getType (p23 x), getType (p24 x), getType (p25 x), getType (p26 x), getType (p27 x), getType (p28 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t19
       p19 _ = Proxy
       p20 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t20
       p20 _ = Proxy
       p21 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t21
       p21 _ = Proxy
       p22 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t22
       p22 _ = Proxy
       p23 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t23
       p23 _ = Proxy
       p24 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t24
       p24 _ = Proxy
       p25 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t25
       p25 _ = Proxy
       p26 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t26
       p26 _ = Proxy
       p27 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t27
       p27 _ = Proxy
       p28 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28) -> Proxy t28
       p28 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19, HasType t20, HasType t21, HasType t22, HasType t23, HasType t24, HasType t25, HasType t26, HasType t27, HasType t28, HasType t29) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x), getType (p20 x), getType (p21 x), getType (p22 x), getType (p23 x), getType (p24 x), getType (p25 x), getType (p26 x), getType (p27 x), getType (p28 x), getType (p29 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t19
       p19 _ = Proxy
       p20 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t20
       p20 _ = Proxy
       p21 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t21
       p21 _ = Proxy
       p22 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t22
       p22 _ = Proxy
       p23 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t23
       p23 _ = Proxy
       p24 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t24
       p24 _ = Proxy
       p25 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t25
       p25 _ = Proxy
       p26 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t26
       p26 _ = Proxy
       p27 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t27
       p27 _ = Proxy
       p28 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t28
       p28 _ = Proxy
       p29 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29) -> Proxy t29
       p29 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19, HasType t20, HasType t21, HasType t22, HasType t23, HasType t24, HasType t25, HasType t26, HasType t27, HasType t28, HasType t29, HasType t30) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x), getType (p20 x), getType (p21 x), getType (p22 x), getType (p23 x), getType (p24 x), getType (p25 x), getType (p26 x), getType (p27 x), getType (p28 x), getType (p29 x), getType (p30 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t19
       p19 _ = Proxy
       p20 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t20
       p20 _ = Proxy
       p21 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t21
       p21 _ = Proxy
       p22 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t22
       p22 _ = Proxy
       p23 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t23
       p23 _ = Proxy
       p24 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t24
       p24 _ = Proxy
       p25 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t25
       p25 _ = Proxy
       p26 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t26
       p26 _ = Proxy
       p27 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t27
       p27 _ = Proxy
       p28 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t28
       p28 _ = Proxy
       p29 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t29
       p29 _ = Proxy
       p30 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30) -> Proxy t30
       p30 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19, HasType t20, HasType t21, HasType t22, HasType t23, HasType t24, HasType t25, HasType t26, HasType t27, HasType t28, HasType t29, HasType t30, HasType t31) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x), getType (p20 x), getType (p21 x), getType (p22 x), getType (p23 x), getType (p24 x), getType (p25 x), getType (p26 x), getType (p27 x), getType (p28 x), getType (p29 x), getType (p30 x), getType (p31 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t19
       p19 _ = Proxy
       p20 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t20
       p20 _ = Proxy
       p21 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t21
       p21 _ = Proxy
       p22 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t22
       p22 _ = Proxy
       p23 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t23
       p23 _ = Proxy
       p24 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t24
       p24 _ = Proxy
       p25 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t25
       p25 _ = Proxy
       p26 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t26
       p26 _ = Proxy
       p27 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t27
       p27 _ = Proxy
       p28 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t28
       p28 _ = Proxy
       p29 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t29
       p29 _ = Proxy
       p30 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t30
       p30 _ = Proxy
       p31 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31) -> Proxy t31
       p31 _ = Proxy

instance (HasType t1, HasType t2, HasType t3, HasType t4, HasType t5, HasType t6, HasType t7, HasType t8, HasType t9, HasType t10, HasType t11, HasType t12, HasType t13, HasType t14, HasType t15, HasType t16, HasType t17, HasType t18, HasType t19, HasType t20, HasType t21, HasType t22, HasType t23, HasType t24, HasType t25, HasType t26, HasType t27, HasType t28, HasType t29, HasType t30, HasType t31, HasType t32) => HasType (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) where
  getType x = Type "Tuple" [getType (p1 x), getType (p2 x), getType (p3 x), getType (p4 x), getType (p5 x), getType (p6 x), getType (p7 x), getType (p8 x), getType (p9 x), getType (p10 x), getType (p11 x), getType (p12 x), getType (p13 x), getType (p14 x), getType (p15 x), getType (p16 x), getType (p17 x), getType (p18 x), getType (p19 x), getType (p20 x), getType (p21 x), getType (p22 x), getType (p23 x), getType (p24 x), getType (p25 x), getType (p26 x), getType (p27 x), getType (p28 x), getType (p29 x), getType (p30 x), getType (p31 x), getType (p32 x)] Nothing
     where
       p1 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t1
       p1 _ = Proxy
       p2 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t2
       p2 _ = Proxy
       p3 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t3
       p3 _ = Proxy
       p4 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t4
       p4 _ = Proxy
       p5 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t5
       p5 _ = Proxy
       p6 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t6
       p6 _ = Proxy
       p7 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t7
       p7 _ = Proxy
       p8 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t8
       p8 _ = Proxy
       p9 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t9
       p9 _ = Proxy
       p10 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t10
       p10 _ = Proxy
       p11 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t11
       p11 _ = Proxy
       p12 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t12
       p12 _ = Proxy
       p13 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t13
       p13 _ = Proxy
       p14 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t14
       p14 _ = Proxy
       p15 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t15
       p15 _ = Proxy
       p16 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t16
       p16 _ = Proxy
       p17 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t17
       p17 _ = Proxy
       p18 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t18
       p18 _ = Proxy
       p19 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t19
       p19 _ = Proxy
       p20 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t20
       p20 _ = Proxy
       p21 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t21
       p21 _ = Proxy
       p22 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t22
       p22 _ = Proxy
       p23 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t23
       p23 _ = Proxy
       p24 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t24
       p24 _ = Proxy
       p25 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t25
       p25 _ = Proxy
       p26 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t26
       p26 _ = Proxy
       p27 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t27
       p27 _ = Proxy
       p28 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t28
       p28 _ = Proxy
       p29 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t29
       p29 _ = Proxy
       p30 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t30
       p30 _ = Proxy
       p31 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t31
       p31 _ = Proxy
       p32 :: Proxy (t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, t19, t20, t21, t22, t23, t24, t25, t26, t27, t28, t29, t30, t31, t32) -> Proxy t32
       p32 _ = Proxy

{-

var tuples = [2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32];

var hasTypeTuple = n => {
  if (n < 2) {
    return '';
  }

  var l = ['\n',
    'instance (HasType t1'
  ];
  for (var i = 1; i < n; i++) {
    l = l.concat([', HasType t', i + 1]);
  }
  l = l.concat([') => HasType (t1']);
  for (var i = 1; i < n; i++) {
    l = l.concat([', t', i + 1]);
  }
  l = l.concat([') where\n']);

  l = l.concat(['  getType x = Type "Tuple" [getType (p1 x)']);
  for (var i = 1; i < n; i++) {
    l = l.concat([', getType (p', i + 1, ' x)']);
  }
  l = l.concat(['] Nothing\n']);


  l = l.concat(['     where\n']);
  var f = ['(t1'];
  for (var i = 1; i < n; i++) {
    f  = f.concat([', t', i + 1]);
  }
  f = f.concat([')']).join('');
  for (var i = 0; i < n; i++) {
    l = l.concat([
      '       p', i + 1, ' :: Proxy ', f, ' -> Proxy t', i + 1, '\n',
      '       p', i + 1, ' _ = Proxy\n',
    ]);
  }

  return l.join('');
};

-}
