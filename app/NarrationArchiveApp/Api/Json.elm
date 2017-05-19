module NarrationArchiveApp.Api.Json exposing (..)

import Json.Decode as Json exposing (..)
import Common.Api.Json exposing (parseReaction, parseNarrationOverview)
import NarrationArchiveApp.Models exposing (NarrationArchive)


parseNarrationArchive : Json.Decoder NarrationArchive
parseNarrationArchive =
    Json.map NarrationArchive
        (field "narrations" <| list parseNarrationOverview)
