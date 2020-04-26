module CharacterApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode
import Common.Api.Json exposing (parseParticipantCharacter, parseNarrationStatus)
import Common.Models exposing (CharacterInfo)


encodeCharacterUpdate : CharacterInfo -> Value
encodeCharacterUpdate characterInfo =
  Json.Encode.object
    [ ( "name", Json.Encode.string characterInfo.name )
    , ( "description", characterInfo.description )
    , ( "backstory", characterInfo.backstory )
    ]
