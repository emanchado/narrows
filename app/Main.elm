module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Tuple exposing (first, second)
import Url
import Http

import Routing
import Common.Models exposing (errorBanner, successBanner, UserSession(..))
import Core.Api
import Core.Views
import Core.Models exposing (Model)
import Core.Messages exposing (Msg(..))

import ReaderApp
import CharacterApp
import CharacterEditApp
import DashboardApp
import NarrationArchiveApp
import NarrationCreationApp
import NarrationOverviewApp
import NarrationIntroApp
import ChapterEditApp
import ChapterControlApp
import CharacterCreationApp
import UserManagementApp
import NovelReaderApp
import ProfileApp


initialState : () -> Url.Url -> Nav.Key -> (Model, Cmd Msg)
initialState flags url key =
  ( { route = Routing.fromUrl url
    , key = key
    , session = Nothing
    , banner = Nothing
    , email = ""
    , password = ""
    , forgotPasswordUi = False
    , readerApp = ReaderApp.initialState key
    , characterApp = CharacterApp.initialState key
    , dashboardApp = DashboardApp.initialState key
    , narrationArchiveApp = NarrationArchiveApp.initialState key
    , narrationCreationApp = NarrationCreationApp.initialState key
    , narrationOverviewApp = NarrationOverviewApp.initialState key
    , narrationIntroApp = NarrationIntroApp.initialState key
    , chapterEditApp = ChapterEditApp.initialState key
    , chapterControlApp = ChapterControlApp.initialState key
    , characterEditApp = CharacterEditApp.initialState key
    , characterCreationApp = CharacterCreationApp.initialState key
    , userManagementApp = UserManagementApp.initialState key
    , novelReaderApp = NovelReaderApp.initialState key
    , profileApp = ProfileApp.initialState key
    }
  , Core.Api.refreshSession
  )


protectedCmd : Maybe UserSession -> Cmd Msg -> Cmd Msg
protectedCmd maybeSession cmd =
    case maybeSession of
        Just session ->
            case session of
                AnonymousSession ->
                    Cmd.none

                LoggedInSession _ ->
                    cmd

        Nothing ->
            Cmd.none


protectedCmds : Maybe UserSession -> List (Cmd Msg) -> List (Cmd Msg)
protectedCmds maybeSession cmds =
    case maybeSession of
        Just session ->
            case session of
                AnonymousSession ->
                    []

                LoggedInSession _ ->
                    cmds

        Nothing ->
            []


dispatchEnterLocation : Model -> (Model, Cmd Msg)
dispatchEnterLocation model =
  let
    currentRoute = model.route

    readerApp = ReaderApp.urlUpdate currentRoute model.readerApp
    characterApp = CharacterApp.urlUpdate currentRoute model.characterApp
    novelReaderApp = NovelReaderApp.urlUpdate currentRoute model.novelReaderApp
    narrationIntroApp = NarrationIntroApp.urlUpdate currentRoute model.narrationIntroApp

    chapterEditApp = ChapterEditApp.urlUpdate currentRoute model.chapterEditApp
    dashboardApp = DashboardApp.urlUpdate currentRoute model.dashboardApp
    narrationArchiveApp = NarrationArchiveApp.urlUpdate currentRoute model.narrationArchiveApp
    narrationCreationApp = NarrationCreationApp.urlUpdate currentRoute model.narrationCreationApp
    narrationOverviewApp = NarrationOverviewApp.urlUpdate currentRoute model.narrationOverviewApp
    chapterControlApp = ChapterControlApp.urlUpdate currentRoute model.chapterControlApp
    characterCreationApp = CharacterCreationApp.urlUpdate currentRoute model.characterCreationApp
    characterEditApp = CharacterEditApp.urlUpdate currentRoute model.characterEditApp
    userManagementApp = UserManagementApp.urlUpdate currentRoute model.userManagementApp
    profileApp = ProfileApp.urlUpdate currentRoute model.profileApp
  in
    ( { model | route = currentRoute
              , readerApp = first readerApp
              , characterApp = first characterApp
              , dashboardApp = first dashboardApp
              , narrationArchiveApp = first narrationArchiveApp
              , narrationCreationApp = first narrationCreationApp
              , narrationOverviewApp = first narrationOverviewApp
              , narrationIntroApp = first narrationIntroApp
              , chapterEditApp = first chapterEditApp
              , chapterControlApp = first chapterControlApp
              , characterCreationApp = first characterCreationApp
              , characterEditApp = first characterEditApp
              , userManagementApp = first userManagementApp
              , novelReaderApp = first novelReaderApp
              , profileApp = first profileApp
      }
    , Cmd.batch <|
      List.append
        [ Cmd.map ReaderMsg <| second readerApp
        , Cmd.map CharacterMsg <| second characterApp
        , Cmd.map NovelReaderMsg <| second novelReaderApp
        , Cmd.map NarrationIntroMsg <| second narrationIntroApp
        ]
        (protectedCmds
          model.session
          [ Cmd.map DashboardMsg <| second dashboardApp
          , Cmd.map NarrationArchiveMsg <| second narrationArchiveApp
          , Cmd.map NarrationCreationMsg <| second narrationCreationApp
          , Cmd.map NarrationOverviewMsg <| second narrationOverviewApp
          , Cmd.map ChapterEditMsg <| second chapterEditApp
          , Cmd.map ChapterControlMsg <| second chapterControlApp
          , Cmd.map CharacterCreationMsg <| second characterCreationApp
          , Cmd.map CharacterEditMsg <| second characterEditApp
          , Cmd.map UserManagementMsg <| second userManagementApp
          , Cmd.map ProfileMsg <| second profileApp
          ])
    )


