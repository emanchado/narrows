module NarrationArchiveApp.Api exposing (..)

import Http
import NarrationArchiveApp.Messages exposing (Msg, Msg(..))
import NarrationArchiveApp.Api.Json exposing (parseNarrationArchive)


fetchAllNarrations : Cmd Msg
fetchAllNarrations =
  Http.send NarrationArchiveFetchResult <|
    Http.get "/api/narrations" parseNarrationArchive
