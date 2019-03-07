module Common.Views.Reading exposing (..)

import Html
import Html.Attributes exposing (style)

import Common.Models.Reading exposing (PageState(..))


backgroundImageStyle : Int -> Maybe String -> Int -> List (Html.Attribute msg)
backgroundImageStyle narrationId maybeBgImage backgroundBlurriness =
  let
    imageUrl =
      case maybeBgImage of
        Just backgroundImage ->
          "/static/narrations/" ++
            String.fromInt narrationId ++
            "/background-images/" ++
            backgroundImage

        Nothing ->
          "#"
    filter = "blur(" ++ (String.fromInt backgroundBlurriness) ++ "px)"
  in
    [ style "background-image" <| "url(" ++ imageUrl ++ ")"
    , style "-webkit-filter" filter
    , style "-moz-filter" filter
    , style "filter" filter
    ]


chapterContainerClass : PageState -> String
chapterContainerClass state =
  case state of
    Loader -> "invisible transparent"
    StartingNarration -> "transparent"
    Narrating -> "fade-in"
