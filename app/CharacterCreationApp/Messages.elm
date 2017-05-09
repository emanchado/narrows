module CharacterCreationApp.Messages exposing (..)

import Http


type Msg
    = NoOp
    | UpdateName String
    | UpdateEmail String
    | CreateCharacter
    | CreateCharacterResult (Result Http.Error (Http.Response String))
    | CancelCreateCharacter
