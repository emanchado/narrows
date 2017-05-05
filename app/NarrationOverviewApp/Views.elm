module NarrationOverviewApp.Views exposing (..)

import List
import Html exposing (Html, main', h1, h2, section, div, ul, li, button, a, em, text)
import Html.Attributes exposing (id, class, href)
import Html.Events exposing (onClick)

import Common.Models exposing (Narration, ChapterOverview, NarrationOverview, FullCharacter)
import Common.Views exposing (linkTo, breadcrumbNavView)
import NarrationOverviewApp.Messages exposing (..)
import NarrationOverviewApp.Models exposing (Model, NarrationNovel)

unpublishedChapterView : ChapterOverview -> Html Msg
unpublishedChapterView chapterOverview =
  li []
    [ a (linkTo
           NavigateTo
           ("/chapters/" ++ (toString chapterOverview.id) ++ "/edit"))
        [ text chapterOverview.title ]
    , text (" - " ++ (toString <| List.length chapterOverview.reactions) ++
              " participants")
    ]

publishedChapterView : ChapterOverview -> Html Msg
publishedChapterView chapterOverview =
  let
    sentReactions =
      List.filter
        (\r -> case r.text of
                 Nothing -> False
                 _ -> True)
        chapterOverview.reactions
  in
    li []
      [ a (linkTo
             NavigateTo
             ("/chapters/" ++ (toString chapterOverview.id)))
          [ text chapterOverview.title ]
      , text (" - " ++ (toString <| List.length sentReactions) ++
                " / " ++ (toString <| List.length chapterOverview.reactions) ++
                " reactions (" ++ (toString chapterOverview.numberMessages) ++
                " messages)")
      ]

chapterOverviewView : ChapterOverview -> Html Msg
chapterOverviewView chapterOverview =
  case chapterOverview.published of
    Just published ->
      publishedChapterView chapterOverview
    Nothing ->
      unpublishedChapterView chapterOverview

narrationCharacterView : FullCharacter -> Html Msg
narrationCharacterView character =
  li []
    [ a (linkTo
           NavigateTo
           ("/characters/" ++ character.token))
        [ text character.name ]
    ]

narrationNovelView : Narration -> NarrationNovel -> Html Msg
narrationNovelView narration novel =
  let
    maybeCharacter =
      List.filter
        (\c -> c.id == novel.characterId)
        narration.characters
          |> List.head
  in
    case maybeCharacter of
      Just character ->
        li []
          [ a [ href <| "/novels/" ++ novel.token ]
              [ text <| "“" ++ narration.title ++ "” from "
              , em [] [ text character.name ]
              , text "’s POV"
              ]
          ]
      Nothing ->
        div []
          [ text <| "Cannot find character with id " ++ (toString novel.characterId) ++ " WTF" ]

overviewView : NarrationOverview -> List NarrationNovel -> Html Msg
overviewView overview novels =
  main' [ id "narrator-app", class "app-container" ]
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
            , ul [ class "chapter-list" ]
                (List.map chapterOverviewView overview.chapters)
            ]
        , section [ class "page-aside" ]
            [ h2 [] [ text "Characters" ]
            , button [ class "btn btn-add"
                     , onClick (NavigateTo <| "/narrations/" ++ (toString overview.narration.id) ++ "/characters/new")
                     ]
                [ text "New character" ]
            , ul [ class "character-list" ]
                (List.map narrationCharacterView overview.narration.characters)
            , h2 [] [ text "Novels" ]
            , ul [ class "novel-list" ]
                (List.map (narrationNovelView overview.narration) novels)
            ]
        ]
    ]

loadingView : Model -> Html Msg
loadingView model =
  case model.banner of
    Just banner ->
      div [ class ("banner banner-" ++ banner.type') ]
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
