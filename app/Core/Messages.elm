module Core.Messages exposing (..)

import Http
import Navigation

import Core.Models
import ReaderApp
import CharacterApp
import NarratorDashboardApp
import NarrationArchiveApp
import NarrationCreationApp
import NarrationOverviewApp
import ChapterEditApp
import ChapterControlApp
import CharacterCreationApp
import UserManagementApp
import NovelReaderApp


type Msg
    = NoOp
    | NavigateTo String
    | UpdateLocation Navigation.Location
    | SessionFetchResult (Result Http.Error Core.Models.UserInfo)
    | UpdateEmail String
    | UpdatePassword String
    | Login
    | LoginResult (Result Http.Error Core.Models.UserInfo)
    | Logout
    | LogoutResult (Result Http.Error String)
    | ReaderMsg ReaderApp.Msg
    | CharacterMsg CharacterApp.Msg
    | NarratorDashboardMsg NarratorDashboardApp.Msg
    | NarrationArchiveMsg NarrationArchiveApp.Msg
    | NarrationCreationMsg NarrationCreationApp.Msg
    | NarrationOverviewMsg NarrationOverviewApp.Msg
    | ChapterEditMsg ChapterEditApp.Msg
    | ChapterControlMsg ChapterControlApp.Msg
    | CharacterCreationMsg CharacterCreationApp.Msg
    | UserManagementMsg UserManagementApp.Msg
    | NovelReaderMsg NovelReaderApp.Msg
