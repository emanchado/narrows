import Navigation
import Http
import Json.Decode

import Routing
import ReaderApp
import CharacterApp
import NarratorDashboardApp
import NarrationCreationApp
import NarrationOverviewApp
import ChapterEditApp
import ChapterControlApp
import CharacterCreationApp
import UserManagementApp
import NovelReaderApp

import Core.Api
import Core.Models exposing (Model, UserSession(..))
import Core.Messages exposing (Msg(..))
import Core.Views


initialState : Result String Routing.Route -> (Model, Cmd Msg)
initialState result =
  let
    currentRoute = Routing.routeFromResult result
  in
    ( { route = currentRoute
      , session = Nothing
      , email = ""
      , password = ""
      , readerApp = ReaderApp.initialState
      , characterApp = CharacterApp.initialState
      , narratorDashboardApp = NarratorDashboardApp.initialState
      , narrationCreationApp = NarrationCreationApp.initialState
      , narrationOverviewApp = NarrationOverviewApp.initialState
      , chapterEditApp = ChapterEditApp.initialState
      , chapterControlApp = ChapterControlApp.initialState
      , characterCreationApp = CharacterCreationApp.initialState
      , userManagementApp = UserManagementApp.initialState
      , novelReaderApp = NovelReaderApp.initialState
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

combinedUrlUpdate : Result String Routing.Route -> Model -> (Model, Cmd Msg)
combinedUrlUpdate result model =
  let
    currentRoute = Routing.routeFromResult result
    (updatedReaderModel, readerCmd) = ReaderApp.urlUpdate currentRoute model.readerApp
    (updatedCharacterModel, characterCmd) = CharacterApp.urlUpdate currentRoute model.characterApp
    (updatedNarratorModel, narratorCmd) = ChapterEditApp.urlUpdate currentRoute model.chapterEditApp
    (updatedNarratorDashboardModel, narratorDashboardCmd) = NarratorDashboardApp.urlUpdate currentRoute model.narratorDashboardApp
    (updatedNarrationCreationModel, narrationCreationCmd) = NarrationCreationApp.urlUpdate currentRoute model.narrationCreationApp
    (updatedNarrationOverviewModel, narrationOverviewCmd) = NarrationOverviewApp.urlUpdate currentRoute model.narrationOverviewApp
    (updatedChapterControlModel, chapterControlCmd) = ChapterControlApp.urlUpdate currentRoute model.chapterControlApp
    (updatedCharacterCreationModel, characterCreationCmd) = CharacterCreationApp.urlUpdate currentRoute model.characterCreationApp
    (updatedUserManagementModel, userManagementCmd) = UserManagementApp.urlUpdate currentRoute model.userManagementApp
    (updatedNovelReaderModel, novelReaderCmd) = NovelReaderApp.urlUpdate currentRoute model.novelReaderApp
  in
    ( { model | route = currentRoute
              , readerApp = updatedReaderModel
              , characterApp = updatedCharacterModel
              , narratorDashboardApp = updatedNarratorDashboardModel
              , narrationCreationApp = updatedNarrationCreationModel
              , narrationOverviewApp = updatedNarrationOverviewModel
              , chapterEditApp = updatedNarratorModel
              , chapterControlApp = updatedChapterControlModel
              , characterCreationApp = updatedCharacterCreationModel
              , userManagementApp = updatedUserManagementModel
              , novelReaderApp = updatedNovelReaderModel
              }
    , Cmd.batch <|
        List.append
          [ Cmd.map ReaderMsg readerCmd
          , Cmd.map CharacterMsg characterCmd
          , Cmd.map NovelReaderMsg novelReaderCmd
          ]
          (protectedCmds
             model.session
             [ Cmd.map NarratorDashboardMsg narratorDashboardCmd
             , Cmd.map NarrationCreationMsg narrationCreationCmd
             , Cmd.map NarrationOverviewMsg narrationOverviewCmd
             , Cmd.map ChapterEditMsg narratorCmd
             , Cmd.map ChapterControlMsg chapterControlCmd
             , Cmd.map CharacterCreationMsg characterCreationCmd
             , Cmd.map UserManagementMsg userManagementCmd
             ])
    )

combinedUpdate : Msg -> Model -> (Model, Cmd Msg)
combinedUpdate msg model =
  case msg of
    NavigateTo url ->
      (model, Navigation.newUrl url)

    SessionFetchSuccess session ->
      combinedUrlUpdate
        (Ok model.route)
        { model | session = Just <| LoggedInSession session }
    SessionFetchError err ->
      combinedUrlUpdate
        (Ok model.route)
        { model | session = Just AnonymousSession }

    UpdateEmail newEmail ->
      ({ model | email = newEmail }, Cmd.none)
    UpdatePassword newPassword ->
      ({ model | password = newPassword }, Cmd.none)
    Login ->
      (model, Core.Api.login model.email model.password)
    LoginSuccess resp ->
      case resp.value of
        Http.Text text ->
          let
            decodedResponse =
              Json.Decode.decodeString Core.Api.parseSession text
          in
            case decodedResponse of
              Ok result ->
                combinedUrlUpdate
                  (Ok model.route)
                  { model | session = Just <| LoggedInSession result }
              _ ->
                (model, Cmd.none)
        _ ->
          (model, Cmd.none)
    LoginError err ->
      ({ model | session = Just AnonymousSession }, Cmd.none)

    ReaderMsg readerMsg ->
      let
        (newReaderModel, cmd) = ReaderApp.update readerMsg model.readerApp
      in
        ({ model | readerApp = newReaderModel }, Cmd.map ReaderMsg cmd)
    CharacterMsg characterMsg ->
      let
        (newCharacterModel, cmd) = CharacterApp.update characterMsg model.characterApp
      in
        ({ model | characterApp = newCharacterModel }, Cmd.map CharacterMsg cmd)
    NovelReaderMsg novelReaderMsg ->
      let
        (newNovelReaderModel, cmd) = NovelReaderApp.update novelReaderMsg model.novelReaderApp
      in
        ({ model | novelReaderApp = newNovelReaderModel }, Cmd.map NovelReaderMsg cmd)

    NarratorDashboardMsg narratorDashboardMsg ->
      let
        (newNarratorDashboardModel, cmd) = NarratorDashboardApp.update narratorDashboardMsg model.narratorDashboardApp
      in
        ( { model | narratorDashboardApp = newNarratorDashboardModel }
        , protectedCmd model.session <| Cmd.map NarratorDashboardMsg cmd
        )
    NarrationCreationMsg narrationCreationMsg ->
      let
        (newNarrationCreationModel, cmd) = NarrationCreationApp.update narrationCreationMsg model.narrationCreationApp
      in
        ( { model | narrationCreationApp = newNarrationCreationModel }
        , protectedCmd model.session <| Cmd.map NarrationCreationMsg cmd
        )
    NarrationOverviewMsg narrationOverviewMsg ->
      let
        (newNarrationOverviewModel, cmd) = NarrationOverviewApp.update narrationOverviewMsg model.narrationOverviewApp
      in
        ( { model | narrationOverviewApp = newNarrationOverviewModel }
        , protectedCmd model.session <| Cmd.map NarrationOverviewMsg cmd
        )
    ChapterEditMsg chapterEditMsg ->
      let
        (newNarratorModel, cmd) = ChapterEditApp.update chapterEditMsg model.chapterEditApp
      in
        ( { model | chapterEditApp = newNarratorModel }
        , protectedCmd model.session <| Cmd.map ChapterEditMsg cmd
        )
    ChapterControlMsg chapterControlMsg ->
      let
        (newChapterControlModel, cmd) = ChapterControlApp.update chapterControlMsg model.chapterControlApp
      in
        ( { model | chapterControlApp = newChapterControlModel }
        , protectedCmd model.session <| Cmd.map ChapterControlMsg cmd
        )
    CharacterCreationMsg characterCreationMsg ->
      let
        (newCharacterCreationModel, cmd) = CharacterCreationApp.update characterCreationMsg model.characterCreationApp
      in
        ( { model | characterCreationApp = newCharacterCreationModel }
        , protectedCmd model.session <| Cmd.map CharacterCreationMsg cmd
        )
    UserManagementMsg userManagementMsg ->
      let
        (newUserManagementModel, cmd) = UserManagementApp.update userManagementMsg model.userManagementApp
      in
        ( { model | userManagementApp = newUserManagementModel }
        , protectedCmd model.session <| Cmd.map UserManagementMsg cmd
        )

    _ ->
      (model, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch [ Sub.map ReaderMsg (ReaderApp.subscriptions model.readerApp)
            , Sub.map CharacterMsg (CharacterApp.subscriptions model.characterApp)
            , Sub.map NarratorDashboardMsg (NarratorDashboardApp.subscriptions model.narratorDashboardApp)
            , Sub.map NarrationCreationMsg (NarrationCreationApp.subscriptions model.narrationCreationApp)
            , Sub.map NarrationOverviewMsg (NarrationOverviewApp.subscriptions model.narrationOverviewApp)
            , Sub.map ChapterEditMsg (ChapterEditApp.subscriptions model.chapterEditApp)
            , Sub.map ChapterControlMsg (ChapterControlApp.subscriptions model.chapterControlApp)
            , Sub.map CharacterCreationMsg (CharacterCreationApp.subscriptions model.characterCreationApp)
            , Sub.map UserManagementMsg (UserManagementApp.subscriptions model.userManagementApp)
            , Sub.map NovelReaderMsg (NovelReaderApp.subscriptions model.novelReaderApp)
            ]

main : Program Never
main =
  Navigation.program Routing.parser
    { init = initialState
    , update = combinedUpdate
    , urlUpdate = combinedUrlUpdate
    , subscriptions = subscriptions
    , view = Core.Views.mainView
    }
