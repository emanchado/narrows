module Api exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode
import Task
import Http

import Messages exposing (Msg, Msg(..))
import Models exposing (Chapter, Character, ChapterMessages, MessageThread, Message)

parseCharacter : Json.Decoder Character
parseCharacter =
  Json.object2 Character ("id" := int) ("name" := string)

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
    (maybe ("reaction" := string))

parseChapterMessages : Json.Decoder ChapterMessages
parseChapterMessages =
  Json.object1 ChapterMessages
    ("messageThreads" := list parseMessageThread)

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

sendReaction : Int -> String -> String -> Cmd Msg
sendReaction chapterId characterToken reactionText =
  let
    sendReactionApiUrl =
      "/api/reactions/" ++ (toString chapterId) ++ "/" ++ characterToken
  in
    Task.perform
      SendReactionError
      SendReactionSuccess
      (Http.send
         Http.defaultSettings
         { verb = "PUT"
         , url = sendReactionApiUrl
         , headers = [("Content-Type", "application/json")]
         , body = Http.string (Json.Encode.encode 0 (Json.Encode.object [ ("text", Json.Encode.string reactionText) ]))
         })
