module Update exposing (..)

import Process
import Task
import Time

import Routing
import Api
import Messages exposing (..)
import Models exposing (..)
import Ports exposing (renderChapter)


maxBlurriness : Int
maxBlurriness = 10

urlUpdate : Result String Routing.Route -> Model -> (Model, Cmd Msg)
urlUpdate result model =
  let
    currentRoute =
      Routing.routeFromResult result
    updatedModel = { model | route = currentRoute }
  in
    case currentRoute of
      Routing.ChapterPage chapterId characterToken ->
        ( { updatedModel | characterToken = characterToken }
        , Api.fetchChapterInfo chapterId characterToken )
      _ ->
        (updatedModel, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    StartNarration ->
      let
        command = case model.chapter of
                    Just chapterData ->
                      Cmd.batch
                        [ renderChapter { elemId = "chapter-text"
                                        , text = chapterData.text
                                        }
                        , Process.sleep (100 * Time.millisecond)
                          |> Task.perform (\_ -> PlayPauseMusic) (\_ -> MarkNarrationStarted)
                        ]
                    Nothing ->
                      Cmd.none
      in
        ({ model | state = StartingNarration }, command)
    MarkNarrationStarted ->
      ({ model | state = Narrating }, Cmd.none)
    ChapterFetchError error ->
      ({ model | errorMessage = (Just "Error fetching chapter") }, Cmd.none)
    ChapterFetchSuccess chapterData ->
      let
        reactionText = case chapterData.reaction of
                         Just reaction ->
                           reaction
                         Nothing ->
                           ""
      in
        ({ model | chapter = Just chapterData, reaction = reactionText }
        , Cmd.none)
    ToggleBackgroundMusic ->
      ({ model | backgroundMusic = not model.backgroundMusic }, Cmd.none)
    PlayPauseMusic ->
      ({ model | musicPlaying = not model.musicPlaying }, Cmd.none)
    PageScroll scrollAmount ->
      let
        blurriness = Debug.log "Blurriness:" (min
                                                (round ((toFloat scrollAmount) / 40))
                                                maxBlurriness)
      in
        ({ model | backgroundBlurriness = blurriness }, Cmd.none)
    UpdateReactionText newText ->
      ({ model | reaction = newText }, Cmd.none)
    SendReaction ->
      case model.chapter of
        Just chapter ->
          (model, Api.sendReaction chapter.id model.characterToken model.reaction)
        Nothing ->
          ({ model | errorMessage = (Just "No chapter to send reaction to") }, Cmd.none)
    SendReactionError error ->
      ({ model | errorMessage = (Just "Error sending reaction") }, Cmd.none)
    SendReactionSuccess resp ->
      ({ model | reactionSent = True }, Cmd.none)
