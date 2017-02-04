module CharacterApp.Messages exposing (..)

import Http

import CharacterApp.Models exposing (..)

type Msg
  = NoOp
  | CharacterFetchError Http.Error
  | CharacterFetchSuccess CharacterInfo
