module CharacterCreationApp.Messages exposing (..)

import Http

import Common.Models exposing (Narration, Character)


type Msg
    = NoOp
    | NavigateTo String
    | FetchNarrationResult (Result Http.Error Narration)
    | UpdateName String
    | CreateCharacter
    | CreateCharacterResult (Result Http.Error Character)
    | CancelCreateCharacter
