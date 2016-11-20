module ChapterControlApp.Api exposing (..)

import Task
import Http
import Json.Decode as Json exposing (..)

import Common.Models exposing (FullCharacter, Message, MessageThread, Reaction)
import Common.Api.Json exposing (parseCharacter, parseChapter)

import ChapterControlApp.Messages exposing (Msg, Msg(..))
import ChapterControlApp.Models exposing (ChapterInteractions)

parseReaction : Json.Decoder Reaction
parseReaction =
  Json.object2 Reaction
    ("character" := parseCharacter)
    (maybe ("text" := string))

parseMessage : Json.Decoder Message
parseMessage =
  Json.object5 Message
    ("id" := int)
    ("body" := string)
    ("sentAt" := string)
    (maybe ("sender" := parseCharacter))
    (maybe ("recipients" := (list parseCharacter)))

parseMessageThread : Json.Decoder MessageThread
parseMessageThread =
  Json.object2 MessageThread
    ("participants" := list parseCharacter)
    ("messages" := list parseMessage)

parseChapterInteractions : Json.Decoder ChapterInteractions
parseChapterInteractions =
  Json.object3 ChapterInteractions
    ("chapter" := parseChapter)
    ("reactions" := list parseReaction)
    ("messageThreads" := list parseMessageThread)

fetchChapterInteractions : Int -> Cmd Msg
fetchChapterInteractions chapterId =
  let
    chapterInteractionsApiUrl =
      "/api/chapters/" ++ (toString chapterId) ++ "/interactions"
  in
    Task.perform ChapterInteractionsFetchError ChapterInteractionsFetchSuccess
      (Http.get parseChapterInteractions chapterInteractionsApiUrl)
