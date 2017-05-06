module NovelReaderApp.Update exposing (..)

import Http
import Navigation
import Task

import Routing
import Common.Ports exposing (renderText, startNarration, playPauseNarrationMusic, flashElement)
import Common.Models exposing (Character)

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

urlUpdate : Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate route model =
  case route of
    Routing.NovelReaderPage novelToken ->
      ( model
      , NovelReaderApp.Api.fetchNovelInfo novelToken
      )
    _ ->
      (model, Cmd.none)

descriptionRenderCommand : ParticipantCharacter -> Cmd Msg
descriptionRenderCommand character =
  renderText { elemId = "description-character-" ++ (toString character.id)
             , text = character.description
             , proseMirrorType = "description"
             }

startNarrationCmd : Cmd Msg
startNarrationCmd =
  Task.perform (\_ -> StartNarration) (\_ -> StartNarration) (Task.succeed 1)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NavigateTo url ->
      (model, Navigation.newUrl url)

    NovelFetchError error ->
      let
        errorString = case error of
                        Http.UnexpectedPayload payload ->
                          "Bad payload: " ++ payload
                        Http.BadResponse status body ->
                          "Got status " ++ (toString status) ++ " with body " ++ body
                        _ ->
                          "Cannot connect to server"
      in
        ({ model | banner = (Just { text = "Error fetching chapter: " ++ errorString
                                  , type' = "error"
                                  }) }
        , Cmd.none)
    NovelFetchSuccess novelData ->
      ({ model | novel = Just novelData }
      , Cmd.none
      )

    StartNarration ->
      let
        audioElemId = if model.musicPlaying then
                        "background-music"
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
            (model, Cmd.none)
    NarrationStarted _ ->
      ({ model | state = Narrating }, Cmd.none)
    ToggleBackgroundMusic ->
      let
        musicOn = not model.backgroundMusic
      in
        ( { model | backgroundMusic = musicOn, musicPlaying = musicOn }
        , Cmd.none
        )
    PlayPauseMusic ->
      ( { model | musicPlaying = not model.musicPlaying }
      , playPauseNarrationMusic { audioElemId = "background-music" }
      )

    PageScroll scrollAmount ->
      let
        blurriness =
          min maxBlurriness (round ((toFloat scrollAmount) / 40))
      in
        ({ model | backgroundBlurriness = blurriness }, Cmd.none)

    PreviousChapter ->
      if model.currentChapterIndex > 0 then
        ( { model | currentChapterIndex = model.currentChapterIndex - 1 }
        , Cmd.batch [ startNarrationCmd
                    , scrollTo 0
                    ]
        )
      else
        (model, Cmd.none)
    NextChapter ->
      let
        lastChapter = case model.novel of
                        Just novel -> (List.length novel.chapters) - 1
                        Nothing -> 0
        newChapterIndex = min lastChapter (model.currentChapterIndex + 1)
      in
        if newChapterIndex /= model.currentChapterIndex then
          ( { model | currentChapterIndex = newChapterIndex }
          , Cmd.batch [ startNarrationCmd
                      , scrollTo 0
                      ]
          )
        else
          (model, Cmd.none)

    ShowReferenceInformation ->
      ({ model | referenceInformationVisible = True }, Cmd.none)
    HideReferenceInformation ->
      ({ model | referenceInformationVisible = False }, Cmd.none)
