module Core.Routes exposing (..)


type Route
    = ChapterReaderPage Int String
    | CharacterPage String
    | Dashboard
    | NarrationArchivePage
    | CharacterArchivePage
    | NarrationCreationPage
    | NarrationEditPage Int
    | NarrationIntroPage String
    | ChapterEditNarratorPage Int
    | ChapterControlPage Int
    | CreateChapterPage Int
    | NarrationPage Int
    | CharacterCreationPage Int
    | CharacterEditPage Int
    | UserManagementPage
    | NovelReaderPage String
    | NovelReaderChapterPage String Int
    | ProfilePage
    | PasswordResetFailure String
    | NotFoundRoute
