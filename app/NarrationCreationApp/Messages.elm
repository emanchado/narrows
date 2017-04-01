module NarrationCreationApp.Messages exposing (..)

import Http

type Msg
  = NoOp
  | UpdateTitle String
  | CreateNarration
  | CreateNarrationError Http.RawError
  | CreateNarrationSuccess Http.Response
  | CancelCreateNarration
