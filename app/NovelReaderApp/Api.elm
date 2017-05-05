module NovelReaderApp.Api exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode
import Task
import Http

import Common.Api.Json exposing (parseChapterMessages)

import NovelReaderApp.Messages exposing (Msg, Msg(..))
import NovelReaderApp.Models exposing (Chapter, ParticipantCharacter, Novel, Narration)

parseParticipantCharacter : Json.Decoder ParticipantCharacter
parseParticipantCharacter =
  Json.object4 ParticipantCharacter
    ("id" := int)
    ("name" := string)
    (maybe ("avatar" := string))
    ("description" := Json.value)

parseChapter : Json.Decoder Chapter
parseChapter =
  Json.object5 Chapter
    ("id" := int)
    ("title" := string)
    ("audio" := string)
    ("backgroundImage" := string)
    ("text" := Json.value)

parseNarration : Json.Decoder Narration
parseNarration =
  Json.object5 Narration
    ("id" := int)
    ("title" := string)
    ("characters" := list parseParticipantCharacter)
    (maybe ("defaultAudio" := string))
    (maybe ("defaultBackgroundImage" := string))

parseNovel : Json.Decoder Novel
parseNovel =
  Json.object4 Novel
    ("token" := string)
    ("characterId" := int)
    ("narration" := parseNarration)
    ("chapters" := list parseChapter)

fetchNovelInfo : String -> Cmd Msg
fetchNovelInfo novelToken =
  let
    novelApiUrl = "/api/novels/" ++ novelToken
  in
    Task.perform NovelFetchError NovelFetchSuccess
      (Http.get parseNovel novelApiUrl)
