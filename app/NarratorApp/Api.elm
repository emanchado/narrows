module NarratorApp.Api exposing (..)

import Json.Decode as Json exposing (..)
-- import Json.Encode
import Task
import Http

import NarratorApp.Messages exposing (Msg, Msg(..))
import NarratorApp.Models exposing (Chapter, Character)

parseCharacter : Json.Decoder Character
parseCharacter =
  Json.object2 Character ("id" := int) ("name" := string)

parseChapter : Json.Decoder Chapter
parseChapter =
  Json.object8 Chapter
    ("id" := int)
    ("narrationId" := int)
    ("title" := string)
    ("audio" := string)
    ("backgroundImage" := string)
    ("text" := Json.value)
    ("participants" := list parseCharacter)
    (maybe ("published" := string))

fetchChapterInfo : Int -> Cmd Msg
fetchChapterInfo chapterId =
  let
    chapterApiUrl = "/api/chapters/" ++ (toString chapterId)
  in
    Task.perform ChapterFetchError ChapterFetchSuccess
      (Http.get parseChapter chapterApiUrl)
