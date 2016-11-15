module Routing exposing (..)

import String
import Navigation
import UrlParser exposing (..)

type Route
  = ChapterReaderPage Int String
  | ChapterNarratorPage Int
  | CreateChapterPage Int
  | NarrationPage Int
  | NotFoundRoute

matchers : Parser (Route -> a) a
matchers =
  oneOf
    [ format ChapterReaderPage (s "read" </> int </> string)
    , format ChapterNarratorPage (s "chapters" </> int)
    , format CreateChapterPage (s "narrations" </> int </> s "new")
    , format NarrationPage (s "narrations" </> int)
    ]

urlPathParser : Navigation.Location -> Result String Route
urlPathParser location =
  location.pathname
    |> String.dropLeft 1
    |> parse identity matchers

parser : Navigation.Parser (Result String Route)
parser =
  Navigation.makeParser urlPathParser

routeFromResult : Result String Route -> Route
routeFromResult result =
  case result of
    Ok route ->
      route

    Err string ->
      NotFoundRoute
