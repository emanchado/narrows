module ChapterControlApp.Api exposing (..)

import Task
import Http

import ChapterControlApp.Messages exposing (Msg, Msg(..))

fetchChapterInfo : Int -> Cmd Msg
fetchChapterInfo narrationId =
  let
    narrationApiUrl = "/api/narrations/" ++ (toString narrationId) ++ "/chapters"
  in
    Task.perform ChapterControlFetchError ChapterControlFetchSuccess
      (Http.get parseChapterControl narrationApiUrl)
