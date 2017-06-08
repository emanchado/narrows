module Routing exposing (..)

import Navigation
import UrlParser exposing (..)

import Core.Routes exposing (Route(..))


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map ChapterReaderPage (s "read" </> int </> string)
        , map CharacterPage (s "characters" </> string)
        , map NarratorIndex (s "")
        , map NarrationArchivePage (s "narrations")
        , map NarrationCreationPage (s "narrations" </> s "new")
        , map ChapterEditNarratorPage (s "chapters" </> int </> s "edit")
        , map ChapterControlPage (s "chapters" </> int)
        , map CreateChapterPage (s "narrations" </> int </> s "new")
        , map CharacterCreationPage (s "narrations" </> int </> s "characters" </> s "new")
        , map NarrationPage (s "narrations" </> int)
        , map UserManagementPage (s "users")
        , map NovelReaderChapterPage (s "novels" </> string </> s "chapters" </> int)
        , map NovelReaderPage (s "novels" </> string)
        , map ProfilePage (s "profile")
        ]


parseLocation : Navigation.Location -> Route
parseLocation location =
  case (parsePath matchers location) of
    Just route ->
      route
    Nothing ->
      NotFoundRoute
