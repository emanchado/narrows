module CharacterEditApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode
import CharacterEditApp.Models exposing (CharacterInfo, ChapterSummary, NarrationSummary, CharacterTokenResponse)


parseChapterSummary : Json.Decoder ChapterSummary
parseChapterSummary =
    Json.map2 ChapterSummary
        (field "id" int)
        (field "title" string)


parseNarrationSummary : Json.Decoder NarrationSummary
parseNarrationSummary =
    Json.map3 NarrationSummary
        (field "id" int)
        (field "title" string)
        (field "chapters" <| list parseChapterSummary)


parseCharacterInfo : Json.Decoder CharacterInfo
parseCharacterInfo =
    Json.map CharacterInfo
      (field "id" int)
    |> andThen (\r ->
                  Json.map8 r
                    (field "token" string)
                    (field "email" string)
                    (field "name" string)
                    (maybe (field "avatar" string))
                    (field "novelToken" string)
                    (field "description" Json.value)
                    (field "backstory" Json.value)
                    (field "narration" parseNarrationSummary))


parseCharacterToken : Json.Decoder CharacterTokenResponse
parseCharacterToken =
  Json.map CharacterTokenResponse
    (field "token" string)


encodeCharacterUpdate : CharacterInfo -> Value
encodeCharacterUpdate characterInfo =
  Json.Encode.object
    [ ( "name", Json.Encode.string characterInfo.name )
    , ( "email", Json.Encode.string characterInfo.email )
    , ( "description", characterInfo.description )
    , ( "backstory", characterInfo.backstory )
    ]
