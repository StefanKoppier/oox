{-# OPTIONS_GHC -fno-warn-orphans #-}

module Analysis.CFA.CFG(
      ControlFlowGraph
    , CFGContext
    , CFGNodes
    , CFGNode
    , CFGNodeValue(..)
    , CFGEdge
    , CFGAdj
    , Node
    , context
) where

import           Data.Graph.Inductive.Graph
import           Data.Graph.Inductive.PatriciaTree
import qualified Data.Set                          as S
import qualified Text.Pretty                       as P
import           Language.Syntax
import           Language.Syntax.Pretty()

type ControlFlowGraph = ControlFlowGraph' CFGNodeValue ()

newtype ControlFlowGraph' a b = CFG (Gr a b)

instance Graph ControlFlowGraph' where
    empty                = CFG empty
    isEmpty (CFG cfg)    = isEmpty cfg
    match node (CFG cfg) = CFG <$> match node cfg
    mkGraph ns es        = CFG (mkGraph ns es)
    labNodes (CFG cfg)   = labNodes cfg

instance DynGraph ControlFlowGraph' where
    c & (CFG cfg) = CFG (c & cfg)

type CFGContext = (CFGAdj, Node, CFGNodeValue, CFGAdj)

instance {-# OVERLAPS #-} Eq CFGContext where
    (_, x, _, _) == (_, y, _, _) = x == y
    
instance {-# OVERLAPS #-} Ord CFGContext where
    (_, x, _, _) <= (_, y, _, _) = x <= y

--------------------------------------------------------------------------------
-- Control Flow Graph nodes
--------------------------------------------------------------------------------

instance {-# OVERLAPS #-} Eq CFGNode where
    (x, _) == (y, _) = x == y

instance {-# OVERLAPS #-} Ord CFGNode where
    (x, _) <= (y, _) = x <= y

type CFGNodes = S.Set CFGNode

type CFGNode = LNode CFGNodeValue

data CFGNodeValue
    = StatNode 
        Statement
    | MemberEntry 
        RuntimeType 
        Identifier
        Identifier 
        [RuntimeType]
    | MemberExit 
        RuntimeType 
        Identifier
        Identifier
        [RuntimeType]
    | ExceptionalNode 
    | TryEntry Node
    | TryExit
    | CatchEntry
    | CatchExit
    deriving (Show, Eq)

--------------------------------------------------------------------------------
-- Control Flow Graph edges
--------------------------------------------------------------------------------

type CFGEdge = UEdge

type CFGAdj = Adj ()

--------------------------------------------------------------------------------
-- Pretty printing
--------------------------------------------------------------------------------

instance P.Pretty ControlFlowGraph where
    pretty cfg 
        = foldr ((P.$+$) . P.pretty . context cfg) P.empty (nodes cfg)

instance P.Pretty CFGContext where
    pretty (_, node, value, neighbours) 
        = P.int node P.<> P.text "->" P.<> P.pretty neighbours P.<+> P.pretty value

instance P.Pretty CFGAdj where
    pretty = P.brackets . P.commas
    
instance P.Pretty (a, Node) where
    pretty (_, node) = P.int node

instance P.Pretty CFGNodeValue where
    pretty (StatNode stat) 
        = P.pretty stat

    pretty (MemberEntry retType className methodName params) 
        = P.text "entry of" P.<+> P.quotes pMethod
        where
            pMethod = P.pretty retType P.<+> pName P.<> pParams
            pName   = P.pretty className P.<> P.dot P.<> P.pretty methodName
            pParams = P.parens (P.commas params)

    pretty (MemberExit retType className methodName params)  
        = P.text "exit of" P.<+> P.quotes pMethod
        where
            pMethod = P.pretty retType P.<+> pName P.<> pParams
            pName   = P.pretty className P.<> P.dot P.<> P.pretty methodName 
            pParams = P.parens (P.commas params)

    pretty ExceptionalNode
        = P.text "exception"

    pretty (TryEntry _)
        = P.text "entry of try"
        
    pretty TryExit
        = P.text "exit of try"
        
    pretty CatchEntry
        = P.text "entry of catch"
    
    pretty CatchExit
        = P.text "exit of catch"