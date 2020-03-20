module NarrationOverviewApp.Views exposing (..)

import List
import Html exposing (Html, main_, h1, h2, section, div, span, ul, li, button, img, input, label, a, em, text)
import Html.Attributes exposing (id, class, for, checked, name, title, type_, readonly, value, href, src)
import Html.Events exposing (onClick)
import Common.Models exposing (Narration, NarrationStatus(..), ChapterOverview, NarrationOverview, FullCharacter, narrationStatusString)
import Common.Views exposing (breadcrumbNavView, narrationOverviewView, loadingView, ribbonForNarrationStatus)
import NarrationOverviewApp.Messages exposing (..)
import NarrationOverviewApp.Models exposing (Model)


narrationCharacterView : Narration -> FullCharacter -> Html Msg
narrationCharacterView narration character =
  let
    avatarUrl =
      case character.avatar of
        Just avatar ->
          "/static/narrations/" ++ (String.fromInt narration.id) ++ "/avatars/" ++ avatar

        Nothing ->
          "/img/default-avatar.png"
  in
    li []
      [ img [ class "avatar"
            , src avatarUrl
            ]
          []
      , span []
          [ a [ href <| "/characters/" ++ (String.fromInt character.id) ++ "/edit"
              , title <| case character.email of
                           Just email -> "Played by " ++ email
                           Nothing -> "Unclaimed character"
              ]
              [ text character.name ]
          , case character.email of
              Just _ ->
                text ""
              Nothing ->
                text " — Unclaimed character"
          ]
      ]


overviewView : NarrationOverview -> Bool -> Html Msg
overviewView overview showUrlInfoBox =
  let
    isActive = overview.narration.status == Active
    chapterOptions = if isActive then
                       button [ class "btn btn-add"
                              , onClick (NavigateTo <| "/narrations/" ++ (String.fromInt overview.narration.id) ++ "/new")
                              ]
                         [ text "New chapter" ]
                     else
                       text ""
    characterOptions = if isActive then
                         button [ class "btn btn-add"
                                , onClick (NavigateTo <| "/narrations/" ++ (String.fromInt overview.narration.id) ++ "/characters/new")
                                ]
                           [ text "New character" ]
                       else
                         text ""
  in
    main_ [ id "narrator-app", class "app-container" ]
      [ breadcrumbNavView
          [ { title = "Home"
            , url = "/"
            }
          ]
          (text overview.narration.title)
      , h1 []
          [ text <| "Narration " ++ overview.narration.title ++ " "
          , a [ class "btn btn-edit"
              , href <| "/narrations/" ++ (String.fromInt overview.narration.id) ++ "/edit" ]
              [ text "Edit" ]
          ]
      , div [ class <| "two-column narration-" ++ (narrationStatusString overview.narration.status) ]
          [ ribbonForNarrationStatus overview.narration.status
          , section []
              [ h2 [] [ text "Chapters" ]
              , chapterOptions
              , ul [ class "chapter-list" ] <|
                  narrationOverviewView NavigateTo overview
              ]
          , section [ class "page-aside" ]
              [ h2 [] [ text "Characters" ]
              , characterOptions
              , ul [ class "dramatis-personae compact" ]
                  (List.map (narrationCharacterView overview.narration) overview.narration.characters)
              , div [ class "vertical-form small-form" ]
                  [ label [] [ text "Narration intro URL: "
                             , img [ src "/img/info-black.png"
                                   , class "help"
                                   , onClick ToggleURLInfoBox
                                   ]
                                 []
                             ]
                  , if showUrlInfoBox then
                      div [ class "floating-tip" ]
                        [ text "Send this URL to potential players, "
                        , text "including posting on public forums. Anyone "
                        , text "with access to this URL will be able to "
                        , text "claim a character in the story, even if "
                        , text "they didn't have an account in NARROWS."
                        ]
                    else
                      text ""
                  , input [ readonly True
                          , type_ "text"
                          , value overview.narration.introUrl
                          ]
                      []
                  ]
              , h2 [] [ text "Status" ]
              , div [ class "narration-status" ]
                  [ input [ type_ "radio"
                          , id "narration-status-active"
                          , name "narration-status"
                          , onClick <| MarkNarration Active
                          , checked (overview.narration.status == Active)
                          ]
                      []
                  , label [ for "narration-status-active" ]
                      [ text "Active" ]
                  ]
              , div [ class "narration-status" ]
                  [ input [ type_ "radio"
                            , id "narration-status-finished"
                            , name "narration-status"
                            , onClick <| MarkNarration Finished
                            , checked (overview.narration.status == Finished)
                            ]
                        []
                  , label [ for "narration-status-finished" ]
                      [ text "Finished" ]
                  ]
              , div [ class "narration-status" ]
                  [ input [ type_ "radio"
                            , id "narration-status-abandoned"
                            , name "narration-status"
                            , onClick <| MarkNarration Abandoned
                            , checked (overview.narration.status == Abandoned)
                            ]
                        []
                  , label [ for "narration-status-abandoned" ]
                      [ text "Abandoned" ]
                  ]
              ]
          ]
      ]


mainView : Model -> Html Msg
mainView model =
  case model.narrationOverview of
    Just overview ->
      overviewView overview model.showUrlInfoBox

    Nothing ->
      loadingView model.banner
