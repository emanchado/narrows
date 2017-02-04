module CharacterApp.Api exposing (..)

import Json.Decode as Json exposing (..)
import Task
import Http

import CharacterApp.Messages exposing (Msg, Msg(..))
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

fetchCharacterInfo : String -> Cmd Msg
fetchCharacterInfo characterToken =
  let
    characterApiUrl = "/api/characters/" ++ characterToken
  in
    Task.perform CharacterFetchError CharacterFetchSuccess
      (Http.get parseCharacterInfo characterApiUrl)
