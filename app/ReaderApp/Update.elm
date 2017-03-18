module ReaderApp.Update exposing (..)

import String
import Http
import Json.Decode

import Routing
import Common.Ports exposing (renderText)
import Common.Models exposing (Character)
import Common.Api.Json exposing (parseChapterMessages)

import ReaderApp.Api
import ReaderApp.Messages exposing (..)
import ReaderApp.Models exposing (..)
import ReaderApp.Ports exposing (startNarration, playPauseNarrationMusic, flashElement)

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
    Routing.ChapterReaderPage chapterId characterToken ->
      ( model
      , ReaderApp.Api.fetchChapterInfo chapterId characterToken
      )
    _ ->
      (model, Cmd.none)

descriptionRenderCommand : ParticipantCharacter -> Cmd Msg
descriptionRenderCommand character =
  renderText { elemId = "description-character-" ++ (toString character.id)
             , text = character.description
             , proseMirrorType = "description"
             }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ChapterFetchError error ->
      let
        errorString = case error of
                        Http.UnexpectedPayload payload ->
                          "Bad payload: " ++ payload
                        Http.BadResponse status body ->
                          "Got status " ++ (toString status) ++ " with body " ++ body
                        _ ->
                          "Network stuff"
      in
        ({ model | banner = (Just { text = "Error fetching chapter: " ++ errorString
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
        , ReaderApp.Api.fetchChapterMessages chapterData.id chapterData.character.token
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
              let
                allParticipantIds =
                  List.map (\p -> p.id) chapter.participants
              in
                List.filter (\p -> p /= chapter.character.id) allParticipantIds
            Nothing ->
              []
      in
        ({ model | messageThreads = Just chapterMessageData.messages
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
                      Cmd.batch <|
                        List.append
                          [ renderText { elemId = "chapter-text"
                                       , text = chapterData.text
                                       , proseMirrorType = "chapter"
                                       }
                          , startNarration { audioElemId = audioElemId }
                          ]
                          (List.map
                             descriptionRenderCommand
                               chapterData.participants)
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

    UpdateNotesText newText ->
      case model.chapter of
        Just chapter ->
          let
            ownCharacter = chapter.character
            updatedOwnCharacter = { ownCharacter | notes = Just newText }
            updatedChapter = { chapter | character = updatedOwnCharacter }
          in
            ({ model | chapter = Just updatedChapter }, Cmd.none)
        Nothing ->
          (model, Cmd.none)
    SendNotes ->
      case model.chapter of
        Just chapter ->
          case chapter.character.notes of
            Just notes ->
              ( model
              , ReaderApp.Api.sendNotes chapter.character.token notes
              )
            Nothing ->
              (model, Cmd.none)
        Nothing ->
          (model, Cmd.none)
    SendNotesError error ->
      ({ model | banner = Just { text = "Error sending notes"
                               , type' = "error"
                               } }
      , Cmd.none)
    SendNotesSuccess resp ->
      let
        newBanner = if (resp.status >= 200) && (resp.status < 300) then
                      Nothing
                    else
                      Just { text = "Error sending notes"
                           , type' = "error"
                           }
      in
        ({ model | banner = newBanner }, flashElement "save-notes-message")

    ShowReply participants ->
      let
        newReply = case model.reply of
                     Just reply ->
                       { reply | recipients = participants }
                     Nothing ->
                       { recipients = participants
                       , body = ""
                       }
      in
        ({ model | reply = Just newReply }, Cmd.none)
    UpdateReplyText newText ->
      let
        newReply = case model.reply of
                     Just reply ->
                       { reply | body = newText }
                     Nothing ->
                       { recipients = []
                       , body = newText
                       }
      in
        ({ model | reply = Just newReply }, Cmd.none)

    SendReply ->
      case model.reply of
        Just reply ->
          if String.isEmpty <| String.trim reply.body then
            (model, Cmd.none)
          else
            case model.chapter of
              Just chapter ->
                ( model
                , ReaderApp.Api.sendReply
                    chapter.id
                    chapter.character.token
                    reply.body
                    (messageRecipients reply.recipients chapter.character.id)
                )
              Nothing ->
                (model, Cmd.none)
        Nothing ->
          (model, Cmd.none)
    SendReplyError error ->
      ({ model | banner = Just { text = "Error sending reply"
                               , type' = "error"
                               } }
      , Cmd.none)
    SendReplySuccess resp ->
      case resp.value of
        Http.Text text ->
          let
            decodedResponse =
              Json.Decode.decodeString parseChapterMessages text
          in
            case decodedResponse of
              Ok result ->
                ( { model | messageThreads = Just result.messages
                          , reply = Nothing }
                , Cmd.none
                )
              _ ->
                ({ model | banner = Just { text = "Error parsing response while sending message"
                                   , type' = "error"
                                   } }
                , Cmd.none
                )
        _ ->
          ({ model | banner = Just { text = "Error sending message"
                                   , type' = "error"
                                   } }
          , Cmd.none
          )
    CloseReply ->
      ({ model | reply = Nothing }, Cmd.none)

    ShowNewMessageUi ->
      ({ model | showNewMessageUi = True }, Cmd.none)
    HideNewMessageUi ->
      ({ model | showNewMessageUi = False }, Cmd.none)
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
          if String.isEmpty <| String.trim model.newMessageText then
            (model, Cmd.none)
          else
            ( model
            , ReaderApp.Api.sendMessage chapter.id chapter.character.token model.newMessageText model.newMessageRecipients
            )
        Nothing ->
          (model, Cmd.none)
    SendMessageError error ->
      ({ model | banner = Just { text = "Error sending message"
                               , type' = "error"
                               } }
      , Cmd.none)
    SendMessageSuccess resp ->
      case resp.value of
        Http.Text text ->
          let
            decodedResponse =
              Json.Decode.decodeString parseChapterMessages text
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
          (model, ReaderApp.Api.sendReaction chapter.id chapter.character.token model.reaction)
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
        newBanner = if (resp.status >= 200) && (resp.status < 300) then
                      Just { text = "Action registered", type' = "success" }
                    else
                      Just { text = "Error registering action"
                           , type' = "error"
                           }
      in
        ({ model | reactionSent = True, banner = newBanner }, Cmd.none)
    ShowReferenceInformation ->
      ({ model | referenceInformationVisible = True }, Cmd.none)
    HideReferenceInformation ->
      ({ model | referenceInformationVisible = False }, Cmd.none)
