module ChapterControlApp.Api exposing (..)

import Http
import Json.Decode as Json exposing (..)
import Json.Encode
import Common.Api.Json exposing (parseChapter, parseReaction, parseMessageThread, parseNarration, parseChapterMessages)
import ChapterControlApp.Messages exposing (Msg, Msg(..))
import ChapterControlApp.Models exposing (ChapterInteractions)


parseChapterInteractions : Json.Decoder ChapterInteractions
parseChapterInteractions =
    Json.map3 ChapterInteractions
        (field "chapter" parseChapter)
        (field "reactions" <| list parseReaction)
        (field "messageThreads" <| list parseMessageThread)


fetchChapterInteractions : Int -> Cmd Msg
fetchChapterInteractions chapterId =
  let
    chapterInteractionsApiUrl =
      "/api/chapters/" ++ (toString chapterId) ++ "/interactions"
  in
    Http.send ChapterInteractionsFetchResult <|
      Http.get chapterInteractionsApiUrl parseChapterInteractions


fetchNarrationInfo : Int -> Cmd Msg
fetchNarrationInfo narrationId =
  let
    narrationApiUrl = "/api/narrations/" ++ (toString narrationId)
  in
    Http.send NarrationFetchResult <|
      Http.get narrationApiUrl parseNarration


sendMessage : Int -> String -> List Int -> Cmd Msg
sendMessage chapterId messageText messageRecipients =
  let
    sendMessageApiUrl = "/api/chapters/" ++ (toString chapterId) ++ "/messages"

    jsonEncodedBody =
      (Json.Encode.object
         [ ( "text", Json.Encode.string messageText )
         , ( "recipients", Json.Encode.list (List.map Json.Encode.int messageRecipients) )
         ])
  in
    Http.send SendMessageResult <|
      Http.post sendMessageApiUrl (Http.jsonBody jsonEncodedBody) parseChapterMessages


sendReply : Int -> String -> List Int -> Cmd Msg
sendReply chapterId messageText messageRecipients =
  let
    sendMessageApiUrl = "/api/chapters/" ++ (toString chapterId) ++ "/messages"

    jsonEncodedBody =
      (Json.Encode.object
         [ ( "text", Json.Encode.string messageText )
         , ( "recipients", Json.Encode.list (List.map Json.Encode.int messageRecipients) )
         ])
  in
    Http.send SendReplyResult <|
      Http.post
        sendMessageApiUrl
        (Http.jsonBody jsonEncodedBody)
        parseChapterMessages
