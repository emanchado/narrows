module ChapterControlApp.Api exposing (..)

import Task
import Http
import Json.Decode as Json exposing (..)
import Json.Encode

import Common.Models exposing (FullCharacter, Message, MessageThread, ChapterMessages, Reaction)
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

parseChapterMessages : Json.Decoder ChapterMessages
parseChapterMessages =
  Json.object2 ChapterMessages
    ("messageThreads" := list parseMessageThread)
    (maybe ("characterId" := int))


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
