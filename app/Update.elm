module Update exposing (..)

import Http
import Json.Decode

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
        , Api.fetchChapterInfo chapterId characterToken
        )
      _ ->
        (updatedModel, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ChapterFetchError error ->
      ({ model | banner = (Just { text = "Error fetching chapter"
                                , type' = "error"
                                }) }
      , Cmd.none)
    ChapterFetchSuccess chapterData ->
      let
        reactionText = case chapterData.reaction of
                         Just reaction ->
                           reaction
                         Nothing ->
                           ""
      in
        ({ model | chapter = Just chapterData, reaction = reactionText }
        , Api.fetchChapterMessages chapterData.id model.characterToken
        )
    ChapterMessagesFetchError error ->
      ({ model | banner = (Just { text = "Error fetching chapter messages"
                                , type' = "error"
                                }) }
      , Cmd.none)
    ChapterMessagesFetchSuccess chapterMessageData ->
      let
        allRecipients =
          case model.chapter of
            Just chapter ->
              case chapterMessageData.characterId of
                Just characterId ->
                  let
                    allParticipantIds =
                      List.map (\p -> p.id) chapter.participants
                  in
                    List.filter (\p -> p /= characterId) allParticipantIds
                Nothing ->
                  []
            Nothing ->
              []
      in
        ({ model | messageThreads = Just chapterMessageData.messages
                 , characterId = chapterMessageData.characterId
                 , newMessageRecipients = allRecipients
                 }
        , Cmd.none
        )

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

    UpdateNewMessageText newText ->
      ({ model | newMessageText = newText }, Cmd.none)
    UpdateNewMessageRecipient characterId on ->
      let
        newRecipientsWithoutCharacter =
          List.filter
            (\r -> r /= characterId)
            model.newMessageRecipients
        newRecipients =
          if on then
            characterId :: newRecipientsWithoutCharacter
          else
            newRecipientsWithoutCharacter
      in
        ({ model | newMessageRecipients = newRecipients }, Cmd.none)
    SendMessage ->
      case model.chapter of
        Just chapter ->
          ( model
          , Api.sendMessage chapter.id model.characterToken model.newMessageText model.newMessageRecipients
          )
        Nothing ->
          (model, Cmd.none)
    SendMessageError error ->
      ({ model | banner = Just { text = "Error sending reaction"
                               , type' = "error"
                               } }
      , Cmd.none)
    SendMessageSuccess resp ->
      case resp.value of
        Http.Text text ->
          let
            decodedResponse =
              Json.Decode.decodeString Api.parseChapterMessages text
          in
            case decodedResponse of
              Ok result ->
                ( { model | messageThreads = Just result.messages
                          , newMessageText = "" }
                , Cmd.none)
              _ ->
                ({ model | banner = Just { text = "Error parsing response while sending message"
                                   , type' = "error"
                                   } }
                , Cmd.none)
        _ ->
          ({ model | banner = Just { text = "Error sending message"
                                   , type' = "error"
                                   } }
          , Cmd.none)

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
