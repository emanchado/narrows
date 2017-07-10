module Core.Views exposing (..)

import Html exposing (program)
import Html exposing (Html, nav, div, span, a, form, input, code, text, img, label, button, br)
import Html.Attributes exposing (class, type_, placeholder, autofocus, href, value)
import Html.Events exposing (onInput, onClick, onSubmit)

import Core.Messages exposing (Msg(..))
import Core.Models exposing (Model, UserSession(..))
import Core.Routes exposing (Route(..))
import Common.Views exposing (onPreventDefaultClick)

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


passwordResetFailureView : Model -> Html Msg
passwordResetFailureView model =
  div [ class "login-page" ]
    [ text "The password reset token wasn't valid, sorry."
    , div [ class "login-form" ]
        [ div [ class "form-actions" ]
            [ button [ class "btn btn-default"
                     , onClick <| NavigateTo "/"
                     ]
                [ text "Back to login page" ]
            ]
        ]
    ]


forgotPasswordView : Model -> Html Msg
forgotPasswordView model =
  div [ class "login-page" ]
    [ div [ class "site-title" ]
        [ text "Narrows - NARRation On Web System" ]
    , div []
        [ text "Forgotten password" ]
    , form [ class "login-form"
           , onSubmit ResetPassword
           ]
        [ div [ class "form-line" ]
            [ label [] [ text "E-mail:" ]
            , input [ type_ "email"
                    , placeholder "user@example.com"
                    , onInput UpdateEmail
                    , value model.email
                    ]
                []
            ]
        , div [ class "form-line form-actions" ]
          [ button [ class "btn btn-default"
                   , type_ "submit"
                   ]
              [ text "Reset password" ]
          , button [ class "btn"
                   , onPreventDefaultClick BackToLogin
                   ]
              [ text "Back to login" ]
          ]
        , Common.Views.bannerView model.banner
        ]
    ]


loginView : Model -> Html Msg
loginView model =
  div [ class "login-page" ]
    [ div [ class "site-title" ]
          [ text "Narrows - NARRation On Web System" ]
      , form [ class "login-form"
             , onSubmit Login
             ]
          [ div [ class "form-line" ]
              [ label [] [ text "E-mail:" ]
              , input [ type_ "email"
                      , placeholder "user@example.com"
                      , onInput UpdateEmail
                      , value model.email
                      ]
                  []
              ]
          , div [ class "form-line" ]
              [ label [] [ text "Password:" ]
              , input [ type_ "password"
                      , placeholder "Password"
                      , onInput UpdatePassword
                      ]
                  []
              ]
          , div [ class "form-line form-actions" ]
              [ button [ class "btn btn-default"
                       , type_ "submit"
                       ]
                  [ text "Login" ]
              , button [ class "btn"
                       , onPreventDefaultClick ForgotPassword
                       ]
                  [ text "Forgot password" ]
              ]
          , Common.Views.bannerView model.banner
          ]
      ]


dispatchProtectedPage : Model -> Html Msg
dispatchProtectedPage model =
  case model.route of
    NarratorIndex ->
      Html.map NarratorDashboardMsg (NarratorDashboardApp.view model.narratorDashboardApp)

    NarrationArchivePage ->
      Html.map NarrationArchiveMsg (NarrationArchiveApp.view model.narrationArchiveApp)

    NarrationCreationPage ->
      Html.map NarrationCreationMsg (NarrationCreationApp.view model.narrationCreationApp)

    NarrationEditPage narrationId ->
      Html.map NarrationCreationMsg (NarrationCreationApp.view model.narrationCreationApp)

    NarrationPage narrationId ->
      Html.map NarrationOverviewMsg (NarrationOverviewApp.view model.narrationOverviewApp)

    CreateChapterPage narrationId ->
      Html.map ChapterEditMsg (ChapterEditApp.view model.chapterEditApp)

    ChapterEditNarratorPage chapterId ->
      Html.map ChapterEditMsg (ChapterEditApp.view model.chapterEditApp)

    ChapterControlPage chapterId ->
      Html.map ChapterControlMsg (ChapterControlApp.view model.chapterControlApp)

    CharacterCreationPage chapterId ->
      Html.map CharacterCreationMsg (CharacterCreationApp.view model.characterCreationApp)

    UserManagementPage ->
      Html.map UserManagementMsg (UserManagementApp.view model.userManagementApp)

    ProfilePage ->
      Html.map ProfileMsg (ProfileApp.view model.profileApp)

    _ ->
      -- Something went wrong, eg. forgot to register the new page
      unregisteredPageView


appContentView : Model -> Html Msg
appContentView model =
  case model.route of
    ChapterReaderPage chapterId characterToken ->
      Html.map ReaderMsg (ReaderApp.view model.readerApp)

    NovelReaderPage novelToken ->
      Html.map NovelReaderMsg (NovelReaderApp.view model.novelReaderApp)

    NovelReaderChapterPage novelToken chapterIndex ->
      Html.map NovelReaderMsg (NovelReaderApp.view model.novelReaderApp)

    CharacterPage characterToken ->
      Html.map CharacterMsg (CharacterApp.view model.characterApp)

    PasswordResetFailure _ ->
      passwordResetFailureView model

    NotFoundRoute ->
      notFoundView

    _ ->
      case model.session of
        Just session ->
          case session of
            Core.Models.AnonymousSession ->
              if model.forgotPasswordUi then
                forgotPasswordView model
              else
                loginView model

            Core.Models.LoggedInSession _ ->
              dispatchProtectedPage model

        Nothing ->
          Common.Views.loadingView Nothing


actionLinks : Maybe UserSession -> List (Html Msg)
actionLinks maybeSession =
  let
    adminLinks =
      case maybeSession of
          Just session ->
              case session of
                  AnonymousSession ->
                      []

                  LoggedInSession userInfo ->
                      if userInfo.role == "admin" then
                          [ a (Common.Views.linkTo NavigateTo "/users")
                              [ text "Manage users" ]
                          , text " | "
                          ]
                      else
                          []

          Nothing ->
              []
  in
    List.concat [ [ a (Common.Views.linkTo NavigateTo "/profile")
                      [ text "Profile" ]
                  , text " | "
                  ]
                , adminLinks
                , [ a [ href "#"
                      , onClick Logout
                      ]
                      [ text "Log out" ]
                  ]
                ]


mainView : Model -> Html Msg
mainView model =
    let
        homeLink =
            [ a (Common.Views.linkTo NavigateTo "/")
                [ div [ class "logo" ] [ text "NARROWS" ] ]
            ]

        finalLinks =
            List.concat [ homeLink, [ div [] <| actionLinks model.session ] ]
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
