module Routing exposing (..)

import Browser.Navigation
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, int, string)

import Core.Routes exposing (Route(..))


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Dashboard Parser.top
        , Parser.map ChapterReaderPage (s "read" </> int </> string)
        , Parser.map CharacterPage (s "characters" </> string)
        , Parser.map NarrationArchivePage (s "narrations")
        , Parser.map CharacterArchivePage (s "characters")
        , Parser.map NarrationCreationPage (s "narrations" </> s "new")
        , Parser.map NarrationEditPage (s "narrations" </> int </> s "edit")
        , Parser.map ChapterEditNarratorPage (s "chapters" </> int </> s "edit")
        , Parser.map ChapterControlPage (s "chapters" </> int)
        , Parser.map CreateChapterPage (s "narrations" </> int </> s "new")
        , Parser.map CharacterCreationPage (s "narrations" </> int </> s "characters" </> s "new")
        , Parser.map CharacterEditPage (s "characters" </> int </> s "edit")
        , Parser.map NarrationPage (s "narrations" </> int)
        , Parser.map UserManagementPage (s "users")
        , Parser.map NovelReaderChapterPage (s "novels" </> string </> s "chapters" </> int)
        , Parser.map NovelReaderPage (s "novels" </> string)
        , Parser.map ProfilePage (s "profile")
        , Parser.map PasswordResetFailure (s "password-reset" </> string)
        , Parser.map NarrationIntroPage (s "narrations" </> string </> s "intro")
        ]

fromUrl : Url -> Route
fromUrl url =
    let
      maybeRoute = Parser.parse parser url
    in
      case maybeRoute of
        Just route -> route
        Nothing -> NotFoundRoute
