module CharacterApp.Messages exposing (..)

import Http
import Json.Encode

import CharacterApp.Models exposing (..)

type Msg
  = NoOp
  | CharacterFetchError Http.Error
  | CharacterFetchSuccess CharacterInfo
  | UpdateDescriptionText Json.Encode.Value
  | UpdateBackstoryText Json.Encode.Value
  | SaveCharacter
  | SaveCharacterError Http.RawError
  | SaveCharacterSuccess Http.Response
