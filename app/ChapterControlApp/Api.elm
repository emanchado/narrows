module ChapterControlApp.Api exposing (..)

import Http
import Json.Decode as Json exposing (..)
import Json.Encode
import Common.Api.Json exposing (parseChapter, parseMessageThread, parseNarration, parseChapterMessages)
import ChapterControlApp.Messages exposing (Msg, Msg(..))
import ChapterControlApp.Models exposing (ChapterInteractions)


parseChapterInteractions : Json.Decoder ChapterInteractions
parseChapterInteractions =
    Json.map2 ChapterInteractions
        (field "chapter" parseChapter)
        (field "messageThreads" <| list parseMessageThread)


fetchChapterInteractions : Int -> Cmd Msg
fetchChapterInteractions chapterId =
  let
    chapterInteractionsApiUrl =
      "/api/chapters/" ++ (String.fromInt chapterId) ++ "/interactions"
  in
    Http.get { url = chapterInteractionsApiUrl
             , expect = Http.expectJson ChapterInteractionsFetchResult parseChapterInteractions
             }


fetchNarrationInfo : Int -> Cmd Msg
fetchNarrationInfo narrationId =
  let
    narrationApiUrl = "/api/narrations/" ++ (String.fromInt narrationId)
  in
    Http.get { url = narrationApiUrl
             , expect = Http.expectJson NarrationFetchResult parseNarration
             }


sendMessage : Int -> String -> List Int -> Cmd Msg
sendMessage chapterId messageText messageRecipients =
  let
    sendMessageApiUrl = "/api/chapters/" ++ (String.fromInt chapterId) ++ "/messages"

    jsonEncodedBody =
      (Json.Encode.object
         [ ( "text", Json.Encode.string messageText )
         , ( "recipients", Json.Encode.list Json.Encode.int messageRecipients )
         ])
  in
    Http.post { url = sendMessageApiUrl
              , body = (Http.jsonBody jsonEncodedBody)
              , expect = Http.expectJson SendMessageResult parseChapterMessages
              }


sendReply : Int -> String -> List Int -> Cmd Msg
sendReply chapterId messageText messageRecipients =
  let
    sendMessageApiUrl = "/api/chapters/" ++ (String.fromInt chapterId) ++ "/messages"

    jsonEncodedBody =
      (Json.Encode.object
         [ ( "text", Json.Encode.string messageText )
         , ( "recipients", Json.Encode.list Json.Encode.int messageRecipients )
         ])
  in
    Http.post { url = sendMessageApiUrl
              , body = (Http.jsonBody jsonEncodedBody)
              , expect = Http.expectJson SendReplyResult parseChapterMessages
              }
