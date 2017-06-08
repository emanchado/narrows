module Main exposing (..)

import Navigation
import Tuple exposing (first, second)

import Routing
import Common.Models exposing (errorBanner)
import Core.Api
import Core.Views
import Core.Models exposing (Model, UserSession(..))
import Core.Messages exposing (Msg(..))

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


initialState : Navigation.Location -> (Model, Cmd Msg)
initialState location =
  ( { route = Routing.parseLocation location
    , session = Nothing
    , banner = Nothing
    , email = ""
    , password = ""
    , readerApp = ReaderApp.initialState
    , characterApp = CharacterApp.initialState
    , narratorDashboardApp = NarratorDashboardApp.initialState
    , narrationArchiveApp = NarrationArchiveApp.initialState
    , narrationCreationApp = NarrationCreationApp.initialState
    , narrationOverviewApp = NarrationOverviewApp.initialState
    , chapterEditApp = ChapterEditApp.initialState
    , chapterControlApp = ChapterControlApp.initialState
    , characterCreationApp = CharacterCreationApp.initialState
    , userManagementApp = UserManagementApp.initialState
    , novelReaderApp = NovelReaderApp.initialState
    , profileApp = ProfileApp.initialState
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

    chapterEditApp = ChapterEditApp.urlUpdate currentRoute model.chapterEditApp
    narratorDashboardApp = NarratorDashboardApp.urlUpdate currentRoute model.narratorDashboardApp
    narrationArchiveApp = NarrationArchiveApp.urlUpdate currentRoute model.narrationArchiveApp
    narrationCreationApp = NarrationCreationApp.urlUpdate currentRoute model.narrationCreationApp
    narrationOverviewApp = NarrationOverviewApp.urlUpdate currentRoute model.narrationOverviewApp
    chapterControlApp = ChapterControlApp.urlUpdate currentRoute model.chapterControlApp
    characterCreationApp = CharacterCreationApp.urlUpdate currentRoute model.characterCreationApp
    userManagementApp = UserManagementApp.urlUpdate currentRoute model.userManagementApp
    profileApp = ProfileApp.urlUpdate currentRoute model.profileApp
  in
    ( { model | route = currentRoute
              , readerApp = first readerApp
              , characterApp = first characterApp
              , narratorDashboardApp = first narratorDashboardApp
              , narrationArchiveApp = first narrationArchiveApp
              , narrationCreationApp = first narrationCreationApp
              , narrationOverviewApp = first narrationOverviewApp
              , chapterEditApp = first chapterEditApp
              , chapterControlApp = first chapterControlApp
              , characterCreationApp = first characterCreationApp
              , userManagementApp = first userManagementApp
              , novelReaderApp = first novelReaderApp
              , profileApp = first profileApp
      }
    , Cmd.batch <|
      List.append
        [ Cmd.map ReaderMsg <| second readerApp
        , Cmd.map CharacterMsg <| second characterApp
        , Cmd.map NovelReaderMsg <| second novelReaderApp
        ]
        (protectedCmds
          model.session
          [ Cmd.map NarratorDashboardMsg <| second narratorDashboardApp
          , Cmd.map NarrationArchiveMsg <| second narrationArchiveApp
          , Cmd.map NarrationCreationMsg <| second narrationCreationApp
          , Cmd.map NarrationOverviewMsg <| second narrationOverviewApp
          , Cmd.map ChapterEditMsg <| second chapterEditApp
          , Cmd.map ChapterControlMsg <| second chapterControlApp
          , Cmd.map CharacterCreationMsg <| second characterCreationApp
          , Cmd.map UserManagementMsg <| second userManagementApp
          , Cmd.map ProfileMsg <| second profileApp
          ])
    )


combinedUpdate : Msg -> Model -> ( Model, Cmd Msg )
combinedUpdate msg model =
  case msg of
    NavigateTo url ->
      ( model, Navigation.newUrl url )
    UpdateLocation newLocation ->
      let
        updatedModel = { model | route = Routing.parseLocation newLocation }
      in
        dispatchEnterLocation updatedModel

    SessionFetchResult (Err err) ->
      dispatchEnterLocation { model | session = Just AnonymousSession }

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

    Logout ->
      ( { model | session = Just AnonymousSession }
      , Core.Api.logout
      )

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

    NarratorDashboardMsg narratorDashboardMsg ->
      let
        ( newNarratorDashboardModel, cmd ) =
          NarratorDashboardApp.update narratorDashboardMsg model.narratorDashboardApp
      in
        ( { model | narratorDashboardApp = newNarratorDashboardModel }
        , protectedCmd model.session <| Cmd.map NarratorDashboardMsg cmd
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

    _ ->
      ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map ReaderMsg (ReaderApp.subscriptions model.readerApp)
        , Sub.map CharacterMsg (CharacterApp.subscriptions model.characterApp)
        , Sub.map NarratorDashboardMsg (NarratorDashboardApp.subscriptions model.narratorDashboardApp)
        , Sub.map NarrationArchiveMsg (NarrationArchiveApp.subscriptions model.narrationArchiveApp)
        , Sub.map NarrationCreationMsg (NarrationCreationApp.subscriptions model.narrationCreationApp)
        , Sub.map NarrationOverviewMsg (NarrationOverviewApp.subscriptions model.narrationOverviewApp)
        , Sub.map ChapterEditMsg (ChapterEditApp.subscriptions model.chapterEditApp)
        , Sub.map ChapterControlMsg (ChapterControlApp.subscriptions model.chapterControlApp)
        , Sub.map CharacterCreationMsg (CharacterCreationApp.subscriptions model.characterCreationApp)
        , Sub.map UserManagementMsg (UserManagementApp.subscriptions model.userManagementApp)
        , Sub.map NovelReaderMsg (NovelReaderApp.subscriptions model.novelReaderApp)
        , Sub.map ProfileMsg (ProfileApp.subscriptions model.profileApp)
        ]


main : Program Never Model Msg
main =
  Navigation.program UpdateLocation
    { init = initialState
    , update = combinedUpdate
    , subscriptions = subscriptions
    , view = Core.Views.mainView
    }
    
