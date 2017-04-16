module CharacterApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode

import CharacterApp.Models exposing (CharacterInfo, ChapterSummary, NarrationSummary)

parseChapterSummary : Json.Decoder ChapterSummary
parseChapterSummary =
  Json.object2 ChapterSummary
    ("id" := int)
    ("title" := string)

parseNarrationSummary : Json.Decoder NarrationSummary
parseNarrationSummary =
  Json.object3 NarrationSummary
    ("id" := int)
    ("title" := string)
    ("chapters" := list parseChapterSummary)

parseCharacterInfo : Json.Decoder CharacterInfo
parseCharacterInfo =
  Json.object6 CharacterInfo
    ("id" := int)
    ("name" := string)
    (maybe ("avatar" := string))
    ("description" := Json.value)
    ("backstory" := Json.value)
    ("narration" := parseNarrationSummary)

encodeCharacterUpdate : CharacterInfo -> String
encodeCharacterUpdate characterInfo =
  (Json.Encode.encode
     0
     (Json.Encode.object [ ("name", Json.Encode.string characterInfo.name)
                         , ("description", characterInfo.description)
                         , ("backstory", characterInfo.backstory)
                         ]))
