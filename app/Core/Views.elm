module Core.Views exposing (..)

import Html exposing (Html, nav, div, span, a, form, input, code, text, img, label, button, br, node)
import Html.Attributes exposing (id, class, type_, placeholder, autofocus, href, value, style)
import Html.Events exposing (onInput, onClick, onSubmit)
import Browser

import Core.Messages exposing (Msg(..))
import Core.Models exposing (Model)
import Core.Routes exposing (Route(..))
import Common.Models exposing (UserSession(..))
import Common.Views exposing (onPreventDefaultClick)

import ReaderApp
import CharacterApp
import DashboardApp
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


notFoundView : Html Msg
notFoundView =
  div []
    [ div [] [ text "404 Not Found" ]
    ]


unregisteredPageView : Html Msg
unregisteredPageView =
  div []
    [ div []
        [ text "Cannot view the page: maybe you forgot to register it in "
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
                     , onClick GoToFrontpage
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
    Dashboard ->
      Html.map DashboardMsg (DashboardApp.view model.dashboardApp)

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

    CharacterEditPage chapterId ->
      Html.map CharacterEditMsg (CharacterEditApp.view model.characterEditApp)

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

    NarrationIntroPage narrationToken ->
      Html.map NarrationIntroMsg (NarrationIntroApp.view model.narrationIntroApp)

    PasswordResetFailure _ ->
      passwordResetFailureView model

    NotFoundRoute ->
      notFoundView

    _ ->
      case model.session of
        Just session ->
          case session of
            AnonymousSession ->
              if model.forgotPasswordUi then
                forgotPasswordView model
              else
                loginView model

            LoggedInSession _ ->
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
                          [ a [ href "/users" ]
                              [ text "Manage users" ]
                          , text " | "
                          ]
                      else
                          []

          Nothing ->
              []
  in
    List.concat [ [ a [ href "/profile" ]
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


mainView : Model -> Browser.Document Msg
mainView model =
    let
        homeLink =
            [ a [ href "/" ]
                [ div [ class "logo" ] [ text "NARROWS" ] ]
            ]

        finalLinks =
            List.concat [ homeLink, [ div [] <| actionLinks model.session ] ]
    in
        case model.session of
            Just session ->
                case session of
                    AnonymousSession ->
                        Browser.Document
                          "NARROWS"
                          [ node
                              "svg"
                              [ id "ProseMirror-icon-collection"
                              , style "display" "none"
                              ]
                              []
                          , appContentView model
                          ]

                    LoggedInSession _ ->
                        Browser.Document
                          "NARROWS"
                          [ div []
                              [ nav [ class "top-bar" ] finalLinks
                              , appContentView model
                              ]
                          , node
                              "svg"
                              [ id "ProseMirror-icon-collection"
                              , style "display" "none"
                              ]
                              []
                          ]

            Nothing ->
                Browser.Document
                  "NARROWS"
                  [ node
                      "svg"
                      [ id "ProseMirror-icon-collection"
                      , style "display" "none"
                      ]
                      []
                  , appContentView model
                  ]
