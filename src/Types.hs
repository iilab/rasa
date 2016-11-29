{-# LANGUAGE ExistentialQuantification, GeneralizedNewtypeDeriving #-}
module Types where

import qualified Data.Text as T
import Control.Monad.Reader
import Control.Monad.Writer
import Control.Lens

type Alteration a = ReaderT (St, Event) (WriterT [Directive] IO) a

runAlteration :: Alteration a -> (St, Event) -> IO (a, [Directive])
runAlteration alt = runWriterT . runReaderT alt

data Mod =
    Ctrl
  | Alt
  | Shift
  deriving (Show)

data Event =
    Keypress Char [Mod]
  | Esc
  | BS
  | Enter
  | Unknown
  deriving (Show)

data Directive =
    OverState (St -> IO St)
  | OverBuffer (Buffer Offset -> IO (Buffer Offset))
  | OverText (T.Text -> IO T.Text)
  | Effect (IO ())
  | Append T.Text
  | DeleteChar
  | KillWord
  | SwitchBuf Int
  | MoveCursor Int
  | MoveCursorCoordBy Coord
  | StartOfLine
  | EndOfLine
  | StartOfBuffer
  | EndOfBuffer
  | FindNext T.Text
  | FindPrev T.Text
  | DeleteTillEOL
  | Noop
  | Exit

type Offset = Int
type Coord = (Int, Int)
type Size = (Int, Int)

data Buffer c = Buffer {
    _text :: T.Text
  , _cursor :: c
  , _filename :: String
} deriving (Show, Eq)

data Extension = forall extSt . Extension {
    _name :: String
  , _apply :: extSt -> Alteration Extension
  , _extState :: extSt
}

instance Show Extension where
    show = _name

data St = St {
    _buffers :: [Buffer Offset]
  , _focused :: Int
  , _extensions :: [Extension]
} deriving (Show)

makeLenses ''Buffer
makeLenses ''St
