module NarrationArchiveApp.Messages exposing (..)

import Http
import NarrationArchiveApp.Models exposing (NarrationArchive)


type Msg
    = NoOp
    | NavigateTo String
    | NarrationArchiveFetchResult (Result Http.Error NarrationArchive)
