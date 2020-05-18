module DashboardApp.Views exposing (..)

import List
import Html exposing (Html, main_, h1, h2, div, button, ul, li, a, strong, em, text, img, span, pre)
import Html.Attributes exposing (id, class, href, src, height, width)
import Html.Events exposing (onClick)
import Common.Views exposing (loadingView, compactNarrationView, avatarUrl, ribbonForNarrationStatus, bannerView)
import Common.Models exposing (CharacterInfo, NarrationStatus(..), narrationStatusString)
import DashboardApp.Messages exposing (..)
import DashboardApp.Models exposing (Model, DashboardScreen(..))


participationView : CharacterInfo -> Html Msg
participationView character =
  div [ class "participation-container" ]
    [ ribbonForNarrationStatus character.narration.status
    , h2 [] [ text character.narration.title ]
    , div [ class "character-container" ]
        [ img [ class "avatar"
              , width 50
              , height 50
              , src <| avatarUrl character.narration.id character.avatar
              ]
            []
        , span []
            [ a [ href <| "/characters/" ++ character.token
                ]
                [ text character.name ]
            ]
        ]
    , div []
            [ text "Latest chapter: "
            , case List.head <| List.reverse character.narration.chapters of
                Just chapter ->
                  a [ href <| "/read/" ++ (String.fromInt chapter.id) ++ "/" ++ character.token ]
                    [ text chapter.title ]
                Nothing ->
                  em [] [ text "None yet" ]
            ]
    ]


indexScreenView : Model -> Html Msg
indexScreenView model =
  main_ [ id "narrator-app"
        , class "app-container"
        ]
    [ h1 [] [ text "Stories you are narrating" ]
    , case model.narrations of
        Just [] ->
          div [ class "narration-list" ]
            [ text "None. Create a new one with the button below." ]

        Just narrations ->
          div [ class "narration-list" ]
            (List.map (compactNarrationView NavigateTo) narrations)

        Nothing ->
          loadingView model.banner
    , div [ class "btn-bar" ]
        [ button [ class "btn"
                 , onClick NarrationArchive
                 ]
            [ text "Narration Archive" ]
        , button [ class "btn btn-add"
                 , onClick NewNarration
                 ]
            [ text "New narration" ]
        ]
    , h1 [] [ text "Characters you are playing" ]
    , case model.characters of
        Just [] ->
          div [ class "participation-list" ]
            [ text "None. Claim a character in a story and it will appear here." ]

        Just characters ->
          div [ class "participation-list" ]
            (List.map participationView characters)

        Nothing ->
          text ""
    , div [ class "btn-bar" ]
        [ button [ class "btn"
                 , onClick CharacterArchive
                 ]
            [ text "Character Archive" ]
        ]
    ]


narrationArchiveView : Model -> Html Msg
narrationArchiveView model =
    main_ [ id "narrator-app"
          , class "app-container"
          ]
      [ h1 [] [ text "Narration archive" ]
      , case model.allNarrations of
          Just [] ->
            div [ class "narration-list" ]
              [ text "You have never created any narrations."
              , text " You can create one from the front page."
              ]

          Just narrations ->
            div [ class "narration-list" ]
              (List.map (compactNarrationView NavigateTo) narrations)

          Nothing ->
            loadingView model.banner
      ]


characterArchiveView : Model -> Html Msg
characterArchiveView model =
    main_ [ id "narrator-app"
          , class "app-container"
          ]
      [ h1 [] [ text "Characters you are playing" ]
      , case model.allCharacters of
          Just [] ->
            div [ class "participation-list" ]
              [ text "You have never claimed a character in a narration."
              , text " Claim one and it will appear here."
              ]

          Just characters ->
            div [ class "participation-list" ]
              (List.map participationView characters)

          Nothing ->
            text ""
      ]


mainView : Model -> Html Msg
mainView model =
  div []
    [ bannerView model.banner
    , case model.screen of
        IndexScreen ->
          indexScreenView model
        NarrationArchiveScreen ->
          narrationArchiveView model
        CharacterArchiveScreen ->
          characterArchiveView model
    ]
