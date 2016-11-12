module NarrationOverviewApp.Views exposing (..)

import List
import Html exposing (Html, main', h1, div, ul, li, a, text)
import Html.Attributes exposing (id, class, href)

import NarrationOverviewApp.Messages exposing (..)
import Common.Models exposing (Narration)
import NarrationOverviewApp.Models exposing (Model, NarrationOverview, ChapterOverview)

chapterOverviewView : ChapterOverview -> Html Msg
chapterOverviewView chapterOverview =
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

overviewView : Narration -> NarrationOverview -> Html Msg
overviewView narration overview =
  main' [ id "narrator-app" ]
    [ h1 []
        [ text <| "Narration " ++ narration.title ]
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
      case model.narration of
        Just narration ->
          overviewView narration overview
        Nothing ->
          loadingView model
    Nothing ->
      loadingView model
