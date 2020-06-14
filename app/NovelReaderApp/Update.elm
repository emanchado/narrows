module NovelReaderApp.Update exposing (..)

import Http
import Browser.Navigation as Nav
import Task

import Core.Routes exposing (Route(..))
import Common.Ports exposing (readDeviceSettings, setDeviceSetting, renderText, startNarration, pauseNarrationMusic, playPauseNarrationMusic, flashElement)
import Common.Models exposing (Character, errorBanner, ParticipantCharacter)
import Common.Models.Reading exposing (PageState(..))
import NovelReaderApp.Api
import NovelReaderApp.Messages exposing (..)
import NovelReaderApp.Models exposing (..)
import NovelReaderApp.Ports exposing (scrollTo)


maxBlurriness : Int
maxBlurriness = 10


defaultChapterIndex : Int
defaultChapterIndex = -999


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
  case route of
    NovelReaderPage novelToken ->
      ( { model | currentChapterIndex = defaultChapterIndex }
      , Cmd.batch
          [ NovelReaderApp.Api.fetchNovelInfo novelToken
          , readDeviceSettings "receiveDeviceSettingsNovelReader"
          ]
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
            Cmd.batch
              [ NovelReaderApp.Api.fetchNovelInfo novelToken
              , readDeviceSettings "receiveDeviceSettingsNovelReader"
              ]
      )

    _ ->
      ( model, Cmd.none )


descriptionRenderCommand : ParticipantCharacter -> Cmd Msg
descriptionRenderCommand character =
  renderText { elemId = "description-character-" ++ (String.fromInt character.id)
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
      ( model, Nav.pushUrl model.key url )

    ReceiveDeviceSettings newSettings ->
      ( { model | backgroundMusic = newSettings.backgroundMusic
                , musicPlaying = newSettings.backgroundMusic
        }
      , Cmd.none
      )

    NovelFetchResult (Err error) ->
      let
        errorString =
          case error of
            Http.BadBody parserError ->
              "Bad payload: " ++ parserError
            Http.BadStatus status ->
              "Got status " ++ (String.fromInt status)
            _ ->
              "Cannot connect to server"
        newBanner = errorBanner <| "Error fetching chapter: " ++ errorString
      in
        ( { model | banner = newBanner }
        , Cmd.none
        )

    NovelFetchResult (Ok novelData) ->
      let
        chapterIndex = if model.currentChapterIndex == defaultChapterIndex then
                         firstChapterIndex novelData
                       else
                         model.currentChapterIndex
        lastChapterIndex = (List.length novelData.chapters) - 1
        firstChapterIndex_ = firstChapterIndex novelData
        newChapterIndex = min lastChapterIndex chapterIndex
      in
        ( { model | novel = Just novelData
                  , currentChapterIndex = max firstChapterIndex_ newChapterIndex
          }
        , Cmd.none
        )

    StartNarration ->
      let
        audioElemId =
          if model.musicPlaying then
            "background-music-chapter-" ++ (String.fromInt model.currentChapterIndex)
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
                        , startNarration { audioElemId = audioElemId
                                         , narrationId = novel.narration.id
                                         }
                        , setDeviceSetting { name = "backgroundMusic"
                                           , value = if model.backgroundMusic then
                                                       "1"
                                                     else
                                                       ""
                                            }
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
                        (String.fromInt model.currentChapterIndex)
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
      case model.novel of
        Just novel ->
          let
            newChapterIndex = max
                                (firstChapterIndex novel)
                                (model.currentChapterIndex - 1)
            audioElemId = "background-music-chapter-" ++
                            (String.fromInt model.currentChapterIndex)
          in
            ( model
            , Cmd.batch [ Nav.pushUrl model.key <| novelChapterUrl novel newChapterIndex
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
                        (String.fromInt model.currentChapterIndex)
      in
        case model.novel of
          Just novel ->
            ( model
            , Cmd.batch [ Nav.pushUrl model.key <| "/novels/" ++ novel.token ++ "/chapters/" ++ (String.fromInt newChapterIndex)
                        , pauseNarrationMusic { audioElemId = audioElemId }
                        ]
            )

          Nothing ->
            ( model, Cmd.none )

    ShowReferenceInformation ->
      ( { model | referenceInformationVisible = True }, Cmd.none )

    HideReferenceInformation ->
      ( { model | referenceInformationVisible = False }, Cmd.none )
