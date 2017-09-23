module Common.Views.Reading exposing (..)

import Http exposing (encodeUri)

import Common.Models.Reading exposing (PageState(Loader, StartingNarration, Narrating))


backgroundImageStyle : Int -> Maybe String -> Int -> List ( String, String )
backgroundImageStyle narrationId maybeBgImage backgroundBlurriness =
  let
    imageUrl =
      case maybeBgImage of
        Just backgroundImage ->
          "/static/narrations/" ++
            (toString narrationId) ++
            "/background-images/" ++
            (encodeUri <| backgroundImage)

        Nothing ->
          "#"
    filter = "blur(" ++ (toString backgroundBlurriness) ++ "px)"
  in
    [ ( "background-image", "url(" ++ imageUrl ++ ")" )
    , ( "-webkit-filter", filter )
    , ( "-moz-filter", filter )
    , ( "filter", filter )
    ]


chapterContainerClass : PageState -> String
chapterContainerClass state =
  case state of
    Loader -> "invisible transparent"
    StartingNarration -> "transparent"
    Narrating -> "fade-in"
