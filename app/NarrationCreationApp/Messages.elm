module NarrationCreationApp.Messages exposing (..)

import Http

import NarrationCreationApp.Models exposing (CreateNarrationResponse)


type Msg
    = NoOp
    | UpdateTitle String
    | CreateNarration
    | CreateNarrationResult (Result Http.Error CreateNarrationResponse)
    | CancelCreateNarration
