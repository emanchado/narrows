module Api exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode
import Task
import Http

import Messages exposing (Msg, Msg(..))
import Models exposing (Chapter, Participant)

parseParticipant : Json.Decoder Participant
parseParticipant =
  Json.object2 Participant ("id" := int) ("name" := string)

parseChapter : Json.Decoder Chapter
parseChapter =
  Json.object8 Chapter
    ("id" := int)
    ("narrationId" := int)
    ("title" := string)
    ("audio" := string)
    ("backgroundImage" := string)
    ("text" := Json.value)
    ("participants" := list parseParticipant)
    (maybe ("reaction" := string))

fetchChapterInfo : Int -> String -> Cmd Msg
fetchChapterInfo chapterId characterToken =
  let
    chapterApiUrl = "/api/chapters/" ++ (toString chapterId) ++
                    "/" ++ characterToken
  in
    Task.perform ChapterFetchError ChapterFetchSuccess (Http.get parseChapter chapterApiUrl)

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
