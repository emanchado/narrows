module ReaderApp.Api exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode
import Task
import Http

import Common.Api.Json exposing (parseChapterMessages)

import ReaderApp.Messages exposing (Msg, Msg(..))
import ReaderApp.Models exposing (Chapter, ParticipantCharacter, OwnCharacter, ChapterMessages, MessageThread, Message)

parseParticipantCharacter : Json.Decoder ParticipantCharacter
parseParticipantCharacter =
  Json.object4 ParticipantCharacter
    ("id" := int)
    ("name" := string)
    (maybe ("avatar" := string))
    (maybe ("description" := string))

parseOwnCharacter : Json.Decoder OwnCharacter
parseOwnCharacter =
  Json.object4 OwnCharacter
    ("id" := int)
    ("name" := string)
    ("token" := string)
    (maybe ("notes" := string))

parseChapter : Json.Decoder Chapter
parseChapter =
  Json.object8 Chapter
    ("id" := int)
    ("narrationId" := int)
    ("title" := string)
    ("audio" := string)
    ("backgroundImage" := string)
    ("text" := Json.value)
    ("participants" := list parseParticipantCharacter)
    (maybe ("reaction" := string))
    `andThen`
      (\f ->
         Json.object1 f
           ("character" := parseOwnCharacter))

fetchChapterInfo : Int -> String -> Cmd Msg
fetchChapterInfo chapterId characterToken =
  let
    chapterApiUrl = "/api/chapters/" ++ (toString chapterId) ++
                    "/" ++ characterToken
  in
    Task.perform ChapterFetchError ChapterFetchSuccess
      (Http.get parseChapter chapterApiUrl)

fetchChapterMessages : Int -> String -> Cmd Msg
fetchChapterMessages chapterId characterToken =
  let
    chapterMessagesApiUrl = "/api/messages/" ++ (toString chapterId) ++
                         "/" ++ characterToken
  in
    Task.perform ChapterMessagesFetchError ChapterMessagesFetchSuccess
      (Http.get parseChapterMessages chapterMessagesApiUrl)

sendMessage : Int -> String -> String -> List Int -> Cmd Msg
sendMessage chapterId characterToken messageText messageRecipients =
  let
    sendMessageApiUrl =
      "/api/messages/" ++ (toString chapterId) ++ "/" ++ characterToken
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

sendReaction : Int -> String -> String -> Cmd Msg
sendReaction chapterId characterToken reactionText =
  let
    sendReactionApiUrl =
      "/api/reactions/" ++ (toString chapterId) ++ "/" ++ characterToken
    jsonEncodedBody =
      (Json.Encode.encode
         0
         (Json.Encode.object [ ("text", Json.Encode.string reactionText) ]))
  in
    Task.perform
      SendReactionError
        SendReactionSuccess
      (Http.send
         Http.defaultSettings
         { verb = "PUT"
         , url = sendReactionApiUrl
         , headers = [("Content-Type", "application/json")]
         , body = Http.string jsonEncodedBody
         })

sendNotes : String -> String -> Cmd Msg
sendNotes characterToken updatedNotes =
  let
    sendNotesApiUrl = "/api/notes/" ++ characterToken
    jsonEncodedBody =
      (Json.Encode.encode
         0
         (Json.Encode.object [ ("notes", Json.Encode.string updatedNotes) ]))
  in
    Task.perform
      SendNotesError
      SendNotesSuccess
      (Http.send
         Http.defaultSettings
         { verb = "PUT"
         , url = sendNotesApiUrl
         , headers = [("Content-Type", "application/json")]
         , body = Http.string jsonEncodedBody
         })
