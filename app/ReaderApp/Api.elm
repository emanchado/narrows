module ReaderApp.Api exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode
import Http
import Common.Api.Json exposing (parseChapterMessages, parseParticipantCharacter)
import ReaderApp.Messages exposing (Msg, Msg(..))
import Common.Models exposing (ParticipantCharacter, ChapterMessages, MessageThread, Message)
import ReaderApp.Models exposing (Chapter, OwnCharacter, ApiErrorResponse)


parseOwnCharacter : Json.Decoder OwnCharacter
parseOwnCharacter =
    Json.map4 OwnCharacter
        (field "id" int)
        (field "name" string)
        (field "token" string)
        (maybe (field "notes" string))


parseChapter : Json.Decoder Chapter
parseChapter =
   (Json.map8 Chapter
      (field "id" int)
      (field "narrationId" int)
      (field "title" string)
      (maybe (field "audio" string))
      (maybe (field "backgroundImage" string))
      (field "text" Json.value)
      (field "participants" <| list parseParticipantCharacter)
      (field "character" parseOwnCharacter))

parseApiError : Json.Decoder ApiErrorResponse
parseApiError =
  Json.map ApiErrorResponse
    (field "errorMessage" string)


fetchChapterInfo : Int -> String -> Cmd Msg
fetchChapterInfo chapterId characterToken =
  let
    chapterApiUrl = "/api/chapters/" ++ (String.fromInt chapterId) ++
                    "/" ++ characterToken
  in
    Http.get { url = chapterApiUrl
             , expect = Http.expectJson ChapterFetchResult parseChapter
             }


fetchChapterMessages : Int -> String -> Cmd Msg
fetchChapterMessages chapterId characterToken =
  let
    chapterMessagesApiUrl = "/api/messages/" ++ (String.fromInt chapterId) ++
                            "/" ++ characterToken
  in
    Http.get { url = chapterMessagesApiUrl
             , expect = Http.expectJson ChapterMessagesFetchResult parseChapterMessages
             }


sendMessage : Int -> String -> String -> List Int -> Cmd Msg
sendMessage chapterId characterToken messageText messageRecipients =
  let
    sendMessageApiUrl =
      "/api/messages/" ++ (String.fromInt chapterId) ++ "/" ++ characterToken

    jsonEncodedBody =
      (Json.Encode.object
         [ ( "text", Json.Encode.string messageText )
         , ( "recipients", Json.Encode.list Json.Encode.int messageRecipients )
         ])
  in
    Http.post { url = sendMessageApiUrl
              , body = Http.jsonBody jsonEncodedBody
              , expect = Http.expectJson SendMessageResult parseChapterMessages
              }


sendReply : Int -> String -> String -> List Int -> Cmd Msg
sendReply chapterId characterToken messageText messageRecipients =
  let
    sendMessageApiUrl =
      "/api/messages/" ++ (String.fromInt chapterId) ++ "/" ++ characterToken

    jsonEncodedBody =
      (Json.Encode.object
         [ ( "text", Json.Encode.string messageText )
         , ( "recipients", Json.Encode.list Json.Encode.int messageRecipients )
         ])
  in
    Http.post { url = sendMessageApiUrl
              , body = Http.jsonBody jsonEncodedBody
              , expect = Http.expectJson SendReplyResult parseChapterMessages
              }


sendNotes : String -> String -> Cmd Msg
sendNotes characterToken updatedNotes =
  let
    sendNotesApiUrl = "/api/notes/" ++ characterToken

    jsonEncodedBody =
      (Json.Encode.object [ ( "notes", Json.Encode.string updatedNotes ) ])
  in
    Http.request
      { method = "PUT"
      , url = sendNotesApiUrl
      , headers = []
      , body = Http.jsonBody jsonEncodedBody
      , expect = Http.expectStringResponse SendNotesResult (\_ -> Ok "")
      , timeout = Nothing
      , tracker = Nothing
      }
