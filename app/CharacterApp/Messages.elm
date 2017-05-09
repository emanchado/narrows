module CharacterApp.Messages exposing (..)

import Http
import Json.Encode
import CharacterApp.Models exposing (..)


type Msg
    = NoOp
    | NavigateTo String
    | CharacterFetchResult (Result Http.Error CharacterInfo)
    | UpdateCharacterName String
    | UpdateDescriptionText Json.Encode.Value
    | UpdateBackstoryText Json.Encode.Value
    | SaveCharacter
    | SaveCharacterResult (Result Http.Error (Http.Response String))
