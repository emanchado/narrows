module Routing exposing (..)

import String
import Navigation
import UrlParser exposing (..)

type Route
  = ChapterReaderPage Int String
  | CharacterPage String
  | NarratorIndex
  | NarrationCreationPage
  | ChapterEditNarratorPage Int
  | ChapterControlPage Int
  | CreateChapterPage Int
  | NarrationPage Int
  | NotFoundRoute

matchers : Parser (Route -> a) a
matchers =
  oneOf
    [ format ChapterReaderPage (s "read" </> int </> string)
    , format CharacterPage (s "characters" </> string)
    , format NarratorIndex (s "")
    , format NarrationCreationPage (s "narrations" </> s "new")
    , format ChapterEditNarratorPage (s "chapters" </> int </> s "edit")
    , format ChapterControlPage (s "chapters" </> int)
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
