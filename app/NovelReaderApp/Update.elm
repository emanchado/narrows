module NovelReaderApp.Update exposing (..)

import Http
import Navigation
import Task
import Core.Routes exposing (Route(..))
import Common.Ports exposing (renderText, startNarration, pauseNarrationMusic, playPauseNarrationMusic, flashElement)
import Common.Models exposing (Character, errorBanner)
import NovelReaderApp.Api
import NovelReaderApp.Messages exposing (..)
import NovelReaderApp.Models exposing (..)
import NovelReaderApp.Ports exposing (scrollTo)


messageRecipients : List Character -> Int -> List Int
messageRecipients recipients senderId =
  List.filter
    (\r -> r /= senderId)
    (List.map (\r -> r.id) recipients)


maxBlurriness : Int
maxBlurriness = 10


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
  case route of
    NovelReaderPage novelToken ->
      ( model
      , NovelReaderApp.Api.fetchNovelInfo novelToken
      )

    NovelReaderChapterPage novelToken chapterIndex ->
      ( { model | currentChapterIndex = chapterIndex }
      , case model.novel of
          Just novel ->
            case model.state of
              Narrating -> Cmd.batch [ startNarrationCmd
                                     , scrollTo 0
                                     ]
              _ -> Cmd.none

          Nothing ->
            NovelReaderApp.Api.fetchNovelInfo novelToken
      )

    _ ->
      ( model, Cmd.none )


descriptionRenderCommand : ParticipantCharacter -> Cmd Msg
descriptionRenderCommand character =
  renderText { elemId = "description-character-" ++ (toString character.id)
             , text = character.description
             , proseMirrorType = "description"
             }


startNarrationCmd : Cmd Msg
startNarrationCmd =
  Task.perform (\_ -> StartNarration) (Task.succeed 1)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NavigateTo url ->
      ( model, Navigation.newUrl url )

    NovelFetchResult (Err error) ->
      let
        errorString =
          case error of
            Http.BadPayload parserError _ ->
              "Bad payload: " ++ parserError
            Http.BadStatus resp ->
              "Got status " ++ (toString resp.status) ++ " with body " ++ resp.body
            _ ->
              "Cannot connect to server"
        newBanner = errorBanner <| "Error fetching chapter: " ++ errorString
      in
        ( { model | banner = newBanner }
        , Cmd.none
        )

    NovelFetchResult (Ok novelData) ->
      let
        lastChapterIndex = (List.length novelData.chapters) - 1
        newChapterIndex = min lastChapterIndex model.currentChapterIndex
      in
        ( { model | novel = Just novelData
                  , currentChapterIndex = max 0 newChapterIndex
          }
        , Cmd.none
        )

    StartNarration ->
      let
        audioElemId =
          if model.musicPlaying then
            "background-music-chapter-" ++ (toString model.currentChapterIndex)
          else
            ""
      in
        case model.novel of
          Just novel ->
            let
              maybeChapter = findChapter novel model.currentChapterIndex
            in
              ( { model | state = StartingNarration }
              , case maybeChapter of
                  Just chapter ->
                    Cmd.batch <|
                      List.append
                        [ renderText { elemId = "chapter-text"
                                     , text = chapter.text
                                     , proseMirrorType = "chapter"
                                     }
                        , startNarration { audioElemId = audioElemId }
                        ]
                        (List.map
                          descriptionRenderCommand
                          novel.narration.characters)

                  Nothing ->
                    Cmd.none
              )

          Nothing ->
            ( model, Cmd.none )

    NarrationStarted _ ->
      ( { model | state = Narrating }, Cmd.none )

    ToggleBackgroundMusic ->
      let
        musicOn =
          not model.backgroundMusic
      in
        ( { model | backgroundMusic = musicOn, musicPlaying = musicOn }
        , Cmd.none
        )

    PlayPauseMusic ->
      let
        audioElemId = "background-music-chapter-" ++
                        (toString model.currentChapterIndex)
      in
        ( { model | musicPlaying = not model.musicPlaying }
        , playPauseNarrationMusic { audioElemId = audioElemId }
        )

    PageScroll scrollAmount ->
      let
        blurriness =
          min maxBlurriness (round ((toFloat scrollAmount) / 40))
      in
        ( { model | backgroundBlurriness = blurriness }, Cmd.none )

    PreviousChapter ->
      let
        newChapterIndex = max 0 (model.currentChapterIndex - 1)
        audioElemId = "background-music-chapter-" ++
                        (toString model.currentChapterIndex)
      in
        case model.novel of
          Just novel ->
            ( model
            , Cmd.batch [ Navigation.newUrl <| "/novels/" ++ novel.token ++ "/chapters/" ++ (toString newChapterIndex)
                        , pauseNarrationMusic { audioElemId = audioElemId }
                        ]
            )

          Nothing ->
            ( model, Cmd.none )

    NextChapter ->
      let
        lastChapter = case model.novel of
                        Just novel -> (List.length novel.chapters) - 1
                        Nothing -> 0
        newChapterIndex = min lastChapter (model.currentChapterIndex + 1)
        audioElemId = "background-music-chapter-" ++
                        (toString model.currentChapterIndex)
      in
        case model.novel of
          Just novel ->
            ( model
            , Cmd.batch [ Navigation.newUrl <| "/novels/" ++ novel.token ++ "/chapters/" ++ (toString newChapterIndex)
                        , pauseNarrationMusic { audioElemId = audioElemId }
                        ]
            )

          Nothing ->
            ( model, Cmd.none )

    ShowReferenceInformation ->
      ( { model | referenceInformationVisible = True }, Cmd.none )

    HideReferenceInformation ->
      ( { model | referenceInformationVisible = False }, Cmd.none )
