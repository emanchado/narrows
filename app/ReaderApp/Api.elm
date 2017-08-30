module ReaderApp.Api exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode
import Http
import Common.Api.Json exposing (parseChapterMessages)
import ReaderApp.Messages exposing (Msg, Msg(..))
import Common.Models exposing (ParticipantCharacter)
import ReaderApp.Models exposing (Chapter, OwnCharacter, ChapterMessages, MessageThread, Message, ApiErrorResponse)


parseParticipantCharacter : Json.Decoder ParticipantCharacter
parseParticipantCharacter =
    Json.map4 ParticipantCharacter
        (field "id" int)
        (field "name" string)
        (maybe (field "avatar" string))
        (field "description" Json.value)


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
    chapterApiUrl = "/api/chapters/" ++ (toString chapterId) ++
                    "/" ++ characterToken
  in
    Http.send ChapterFetchResult <|
      Http.get chapterApiUrl parseChapter


fetchChapterMessages : Int -> String -> Cmd Msg
fetchChapterMessages chapterId characterToken =
  let
    chapterMessagesApiUrl = "/api/messages/" ++ (toString chapterId) ++
                            "/" ++ characterToken
  in
    Http.send ChapterMessagesFetchResult <|
      Http.get chapterMessagesApiUrl parseChapterMessages


sendMessage : Int -> String -> String -> List Int -> Cmd Msg
sendMessage chapterId characterToken messageText messageRecipients =
  let
    sendMessageApiUrl =
      "/api/messages/" ++ (toString chapterId) ++ "/" ++ characterToken

    jsonEncodedBody =
      (Json.Encode.object
         [ ( "text", Json.Encode.string messageText )
         , ( "recipients", Json.Encode.list (List.map Json.Encode.int messageRecipients) )
         ])
  in
    Http.send SendMessageResult <|
      Http.post
        sendMessageApiUrl
        (Http.jsonBody jsonEncodedBody)
        parseChapterMessages


sendReply : Int -> String -> String -> List Int -> Cmd Msg
sendReply chapterId characterToken messageText messageRecipients =
  let
    sendMessageApiUrl =
      "/api/messages/" ++ (toString chapterId) ++ "/" ++ characterToken

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


sendNotes : String -> String -> Cmd Msg
sendNotes characterToken updatedNotes =
  let
    sendNotesApiUrl = "/api/notes/" ++ characterToken

    jsonEncodedBody =
      (Json.Encode.object [ ( "notes", Json.Encode.string updatedNotes ) ])
  in
    Http.send
      SendNotesResult
      (Http.request
         { method = "PUT"
         , url = sendNotesApiUrl
         , headers = []
         , body = Http.jsonBody jsonEncodedBody
         , expect = Http.expectStringResponse (\_ -> Ok "")
         , timeout = Nothing
         , withCredentials = False
         })
