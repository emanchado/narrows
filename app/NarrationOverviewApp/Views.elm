module NarrationOverviewApp.Views exposing (..)

import List
import Html exposing (Html, main_, h1, h2, section, div, span, ul, li, form, button, img, input, textarea, label, a, em, p, text)
import Html.Attributes exposing (id, class, for, checked, disabled, name, title, type_, readonly, value, href, src, width, height, rows)
import Html.Events exposing (onClick, onInput, onSubmit)

import Common.Models exposing (Narration, NarrationStatus(..), ChapterOverview, NarrationOverview, FullCharacter, narrationStatusString)
import Common.Views exposing (breadcrumbNavView, narrationOverviewView, loadingView, ribbonForNarrationStatus, showDialog, bannerView, sanitizedTitle, characterAvatarView, AvatarSize(..))
import NarrationOverviewApp.Messages exposing (..)
import NarrationOverviewApp.Models exposing (Model)


unclaimed : FullCharacter -> Bool
unclaimed character =
  character.displayName == Nothing


narrationCharacterView : Narration -> FullCharacter -> Html Msg
narrationCharacterView narration character =
    li []
      [ characterAvatarView narration.id Small character
      , span []
          [ a [ href <| "/characters/" ++ (String.fromInt character.id) ++ "/edit"
              , title <| case character.displayName of
                           Just name -> "Played by " ++ name
                           Nothing -> "Unclaimed character"
              ]
              [ text character.name ]
          , case character.displayName of
              Just _ ->
                text ""
              Nothing ->
                text " — Unclaimed character"
          ]
      ]


overviewView : NarrationOverview -> Bool -> Bool -> Bool -> Html Msg
overviewView overview showUrlInfoBox showRemoveNarrationDialog notesModified =
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
          (text <| sanitizedTitle overview.narration.title)
      , h1 []
          [ text <| "Narration " ++ overview.narration.title ++ " "
          , a [ class "btn btn-edit"
              , href <| "/narrations/" ++ (String.fromInt overview.narration.id) ++ "/edit" ]
              [ text "Edit" ]
          ]
      , div [ class <| "two-column narration-" ++ (narrationStatusString overview.narration.status) ]
          [ ribbonForNarrationStatus overview.narration.status
          , section []
              [ div [ class "narration-header" ]
                  [ h2 [] [ text "Chapters" ]
                  , chapterOptions
                  ]
              , ul [ class "chapter-list" ] <|
                  narrationOverviewView False NavigateTo overview
              ]
          , section [ class "narrow-column" ] <|
              List.append
                (if List.any unclaimed overview.narration.characters then
                   [ div [ class "narration-header" ]
                       [ h2 [] [ text "Intro" ]
                       , a [ class "btn btn-edit"
                           , href <| "/narrations/" ++ (String.fromInt overview.narration.id) ++ "/edit" ]
                           [ text "Edit" ]
                       ]
                   , p []
                       [ text "Send this URL to potential players, "
                       , text "including posting on public forums. Anyone "
                       , text "with access to this URL will be able to "
                       , text "claim a character in the story, even if "
                       , text "they didn't have an account in NARROWS."
                       ]
                   , div [ class "single-field-form" ]
                       [ input [ type_ "text"
                               , readonly True
                               , value overview.narration.introUrl
                               ]
                           []
                       , button [ onClick (CopyText overview.narration.introUrl)
                                ]
                           [ text "Copy" ]
                       ]
                   ]
                 else
                   [])
                [ div [ class "narration-header" ]
                   [ h2 [] [ text "Characters" ]
                    , characterOptions ]
                , ul [ class "dramatis-personae compact" ]
                    (List.map (narrationCharacterView overview.narration) overview.narration.characters)
                , h2 [] [ text "Notes" ]
                , form [ class "vertical-form"
                       , onSubmit SaveNarrationNotes
                       ]
                    [ textarea [ rows 10
                               , onInput UpdateNarrationNotes
                               ]
                        [ text overview.narration.notes ]
                    , div [ class "btn-bar" ]
                      [ button [ type_ "submit"
                               , class "btn btn-default"
                               , disabled (not notesModified)
                               ]
                          [ text "Save" ]
                      ]
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
                , div [ class "btn-bar" ]
                    [ button [ class "btn btn-remove"
                             , onClick RemoveNarration
                             ]
                        [ text "Delete" ]
                    ]
                , if showRemoveNarrationDialog then
                    let
                      extraNarrationDescription =
                        if overview.narration.status == Abandoned then
                          ""
                        else
                          (String.toUpper <|
                             narrationStatusString overview.narration.status) ++ " "
                    in
                      showDialog
                        ("Delete this " ++ extraNarrationDescription ++ "narration, with all its chapters and characters?")
                        NoOp
                        "Delete"
                        ConfirmRemoveNarration
                        "Cancel"
                        CancelRemoveNarration
                  else
                    text ""
                ]
          ]
      ]


mainView : Model -> Html Msg
mainView model =
  case model.narrationOverview of
    Just overview ->
      div []
        [ bannerView model.banner
        , overviewView overview model.showUrlInfoBox model.showRemoveNarrationDialog model.notesModified
        ]

    Nothing ->
      loadingView model.banner
