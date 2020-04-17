module ChapterEditApp.Api exposing (..)

import Http
import Url.Builder as UB
import Json.Encode

import ChapterEditApp.Messages exposing (Msg, Msg(..))
import Common.Models exposing (Chapter)
import Common.Api.Json exposing (parseChapter, parseNarration)
import ChapterEditApp.Api.Json exposing (parseLastReactionResponse, parseNarrationChapterSearchResponse, encodeChapter, encodeCharacter)


fetchChapterInfo : Int -> Cmd Msg
fetchChapterInfo chapterId =
  let
    chapterApiUrl = "/api/chapters/" ++ (String.fromInt chapterId)
  in
    Http.get { url = chapterApiUrl
             , expect = Http.expectJson ChapterFetchResult parseChapter
             }


fetchNarrationInfo : Int -> Cmd Msg
fetchNarrationInfo narrationId =
  let
    narrationApiUrl = "/api/narrations/" ++ (String.fromInt narrationId)
  in
    Http.get { url = narrationApiUrl
             , expect = Http.expectJson NarrationFetchResult parseNarration
             }


fetchLastReactions : Int -> Cmd Msg
fetchLastReactions chapterId =
  let
    lastReactionsApiUrl =
      "/api/chapters/" ++ (String.fromInt chapterId) ++ "/last-reactions"
  in
    Http.get { url = lastReactionsApiUrl
             , expect = Http.expectJson LastReactionsFetchResult parseLastReactionResponse
             }


fetchNarrationLastReactions : Int -> Cmd Msg
fetchNarrationLastReactions narrationId =
  let
    lastReactionsApiUrl =
      "/api/narrations/" ++ (String.fromInt narrationId) ++ "/last-reactions"
  in
    Http.get { url = lastReactionsApiUrl
             , expect = Http.expectJson NarrationLastReactionsFetchResult parseLastReactionResponse
             }


saveChapter : Chapter -> Cmd Msg
saveChapter chapter =
  Http.request { method = "PUT"
               , url = "/api/chapters/" ++ (String.fromInt chapter.id)
               , headers = []
               , body = Http.jsonBody <| encodeChapter chapter
               , expect = Http.expectStringResponse SaveChapterResult Ok
               , timeout = Nothing
               , tracker = Nothing
               }


createChapter : Chapter -> Cmd Msg
createChapter chapter =
  let
    createChapterUrl = "/api/narrations/" ++ (String.fromInt chapter.narrationId) ++ "/chapters"
  in
    Http.post { url = createChapterUrl
              , body = Http.jsonBody <| encodeChapter chapter
              , expect = Http.expectJson SaveNewChapterResult parseChapter
              }

searchNarrationChapters : Int -> String -> Cmd Msg
searchNarrationChapters narrationId searchTerm =
  let
    searchApiBaseUrl =
      "/api/narrations/" ++ (String.fromInt narrationId) ++ "/search"
    queryString =
      UB.toQuery [ UB.string "terms" searchTerm ]
  in
    Http.get { url = searchApiBaseUrl ++ queryString
             , expect = Http.expectJson NarrationChapterSearchFetchResult parseNarrationChapterSearchResponse
             }


encodeNarrationNotes : String -> Json.Encode.Value
encodeNarrationNotes notes =
    (Json.Encode.object
        [ ( "notes", Json.Encode.string notes )
        ]
    )

saveNarrationNotes : Int -> String -> Cmd Msg
saveNarrationNotes narrationId notes =
  Http.request { method = "PUT"
               , headers = []
               , url = "/api/narrations/" ++ (String.fromInt narrationId)
               , body = Http.jsonBody <| encodeNarrationNotes notes
               , expect = Http.expectJson SaveNarrationNotesResult parseNarration
               , timeout = Nothing
               , tracker = Nothing
               }
