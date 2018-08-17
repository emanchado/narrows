module CharacterApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode
import Common.Api.Json exposing (parseParticipantCharacter)
import CharacterApp.Models exposing (CharacterInfo, ChapterSummary, NarrationSummary)


parseChapterSummary : Json.Decoder ChapterSummary
parseChapterSummary =
    Json.map2 ChapterSummary
        (field "id" int)
        (field "title" string)


parseNarrationSummary : Json.Decoder NarrationSummary
parseNarrationSummary =
    Json.map4 NarrationSummary
        (field "id" int)
        (field "title" string)
        (field "chapters" <| list parseChapterSummary)
        (field "characters" <| list parseParticipantCharacter)


parseCharacterInfo : Json.Decoder CharacterInfo
parseCharacterInfo =
    Json.map7 CharacterInfo
        (field "id" int)
        (field "name" string)
        (maybe (field "avatar" string))
        (field "novelToken" string)
        (field "description" Json.value)
        (field "backstory" Json.value)
        (field "narration" parseNarrationSummary)


encodeCharacterUpdate : CharacterInfo -> Value
encodeCharacterUpdate characterInfo =
  Json.Encode.object
    [ ( "name", Json.Encode.string characterInfo.name )
    , ( "description", characterInfo.description )
    , ( "backstory", characterInfo.backstory )
    ]
