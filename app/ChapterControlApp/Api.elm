module ChapterControlApp.Api exposing (..)

import Task
import Http
import Json.Decode as Json exposing (..)
import Json.Encode

import Common.Api.Json exposing (parseChapter, parseReaction, parseMessageThread, parseNarration)

import ChapterControlApp.Messages exposing (Msg, Msg(..))
import ChapterControlApp.Models exposing (ChapterInteractions)

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

fetchNarrationInfo : Int -> Cmd Msg
fetchNarrationInfo narrationId =
  let
    narrationApiUrl = "/api/narrations/" ++ (toString narrationId)
  in
    Task.perform NarrationFetchError NarrationFetchSuccess
      (Http.get parseNarration narrationApiUrl)


sendMessage : Int -> String -> List Int -> Cmd Msg
sendMessage chapterId messageText messageRecipients =
  let
    sendMessageApiUrl = "/api/chapters/" ++ (toString chapterId) ++ "/messages"
    jsonEncodedBody =
      (Json.Encode.encode
         0
         (Json.Encode.object [ ("text", Json.Encode.string messageText)
                             , ("recipients", Json.Encode.list (List.map Json.Encode.int messageRecipients))]))
  in
    Task.perform
      SendMessageError
      SendMessageSuccess
      (Http.send
         Http.defaultSettings
         { verb = "POST"
         , url = sendMessageApiUrl
         , headers = [("Content-Type", "application/json")]
         , body = Http.string jsonEncodedBody
         })


sendReply : Int -> String -> List Int -> Cmd Msg
sendReply chapterId messageText messageRecipients =
  let
    sendMessageApiUrl = "/api/chapters/" ++ (toString chapterId) ++ "/messages"
    jsonEncodedBody =
      (Json.Encode.encode
         0
         (Json.Encode.object [ ("text", Json.Encode.string messageText)
                             , ("recipients", Json.Encode.list (List.map Json.Encode.int messageRecipients))]))
  in
    Task.perform
      SendReplyError
      SendReplySuccess
      (Http.send
         Http.defaultSettings
         { verb = "POST"
         , url = sendMessageApiUrl
         , headers = [("Content-Type", "application/json")]
         , body = Http.string jsonEncodedBody
         })
