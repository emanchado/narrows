module ChapterEditApp.Api exposing (..)

import Task
import Http

import ChapterEditApp.Messages exposing (Msg, Msg(..))
import Common.Models exposing (Chapter)
import Common.Api.Json exposing (parseNarration)
import ChapterEditApp.Api.Json exposing (parseChapter, parseLastReactions, encodeChapter, encodeCharacter)

fetchChapterInfo : Int -> Cmd Msg
fetchChapterInfo chapterId =
  let
    chapterApiUrl = "/api/chapters/" ++ (toString chapterId)
  in
    Task.perform ChapterFetchError ChapterFetchSuccess
      (Http.get parseChapter chapterApiUrl)

fetchNarrationInfo : Int -> Cmd Msg
fetchNarrationInfo narrationId =
  let
    narrationApiUrl = "/api/narrations/" ++ (toString narrationId)
  in
    Task.perform NarrationFetchError NarrationFetchSuccess
      (Http.get parseNarration narrationApiUrl)

fetchLastReactions : Int -> Cmd Msg
fetchLastReactions chapterId =
  let
    lastReactionsApiUrl =
      "/api/chapters/" ++ (toString chapterId) ++ "/last-reactions"
  in
    Task.perform LastReactionsFetchError LastReactionsFetchSuccess
      (Http.get parseLastReactions lastReactionsApiUrl)

saveChapter : Chapter -> Cmd Msg
saveChapter chapter =
  Task.perform
    SaveChapterError
    SaveChapterSuccess
    (Http.send
       Http.defaultSettings
       { verb = "PUT"
       , url = "/api/chapters/" ++ (toString chapter.id)
       , headers = [("Content-Type", "application/json")]
       , body = Http.string <| encodeChapter chapter
       })

createChapter : Chapter -> Cmd Msg
createChapter chapter =
  Task.perform
    SaveNewChapterError
    SaveNewChapterSuccess
    (Http.send
       Http.defaultSettings
       { verb = "POST"
       , url = "/api/narrations/" ++ (toString chapter.narrationId) ++ "/chapters"
       , headers = [("Content-Type", "application/json")]
       , body = Http.string <| encodeChapter chapter
       })
