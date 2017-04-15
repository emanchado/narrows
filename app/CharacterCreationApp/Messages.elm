module CharacterCreationApp.Messages exposing (..)

import Http

type Msg
  = NoOp
  | UpdateName String
  | UpdateEmail String
  | CreateCharacter
  | CreateCharacterError Http.RawError
  | CreateCharacterSuccess Http.Response
  | CancelCreateCharacter