combinedUpdate : Msg -> Model -> ( Model, Cmd Msg )
combinedUpdate msg model =
  case msg of
    NoOp ->
      ( model, Cmd.none )
    NavigateTo urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          ( model, Nav.pushUrl model.key (Url.toString url) )
        Browser.External href ->
          ( model, Nav.load href )
    UpdateLocation newLocation ->
      let
        newRoute = Routing.fromUrl newLocation
        updatedModel = { model | route = newRoute }
      in
        dispatchEnterLocation updatedModel
    GoToFrontpage ->
      ( model, Nav.pushUrl model.key "/" )

    SessionFetchResult (Err err) ->
      let
        maybeUpdatedModel = 
          case err of
            Http.BadStatus 404 ->
              model
            _ ->
              { model | banner = errorBanner "Error checking session; staying as anonymous" }
      in
        dispatchEnterLocation { maybeUpdatedModel | session = Just AnonymousSession }

    SessionFetchResult (Ok session) ->
      dispatchEnterLocation { model | session = Just <| LoggedInSession session }

    UpdateEmail newEmail ->
      ( { model | email = newEmail
                , banner = Nothing
        }
      , Cmd.none
      )

    UpdatePassword newPassword ->
      ( { model | password = newPassword
                , banner = Nothing
        }
      , Cmd.none
      )

    Login ->
      ( model, Core.Api.login model.email model.password )

    LoginResult (Err err) ->
      ( { model | session = Just AnonymousSession
                , banner = errorBanner "Invalid credentials"
        }
      , Cmd.none
      )

    LoginResult (Ok resp) ->
      dispatchEnterLocation { model | session = Just <| LoggedInSession resp }

    ForgotPassword ->
      ( { model | forgotPasswordUi = True }, Cmd.none )

    BackToLogin ->
      ( { model | forgotPasswordUi = False }, Cmd.none )

    ResetPassword ->
      if model.email == "" then
        ( model, Cmd.none )
      else
        ( model, Core.Api.resetPassword model.email )

    ResetPasswordResult (Err err) ->
      case err of
        Http.BadBody parserError ->
          ( { model | banner = errorBanner <| "Cannot parse server response: " ++ parserError }
          , Cmd.none
          )
        Http.BadStatus status ->
          ( { model | banner = errorBanner <| "Could not get a proper server response; error code was " ++ (String.fromInt status) }
          , Cmd.none
          )
        _ ->
          ( { model | banner = errorBanner <| "Could not contact server" }
          , Cmd.none
          )

    ResetPasswordResult (Ok resp) ->
      ( { model | forgotPasswordUi = False
                , banner = successBanner <| "A password reset link was sent to " ++ model.email
        }
      , Cmd.none
      )

    Logout ->
      ( { model | session = Just AnonymousSession }
      , Core.Api.logout
      )

    LogoutResult _ ->
      (  model, Cmd.none )

    ReaderMsg readerMsg ->
      let
        ( newReaderModel, cmd ) =
          ReaderApp.update readerMsg model.readerApp
      in
        ( { model | readerApp = newReaderModel }, Cmd.map ReaderMsg cmd )

    CharacterMsg characterMsg ->
      let
        ( newCharacterModel, cmd ) =
          CharacterApp.update characterMsg model.characterApp
      in
        ( { model | characterApp = newCharacterModel }, Cmd.map CharacterMsg cmd )

    NovelReaderMsg novelReaderMsg ->
      let
        ( newNovelReaderModel, cmd ) =
          NovelReaderApp.update novelReaderMsg model.novelReaderApp
      in
        ( { model | novelReaderApp = newNovelReaderModel }, Cmd.map NovelReaderMsg cmd )

    DashboardMsg dashboardMsg ->
      let
        ( newDashboardModel, cmd ) =
          DashboardApp.update dashboardMsg model.dashboardApp
      in
        ( { model | dashboardApp = newDashboardModel }
        , protectedCmd model.session <| Cmd.map DashboardMsg cmd
        )

    NarrationArchiveMsg narrationArchiveMsg ->
      let
        ( newNarrationArchiveModel, cmd ) =
          NarrationArchiveApp.update narrationArchiveMsg model.narrationArchiveApp
      in
        ( { model | narrationArchiveApp = newNarrationArchiveModel }
        , protectedCmd model.session <| Cmd.map NarrationArchiveMsg cmd
        )

    NarrationCreationMsg narrationCreationMsg ->
      let
        ( newNarrationCreationModel, cmd ) =
          NarrationCreationApp.update narrationCreationMsg model.narrationCreationApp
      in
        ( { model | narrationCreationApp = newNarrationCreationModel }
        , protectedCmd model.session <| Cmd.map NarrationCreationMsg cmd
        )

    NarrationOverviewMsg narrationOverviewMsg ->
      let
        ( newNarrationOverviewModel, cmd ) =
          NarrationOverviewApp.update narrationOverviewMsg model.narrationOverviewApp
      in
        ( { model | narrationOverviewApp = newNarrationOverviewModel }
        , protectedCmd model.session <| Cmd.map NarrationOverviewMsg cmd
        )

    NarrationIntroMsg narrationIntroMsg ->
      let
        ( newNarrationIntroModel, cmd ) =
          NarrationIntroApp.update narrationIntroMsg model.narrationIntroApp
      in
        ( { model | narrationIntroApp = newNarrationIntroModel }
        , Cmd.map NarrationIntroMsg cmd
        )

    ChapterEditMsg chapterEditMsg ->
      let
        ( newNarratorModel, cmd ) =
          ChapterEditApp.update chapterEditMsg model.chapterEditApp
      in
        ( { model | chapterEditApp = newNarratorModel }
        , protectedCmd model.session <| Cmd.map ChapterEditMsg cmd
        )

    ChapterControlMsg chapterControlMsg ->
      let
        ( newChapterControlModel, cmd ) =
          ChapterControlApp.update chapterControlMsg model.chapterControlApp
      in
        ( { model | chapterControlApp = newChapterControlModel }
        , protectedCmd model.session <| Cmd.map ChapterControlMsg cmd
        )

    CharacterCreationMsg characterCreationMsg ->
      let
        ( newCharacterCreationModel, cmd ) =
          CharacterCreationApp.update characterCreationMsg model.characterCreationApp
      in
        ( { model | characterCreationApp = newCharacterCreationModel }
        , protectedCmd model.session <| Cmd.map CharacterCreationMsg cmd
        )

    CharacterEditMsg characterEditMsg ->
      let
        ( newCharacterEditModel, cmd ) =
          CharacterEditApp.update characterEditMsg model.characterEditApp
      in
        ( { model | characterEditApp = newCharacterEditModel }
        , protectedCmd model.session <| Cmd.map CharacterEditMsg cmd
        )

    UserManagementMsg userManagementMsg ->
      let
        ( newUserManagementModel, cmd ) =
          UserManagementApp.update userManagementMsg model.userManagementApp
      in
        ( { model | userManagementApp = newUserManagementModel }
        , protectedCmd model.session <| Cmd.map UserManagementMsg cmd
        )

    ProfileMsg profileMsg ->
      let
        ( newProfileModel, cmd ) =
          ProfileApp.update profileMsg model.profileApp
      in
        ( { model | profileApp = newProfileModel }
        , protectedCmd model.session <| Cmd.map ProfileMsg cmd
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map ReaderMsg (ReaderApp.subscriptions model.readerApp)
        , Sub.map CharacterMsg (CharacterApp.subscriptions model.characterApp)
        , Sub.map DashboardMsg (DashboardApp.subscriptions model.dashboardApp)
        , Sub.map NarrationArchiveMsg (NarrationArchiveApp.subscriptions model.narrationArchiveApp)
        , Sub.map NarrationCreationMsg (NarrationCreationApp.subscriptions model.narrationCreationApp)
        , Sub.map NarrationOverviewMsg (NarrationOverviewApp.subscriptions model.narrationOverviewApp)
        , Sub.map NarrationIntroMsg (NarrationIntroApp.subscriptions model.narrationIntroApp)
        , Sub.map ChapterEditMsg (ChapterEditApp.subscriptions model.chapterEditApp)
        , Sub.map ChapterControlMsg (ChapterControlApp.subscriptions model.chapterControlApp)
        , Sub.map CharacterCreationMsg (CharacterCreationApp.subscriptions model.characterCreationApp)
        , Sub.map CharacterEditMsg (CharacterEditApp.subscriptions model.characterEditApp)
        , Sub.map UserManagementMsg (UserManagementApp.subscriptions model.userManagementApp)
        , Sub.map NovelReaderMsg (NovelReaderApp.subscriptions model.novelReaderApp)
        , Sub.map ProfileMsg (ProfileApp.subscriptions model.profileApp)
        ]


main : Program () Model Msg
main =
  Browser.application
    { init = initialState
    , view = Core.Views.mainView
    , update = combinedUpdate
    , subscriptions = subscriptions
    , onUrlRequest = NavigateTo
    , onUrlChange = UpdateLocation
    }
    
