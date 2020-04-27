module DashboardApp.Api exposing (..)

import Http
import DashboardApp.Messages exposing (Msg, Msg(..))
import DashboardApp.Api.Json exposing (parseNarratorOverview, parseNarrationArchive, parseCharacterArchive)


fetchNarratorOverview : Cmd Msg
fetchNarratorOverview =
  Http.get { url = "/api/narrations/overview"
           , expect = Http.expectJson NarratorOverviewFetchResult parseNarratorOverview
           }


fetchAllNarrations : Cmd Msg
fetchAllNarrations =
  Http.get { url = "/api/narrations"
           , expect = Http.expectJson NarrationArchiveFetchResult parseNarrationArchive
           }


fetchAllCharacters : Cmd Msg
fetchAllCharacters =
  Http.get { url = "/api/characters"
           , expect = Http.expectJson CharacterArchiveFetchResult parseCharacterArchive
           }
