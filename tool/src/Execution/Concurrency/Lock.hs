module Execution.Concurrency.Lock where

import qualified Data.Map                 as M
import           Control.Lens
import           Execution.ExecutionState
import           Language.Syntax

type LockSet = M.Map Reference Int

locked :: Int -> Reference -> Engine r Bool
locked tid ref = do
    lockSet <- getLocks
    case lockSet M.!? ref of
        Nothing   -> return False
        Just lTid -> return (tid /= lTid)

lock :: Int -> Reference -> Engine r ()
lock tid ref = modifyLocal (\ state -> state & locks %~ M.insert ref tid)

unlock :: Reference -> Engine r ()
unlock ref = modifyLocal (\ state -> state & locks %~ M.delete ref)
