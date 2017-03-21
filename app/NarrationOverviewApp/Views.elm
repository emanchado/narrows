module NarrationOverviewApp.Views exposing (..)

import List
import Html exposing (Html, main', h1, div, ul, li, a, text)
import Html.Attributes exposing (id, class, href)

import NarrationOverviewApp.Messages exposing (..)
import Common.Models exposing (Narration, ChapterOverview, NarrationOverview)
import NarrationOverviewApp.Models exposing (Model)

unpublishedChapterView : ChapterOverview -> Html Msg
unpublishedChapterView chapterOverview =
  li []
    [ a [ href <| "/chapters/" ++ (toString chapterOverview.id) ++ "/edit" ]
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
      [ a [ href <| "/chapters/" ++ (toString chapterOverview.id) ]
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

overviewView : NarrationOverview -> Html Msg
overviewView overview =
  main' [ id "narrator-app", class "app-container" ]
    [ h1 []
        [ text <| "Narration " ++ overview.narration.title ]
    , a [ href <| "/narrations/" ++ (toString overview.narration.id) ++ "/new" ]
        [ text "Write new chapter" ]
    , ul [ class "chapter-list" ]
      (List.map chapterOverviewView overview.chapters)
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
      overviewView overview
    Nothing ->
      loadingView model
