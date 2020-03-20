module Core.Messages exposing (..)

import Http
import Browser
import Url

import Core.Models exposing (ResetPasswordResponse)
import Common.Models exposing (UserInfo)
import ReaderApp
import CharacterApp
import NarratorDashboardApp
import NarrationArchiveApp
import NarrationCreationApp
import NarrationOverviewApp
import NarrationIntroApp
import ChapterEditApp
import ChapterControlApp
import CharacterCreationApp
import CharacterEditApp
import UserManagementApp
import NovelReaderApp
import ProfileApp


type Msg
    = NoOp
    | NavigateTo Browser.UrlRequest
    | UpdateLocation Url.Url
    | GoToFrontpage
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
    | NarrationIntroMsg NarrationIntroApp.Msg
    | ChapterEditMsg ChapterEditApp.Msg
    | ChapterControlMsg ChapterControlApp.Msg
    | CharacterCreationMsg CharacterCreationApp.Msg
    | CharacterEditMsg CharacterEditApp.Msg
    | UserManagementMsg UserManagementApp.Msg
    | NovelReaderMsg NovelReaderApp.Msg
    | ProfileMsg ProfileApp.Msg
