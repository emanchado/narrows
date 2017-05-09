module ChapterEditApp.Api exposing (..)

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
    Http.send ChapterFetchResult <|
      Http.get chapterApiUrl parseChapter


fetchNarrationInfo : Int -> Cmd Msg
fetchNarrationInfo narrationId =
  let
    narrationApiUrl = "/api/narrations/" ++ (toString narrationId)
  in
    Http.send NarrationFetchResult <|
      Http.get narrationApiUrl parseNarration


fetchLastReactions : Int -> Cmd Msg
fetchLastReactions chapterId =
  let
    lastReactionsApiUrl =
      "/api/chapters/" ++ (toString chapterId) ++ "/last-reactions"
  in
    Http.send LastReactionsFetchResult <|
      Http.get lastReactionsApiUrl parseLastReactions


fetchNarrationLastReactions : Int -> Cmd Msg
fetchNarrationLastReactions narrationId =
  let
    lastReactionsApiUrl =
      "/api/narrations/" ++ (toString narrationId) ++ "/last-reactions"
  in
    Http.send NarrationLastReactionsFetchResult <|
      Http.get lastReactionsApiUrl parseLastReactions


saveChapter : Chapter -> Cmd Msg
saveChapter chapter =
  Http.send SaveChapterResult <|
    Http.request { method = "PUT"
                 , url = "/api/chapters/" ++ (toString chapter.id)
                 , headers = []
                 , body = Http.jsonBody <| encodeChapter chapter
                 , expect = Http.expectStringResponse Ok
                 , timeout = Nothing
                 , withCredentials = False
                 }


createChapter : Chapter -> Cmd Msg
createChapter chapter =
  let
    createChapterUrl = "/api/narrations/" ++ (toString chapter.narrationId) ++ "/chapters"
  in
    Http.send SaveNewChapterResult <|
      Http.post
        createChapterUrl
        (Http.jsonBody <| encodeChapter chapter)
        parseChapter
