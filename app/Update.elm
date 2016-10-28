module Update exposing (..)

import Routing
import Api
import Messages exposing (..)
import Models exposing (..)
import Ports exposing (renderChapter, startNarration, playPauseNarrationMusic)


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
        audioElemId = if model.backgroundMusic then
                        "background-music"
                      else
                        ""
        command = case model.chapter of
                    Just chapterData ->
                      Cmd.batch
                        [ renderChapter { elemId = "chapter-text"
                                        , text = chapterData.text
                                        }
                        , startNarration { audioElemId = audioElemId }
                        ]
                    Nothing ->
                      Cmd.none
      in
        ({ model | state = StartingNarration }, command)
    NarrationStarted _ ->
      ({ model | state = Narrating }, Cmd.none)
    ChapterFetchError error ->
      ({ model | banner = (Just { text = "Error fetching chapter"
                                , type' = "error"
                                }) }, Cmd.none)
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
      let
        musicOn = not model.backgroundMusic
      in
        ({ model | backgroundMusic = musicOn, musicPlaying = musicOn }
        , Cmd.none)
    PlayPauseMusic ->
      ({ model | musicPlaying = not model.musicPlaying }
      , playPauseNarrationMusic { audioElemId = "background-music" })
    PageScroll scrollAmount ->
      let
        blurriness =
          min maxBlurriness (round ((toFloat scrollAmount) / 40))
      in
        ({ model | backgroundBlurriness = blurriness }, Cmd.none)
    UpdateReactionText newText ->
      ({ model | reaction = newText }, Cmd.none)
    SendReaction ->
      case model.chapter of
        Just chapter ->
          (model, Api.sendReaction chapter.id model.characterToken model.reaction)
        Nothing ->
          ({ model | banner = (Just { text = "No chapter to send reaction to"
                                    , type' = "error"
                                    }) }
          , Cmd.none)
    SendReactionError error ->
      ({ model | banner = Just { text = "Error sending reaction"
                               , type' = "error"
                               } }
      , Cmd.none)
    SendReactionSuccess resp ->
      let
        updatedModel = { model | reactionSent = True }
        newBanner = if (resp.status >= 200) && (resp.status < 300) then
                      Just { text = "Action registered", type' = "success" }
                    else
                      Just { text = "Error registering action"
                           , type' = "error"
                           }
      in
        ({ model | reactionSent = True, banner = newBanner }, Cmd.none)
