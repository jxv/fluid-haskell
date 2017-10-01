{-# LANGUAGE DeriveGeneric #-}
module Colorless.Types
  ( Version(..)
  , Major(..)
  , Minor(..)
  , Request(..)
  , Response(..)
  , ResponseError(..)
  , RuntimeError(..)
  , RuntimeThrower(..)
  , Options(..)
  --
  , Symbol(..)
  , Type(..)
  , TypeName(..)
  , EnumeralName(..)
  , MemberName(..)
  , Const(..)
  --
  , HasType(..)
  ) where

import qualified Data.HashMap.Lazy as HML
import Control.Monad (mzero)
import Data.Aeson
import Data.Text (Text)
import Data.String (IsString(..))
import Data.Scientific
import Data.Proxy
import Data.Int
import Data.Word
import GHC.Generics

newtype Major = Major Int
  deriving (Show, Eq, Generic, Num, Ord, Real, Integral, Enum)

instance FromJSON Major
instance ToJSON Major

newtype Minor = Minor Int
  deriving (Show, Eq, Generic, Num, Ord, Real, Integral, Enum)

instance FromJSON Minor
instance ToJSON Minor

data Version = Version
  { major :: Major
  , minor :: Minor
  } deriving (Show, Eq, Generic)

instance ToJSON Version
instance FromJSON Version

data Request = Request
  { meta :: Value
  , query :: Value
  } deriving (Show, Eq)

instance FromJSON Request where
  parseJSON (Object o) = Request
    <$> o .: "meta"
    <*> o .: "query"
  parseJSON _ = mzero

data RuntimeError
  = RuntimeError'UnparsableFormat
  | RuntimeError'UnrecognizedCall
  | RuntimeError'VariableLimit
  | RuntimeError'UnknownVariable Text
  | RuntimeError'IncompatibleType
  | RuntimeError'TooFewArguments
  | RuntimeError'TooManyArguments
  | RuntimeError'NoApiVersion
  | RuntimeError'NoColorlessVersion
  | RuntimeError'ApiMajorVersionTooLow
  | RuntimeError'ApiMajorVersionTooHigh
  | RuntimeError'ApiMinorVersionTooHigh
  | RuntimeError'ColorlessMajorVersionTooLow
  | RuntimeError'ColorlessMajorVersionTooHigh
  | RuntimeError'ColorlessMinorVersionTooHigh
  | RuntimeError'UnparsableMeta
  | RuntimeError'UnparsableQuery
  | RuntimeError'NoImplementation
  | RuntimeError'NotMember
  deriving (Show, Eq)

instance ToJSON RuntimeError where
  toJSON = \case
    RuntimeError'UnparsableFormat -> e "UnparsableFormat"
    RuntimeError'UnrecognizedCall -> object [ "tag" .= String "UnrecognizedCall" ]
    RuntimeError'VariableLimit -> e "VariableLimit"
    RuntimeError'UnknownVariable m -> object [ "tag" .= String "UnknownVariable", "name" .= m ]
    RuntimeError'IncompatibleType -> e "IncompatibleType"
    RuntimeError'TooFewArguments -> e "TooFewArguments"
    RuntimeError'TooManyArguments -> e "TooManyArguments"
    RuntimeError'NoApiVersion -> e "NoApiVersion"
    RuntimeError'NoColorlessVersion -> e "NoColorlessVersion"
    RuntimeError'ApiMajorVersionTooHigh -> e "ApiMajorVersionTooHigh"
    RuntimeError'ApiMajorVersionTooLow -> e "ApiMajorVersionTooLow"
    RuntimeError'ApiMinorVersionTooHigh -> e "ApiMinorVersionTooHigh"
    RuntimeError'ColorlessMajorVersionTooHigh -> e "ColorlessMajorVersionTooHigh"
    RuntimeError'ColorlessMajorVersionTooLow -> e "ColorlessMajorVersionTooLow"
    RuntimeError'ColorlessMinorVersionTooHigh -> e "ColorlessMinorVersionTooHigh"
    RuntimeError'UnparsableMeta -> e "UnparsableMeta"
    RuntimeError'UnparsableQuery -> e "UnparsableQuery"
    RuntimeError'NoImplementation -> e "NoImplementation"
    RuntimeError'NotMember -> e "NotMember"
    where
      e s = object [ "tag" .= String s ]

data ResponseError
  = ResponseError'Service Value
  | ResponseError'Runtime RuntimeError
  deriving (Eq, Show)

instance ToJSON ResponseError where
  toJSON = \case
    ResponseError'Service m -> object [ "tag" .= String "Service", "service" .= m ]
    ResponseError'Runtime m -> object [ "tag" .= String "Runtime", "runtime" .= m ]

data Response
  = Response'Error ResponseError
  | Response'Success Value
  deriving (Show, Eq)

instance ToJSON Response where
  toJSON (Response'Error m) = object [ "tag" .= String "Error", "error" .= m ]
  toJSON (Response'Success m) = object [ "tag" .= String "Success", "success" .= m ]

class Monad m => RuntimeThrower m where
  runtimeThrow :: RuntimeError -> m a

instance RuntimeThrower IO where
  runtimeThrow err = error $ "Runtime error - " ++ show err

data Options = Options
  { variableLimit :: Maybe Int
  } deriving (Show, Eq)

--

newtype Symbol = Symbol Text
  deriving (Show, Eq, Ord, FromJSON, ToJSON, ToJSONKey, FromJSONKey,  IsString)

data Type = Type
  { n :: TypeName
  , p :: [Type]
  } deriving (Show, Eq)

instance IsString Type where
  fromString s = Type (fromString s) []

instance FromJSON Type where
  parseJSON = \case
    String s -> pure $ Type (TypeName s) []
    Object o -> do
      n <- o .: "n"
      case HML.lookup "p" o of
        Nothing -> pure $ Type n []
        Just p -> Type n <$> (parseJSON p)
    _ -> mzero

instance ToJSON Type where
  toJSON (Type n []) = toJSON n
  toJSON (Type n [p]) = object [ "n" .= n, "p" .= toJSON p ]
  toJSON (Type n ps) = object [ "n" .= n, "p" .= map toJSON ps ]

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

class HasType a where
  getType :: Proxy a -> Type

instance HasType Bool where
  getType _ = "Bool"

instance HasType Text where
  getType _ = "String"

instance HasType Int8 where
  getType _ = "I8"

instance HasType Int16 where
  getType _ = "I16"

instance HasType Int32 where
  getType _ = "I32"

instance HasType Int64 where
  getType _ = "I64"

instance HasType Word8 where
  getType _ = "U8"

instance HasType Word16 where
  getType _ = "U16"

instance HasType Word32 where
  getType _ = "U32"

instance HasType Word64 where
  getType _ = "U64"

instance HasType Float where
  getType _ = "F32"

instance HasType Double where
  getType _ = "F64"

instance HasType a => HasType (Maybe a) where
  getType x = Type "Option" [getType (p x)]
    where
      p :: Proxy (Maybe a) -> Proxy a
      p _ = Proxy

instance HasType a => HasType [a] where
  getType x = Type "List" [getType (p x)]
    where
      p :: Proxy [a] -> Proxy a
      p _ = Proxy

instance (HasType e, HasType a) => HasType (Either e a) where
  getType x = Type "Either" [getType (p1 x), getType (p2 x)]
    where
      p1 :: Proxy (Either e a) -> Proxy e
      p1 _ = Proxy
      p2 :: Proxy (Either e a) -> Proxy a
      p2 _ = Proxy
