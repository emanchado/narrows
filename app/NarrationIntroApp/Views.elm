module NarrationIntroApp.Views exposing (..)

import String
import Html exposing (Html, main_, aside, h1, h2, div, form, input, label, button, br, audio, img, ul, li, a, strong, text)
import Html.Attributes exposing (id, class, style, src, preload, loop, alt, href, type_, placeholder, value, checked, for, width, height)
import Html.Events exposing (onInput, onClick)

import Common.Models exposing (ParticipantCharacter, UserSession(..))
import Common.Models.Reading exposing (PageState(..))
import Common.Views exposing (avatarUrl, bannerView, horizontalSpinner, loadingView)
import Common.Views.Reading exposing (backgroundImageStyle, chapterContainerClass)
import NarrationIntroApp.Messages exposing (..)
import NarrationIntroApp.Models exposing (Model)


loadedView : Maybe String -> Bool -> Html Msg
loadedView maybeAudio backgroundMusicOn =
  div [ id "loader-contents" ]
    [ div [ id "start-ui" ]
        [ button [ onClick StartNarration ]
            [ text "Start" ]
        , case maybeAudio of
            Just _ ->
              div []
                [ input [ id "music"
                        , type_ "checkbox"
                        , checked backgroundMusicOn
                        , onClick ToggleBackgroundMusic
                        ]
                    []
                , label [ for "music" ] [ text "Background music" ]
                ]
            Nothing ->
              text ""
        ]
    ]


characterView : String -> Int -> Bool -> ParticipantCharacter -> Html Msg
characterView email narrationId showEmailBox participant =
    li [ class "peekaboo-container" ]
      [ img [ class "avatar"
            , width 100
            , height 100
            , src <| avatarUrl narrationId participant.avatar
            ]
          []
      , div [ class "character-description-container" ]
          [ strong [] [ text participant.name ]
          , br [] []
          , div [ id <| "description-character-" ++ (String.fromInt participant.id)
                , class "character-description"
                ]
              []
          , br [] []
          , (if participant.claimed then
               text ""
             else
               div [ class "inline-form" ]
                 (List.append
                    (if showEmailBox then
                       [ label [ class "peekaboo-item" ]
                           [ text "Claim character as:" ]
                       , input [ class "peekaboo-item"
                               , type_ "email"
                               , onInput UpdateEmail
                               , value email
                               , placeholder "someone@example.com"
                               ]
                           []
                       ]
                     else
                       [])
                    [ button [ class "btn"
                             , onClick <| ClaimCharacter participant.id email
                             ]
                        [ text "Claim" ]]))
          ]
      ]


introView : Model -> Html Msg
introView model =
  case model.narrationIntro of
    Just narrationIntro ->
      div []
        [ div [ id "chapter-container"
              , class (chapterContainerClass model.state)
              ]
            [ div (List.append
                     [ id "top-image" ]
                     (backgroundImageStyle narrationIntro.id narrationIntro.backgroundImage model.backgroundBlurriness))
                [ text (if String.isEmpty narrationIntro.title then
                          "Untitled"
                        else
                          narrationIntro.title)
                ]
            , case narrationIntro.audio of
                Just _ ->
                  img [ id "play-icon"
                      , src ("/img/" ++ (if model.musicPlaying then
                                           "play"
                                         else
                                           "mute") ++
                               "-small.png")
                      , alt (if model.musicPlaying then "Stop" else "Start")
                      , onClick PlayPauseMusic
                      ]
                    []
                Nothing ->
                  text ""
            , div [ id "chapter-text", class "chapter" ]
                [ text "Chapter contents go here" ]
            , bannerView model.banner
            , div [ class "interaction" ]
                (case model.session of
                     Nothing ->
                       [ horizontalSpinner ]

                     Just AnonymousSession ->
                       [ h2 [] [ text "Dramatis personae" ]
                       , ul [ class "dramatis-personae" ]
                           (List.map
                              (characterView model.email narrationIntro.id True)
                              narrationIntro.characters)
                       ]

                     Just (LoggedInSession userInfo) ->
                       [ h2 [] [ text "Dramatis personae" ]
                       , ul [ class "dramatis-personae" ]
                           (List.map
                              (characterView userInfo.email narrationIntro.id False)
                              narrationIntro.characters)
                       ])
            ]
        , case narrationIntro.audio of
            Just audioUrl ->
              audio [ id "background-music"
                    , src ("/static/narrations/" ++
                             (String.fromInt narrationIntro.id) ++
                             "/audio/" ++
                             audioUrl)
                    , loop True
                    , preload (if model.backgroundMusic then
                                 "auto"
                               else
                                 "none")
                    ]
                []
            Nothing ->
              text ""
        ]

    Nothing ->
      div [ id "chapter-container"
          , class (chapterContainerClass model.state)
          ]
        [ text "There isn't any narration with that token."
        , bannerView model.banner
        ]


mainView : Model -> Html Msg
mainView model =
  case model.narrationIntro of
    Just narrationIntro ->
      div [ id "reader-app" ]
        [ case model.state of
            Loader ->
              div [ id "loader" ]
                [ loadedView narrationIntro.audio model.backgroundMusic
                ]

            _ ->
              text ""
        , introView model
        ]
    Nothing ->
      div [ id "loader" ]
        [ div [ id "loader-contents" ]
            [ loadingView model.banner ]
        ]
