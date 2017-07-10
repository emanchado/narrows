module Core.Routes exposing (..)


type Route
    = ChapterReaderPage Int String
    | CharacterPage String
    | NarratorIndex
    | NarrationArchivePage
    | NarrationCreationPage
    | NarrationEditPage Int
    | ChapterEditNarratorPage Int
    | ChapterControlPage Int
    | CreateChapterPage Int
    | NarrationPage Int
    | CharacterCreationPage Int
    | UserManagementPage
    | NovelReaderPage String
    | NovelReaderChapterPage String Int
    | ProfilePage
    | PasswordResetFailure String
    | NotFoundRoute
