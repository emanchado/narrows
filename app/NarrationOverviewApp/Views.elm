module NarrationOverviewApp.Views exposing (..)

import List
import Html exposing (Html, main_, h1, h2, section, div, ul, li, button, img, a, em, text)
import Html.Attributes exposing (id, class, href, src)
import Html.Events exposing (onClick)
import Common.Models exposing (Narration, NarrationStatus(..), ChapterOverview, NarrationOverview, FullCharacter, narrationStatusString)
import Common.Views exposing (linkTo, breadcrumbNavView, narrationOverviewView)
import NarrationOverviewApp.Messages exposing (..)
import NarrationOverviewApp.Models exposing (Model, NarrationNovel)


narrationCharacterView : FullCharacter -> Html Msg
narrationCharacterView character =
  li []
    [ a (linkTo
           NavigateTo
           ("/characters/" ++ character.token))
        [ text character.name ]
    ]


narrationNovelView : String -> List NarrationNovel -> FullCharacter -> Html Msg
narrationNovelView narrationTitle novels character =
  let
    maybeNovel =
      List.filter
        (\n -> n.characterId == character.id)
        novels
        |> List.head
  in
    case maybeNovel of
      Just novel ->
        li []
          [ a [ href <| "/novels/" ++ novel.token ]
              [ text <| "“" ++ narrationTitle ++ "” from "
              , em [] [ text character.name ]
              , text "’s POV"
              ]
          ]

      Nothing ->
        li []
          [ text <| "No novel for " ++ character.name
          , button [ class "btn btn-add btn-inline"
                   , onClick (CreateNovel character.id)
                   ]
              []
          ]


overviewView : NarrationOverview -> List NarrationNovel -> Html Msg
overviewView overview novels =
  main_ [ id "narrator-app", class "app-container" ]
    [ breadcrumbNavView
        NavigateTo
        [ { title = "Home"
          , url = "/"
          }
        ]
        (text overview.narration.title)
    , h1 [] [ text <| "Narration " ++ overview.narration.title ]
    , div [ class "two-column" ]
        [ section []
            [ h2 [] [ text "Chapters" ]
            , button [ class "btn btn-add"
                     , onClick (NavigateTo <| "/narrations/" ++ (toString overview.narration.id) ++ "/new")
                     ]
                [ text "New chapter" ]
            , ul [ class "chapter-list" ] <|
                narrationOverviewView NavigateTo overview
            ]
        , section [ class "page-aside" ]
            [ h2 [] [ text "Characters" ]
            , button [ class "btn btn-add"
                     , onClick (NavigateTo <| "/narrations/" ++ (toString overview.narration.id) ++ "/characters/new")
                     ]
                [ text "New character" ]
            , ul [ class "character-list" ]
                (List.map narrationCharacterView overview.narration.characters)
            , h2 [] [ text "Status" ]
            , text "This narration is "
            , em [] [ text <| narrationStatusString overview.narration.status ]
            , text "."
            , div []
                [ case overview.narration.status of
                    Active ->
                      button [ class "btn"
                             , onClick <| MarkNarration Finished
                             ]
                        [ text "Mark as finished" ]
                    _ ->
                      button [ class "btn"
                             , onClick <| MarkNarration Active
                             ]
                        [ text "Mark as active" ]
                ]
            , h2 [] [ text "Novels" ]
            , ul [ class "novel-list" ]
                (List.map
                   (narrationNovelView overview.narration.title novels)
                   overview.narration.characters)
            ]
        ]
    ]


loadingView : Model -> Html Msg
loadingView model =
  case model.banner of
    Just banner ->
      div [ class ("banner banner-" ++ banner.type_) ]
        [ text banner.text ]

    Nothing ->
      div [] [ text "Loading" ]


mainView : Model -> Html Msg
mainView model =
  case model.narrationOverview of
    Just overview ->
      case model.narrationNovels of
        Just novels ->
          overviewView overview novels
        Nothing ->
          loadingView model

    Nothing ->
      loadingView model
