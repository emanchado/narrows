module Core.Views exposing (..)

import Html.App as App
import Html exposing (Html, nav, div, span, a, form, input, code, text, img, label, button, br)
import Html.Attributes exposing (class, type', placeholder, autofocus, href)
import Html.Events exposing (onInput, onClick, onSubmit)

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

import Core.Messages exposing (Msg(..))
import Core.Models exposing (Model, UserSession(..))
import Common.Views

notFoundView : Html Msg
notFoundView =
  div []
    [ div [] [ text "404 Not Found" ]
    ]

unregisteredPageView : Html Msg
unregisteredPageView =
  div []
    [ div []
        [ text "Cannot page the page: maybe you forgot to register it in "
        , code [] [ text "Core.Views" ]
        , text "?"
        ]
    ]

loginView : Html Msg
loginView =
  div [ class "login-page" ]
    [ div [ class "site-title" ]
        [ text "Narrows - NARRation On Web System" ]
    , form [ class "login-form"
           , onSubmit Login
           ]
        [ div [ class "form-line" ]
            [ label [] [ text "E-mail:" ]
            , input [ placeholder "user@example.com"
                    , onInput UpdateEmail
                    ] []
            ]
        , div [ class "form-line" ]
            [ label [] [ text "Password:" ]
            , input [ type' "password"
                    , placeholder "Password"
                    , onInput UpdatePassword
                    ]
                []
            ]
        , div [ class "form-line form-actions" ]
            [ button [ class "btn btn-default"
                     , type' "submit"
                     , onClick Login
                     ]
                [ text "Login" ]
            ]
        ]
    ]

dispatchProtectedPage : Model -> Html Msg
dispatchProtectedPage model =
  case model.route of
    Routing.NarratorIndex ->
      App.map NarratorDashboardMsg (NarratorDashboardApp.view model.narratorDashboardApp)
    Routing.NarrationCreationPage ->
      App.map NarrationCreationMsg (NarrationCreationApp.view model.narrationCreationApp)
    Routing.NarrationPage narrationId ->
      App.map NarrationOverviewMsg (NarrationOverviewApp.view model.narrationOverviewApp)
    Routing.CreateChapterPage narrationId ->
      App.map ChapterEditMsg (ChapterEditApp.view model.chapterEditApp)
    Routing.ChapterEditNarratorPage chapterId ->
      App.map ChapterEditMsg (ChapterEditApp.view model.chapterEditApp)
    Routing.ChapterControlPage chapterId ->
      App.map ChapterControlMsg (ChapterControlApp.view model.chapterControlApp)
    Routing.CharacterCreationPage chapterId ->
      App.map CharacterCreationMsg (CharacterCreationApp.view model.characterCreationApp)
    Routing.UserManagementPage ->
      App.map UserManagementMsg (UserManagementApp.view model.userManagementApp)

    _ ->
      -- Something went wrong, eg. forgot to register the new page
      unregisteredPageView

appContentView : Model -> Html Msg
appContentView model =
  case model.route of
    Routing.ChapterReaderPage chapterId characterToken ->
      App.map ReaderMsg (ReaderApp.view model.readerApp)
    Routing.CharacterPage characterToken ->
      App.map CharacterMsg (CharacterApp.view model.characterApp)
    Routing.NotFoundRoute ->
      notFoundView
    _ ->
      case model.session of
        Just session ->
          case session of
            Core.Models.AnonymousSession ->
              loginView
            Core.Models.LoggedInSession _ ->
              dispatchProtectedPage model
        Nothing ->
          Common.Views.loadingView Nothing

adminLinks : Maybe UserSession -> List (Html Msg)
adminLinks maybeSession =
  case maybeSession of
    Just session ->
      case session of
        AnonymousSession ->
          []
        LoggedInSession userInfo ->
          if userInfo.role == "admin" then
            [ a (Common.Views.linkTo NavigateTo "/users")
                [ text "Manage users" ]
            ]
          else
            []
    Nothing ->
      []

mainView : Model -> Html Msg
mainView model =
  let
    baseLinks = [ a (Common.Views.linkTo NavigateTo "/")
                    [ div [ class "logo" ] [ text "NARROWS" ] ]
                ]
    finalLinks = List.concat [ baseLinks, adminLinks model.session ]
  in
    case model.session of
      Just session ->
        case session of
          AnonymousSession ->
            appContentView model
          LoggedInSession _ ->
            div []
              [ nav [ class "top-bar" ] finalLinks
              , appContentView model
              ]
      Nothing ->
        appContentView model
