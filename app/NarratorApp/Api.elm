module NarratorApp.Api exposing (..)

import Task
import Http

import NarratorApp.Messages exposing (Msg, Msg(..))
import NarratorApp.Models exposing (Chapter, Character)
import NarratorApp.Api.Json exposing (parseChapter, parseNarration, encodeChapter, encodeCharacter)

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

saveChapter : Chapter -> Cmd Msg
saveChapter chapter =
  let
    saveChapterApiUrl = "/api/chapters/" ++ (toString chapter.id)
  in
    Task.perform
      SaveChapterError
      SaveChapterSuccess
      (Http.send
         Http.defaultSettings
         { verb = "PUT"
         , url = saveChapterApiUrl
         , headers = [("Content-Type", "application/json")]
         , body = Http.string <| encodeChapter chapter
         })

addParticipant : Chapter -> Character -> Cmd Msg
addParticipant chapter character =
  let
    addParticipantApiUrl = "/api/chapters/" ++ (toString chapter.id) ++ "/participants"
  in
    Task.perform
      AddParticipantError
      AddParticipantSuccess
      (Http.send
         Http.defaultSettings
         { verb = "POST"
         , url = addParticipantApiUrl
         , headers = [("Content-Type", "application/json")]
         , body = Http.string <| encodeCharacter character
         })

removeParticipant : Chapter -> Character -> Cmd Msg
removeParticipant chapter character =
  let
    removeParticipantApiUrl =
      "/api/chapters/" ++ (toString chapter.id) ++
        "/participants/" ++ (toString character.id)
  in
    Task.perform
      AddParticipantError
      AddParticipantSuccess
      (Http.send
         Http.defaultSettings
         { verb = "DELETE"
         , url = removeParticipantApiUrl
         , headers = [("Content-Type", "application/json")]
         , body = Http.string <| encodeCharacter character
         })
