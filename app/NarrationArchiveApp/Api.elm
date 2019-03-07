module NarrationArchiveApp.Api exposing (..)

import Http
import NarrationArchiveApp.Messages exposing (Msg, Msg(..))
import NarrationArchiveApp.Api.Json exposing (parseNarrationArchive)


fetchAllNarrations : Cmd Msg
fetchAllNarrations =
  Http.get { url = "/api/narrations"
           , expect = Http.expectJson NarrationArchiveFetchResult parseNarrationArchive
           }
