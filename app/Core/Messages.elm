module Core.Messages exposing (..)

import Http
import Navigation

import Core.Models exposing (ResetPasswordResponse)
import Common.Models exposing (UserInfo)
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
import ProfileApp


type Msg
    = NoOp
    | NavigateTo String
    | UpdateLocation Navigation.Location
    | SessionFetchResult (Result Http.Error UserInfo)
    | UpdateEmail String
    | UpdatePassword String
    | Login
    | LoginResult (Result Http.Error UserInfo)
    | ForgotPassword
    | BackToLogin
    | ResetPassword
    | ResetPasswordResult (Result Http.Error ResetPasswordResponse)
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
    | ProfileMsg ProfileApp.Msg
