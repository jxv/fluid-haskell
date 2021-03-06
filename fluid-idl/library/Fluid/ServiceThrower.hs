{-# OPTIONS_GHC -fno-warn-orphans #-}
module Fluid.ServiceThrower
  ( ServiceThrower(..)
  , ThrownValue(..)
  , mayServiceThrow
  ) where

import Control.Exception.Safe
import Control.Monad.Except
import Data.Aeson

import qualified Fluid.Server.Exchange as Server

newtype ThrownValue = ThrownValue { unThrownValue :: Value }
  deriving (Show, Eq, Typeable)

class MonadThrow m => ServiceThrower m where
  serviceThrow :: Value -> m a
  serviceThrow err = throw (ThrownValue err)

instance Exception ThrownValue

instance MonadThrow m => ServiceThrower (ExceptT Server.Response m) where
  serviceThrow = throwError . Server.Response'Error . Server.ResponseError'Service

mayServiceThrow :: (ServiceThrower m, MonadCatch m) => m a -> m (Maybe a)
mayServiceThrow m = catch (Just <$> m) (\(_ :: ThrownValue) -> return Nothing)
