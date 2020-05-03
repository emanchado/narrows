module Common.Views.FileSelector exposing (..)

import String
import Json.Decode
import Html exposing (Html, div, input, button, select, option, text)
import Html.Attributes exposing (id, class, type_, selected, name, value, disabled)
import Html.Events exposing (on, onClick)

import Common.Views exposing (onPreventDefaultClick)


targetSelectedValue : Json.Decode.Decoder String
targetSelectedValue =
  Json.Decode.at [ "target", "value" ] Json.Decode.string


fileSelector : (String -> msg) -> (String -> msg) -> (String -> msg) -> String -> Bool -> String -> List (String, String) -> Html msg
fileSelector updateMsg openFileSelectorMsg uploadMsg newFileInputId isUploading selectedOption options =
  let
    optionLabel =
      \label ->
        if String.length label > 25 then
          String.concat [ (String.left 12 label)
                        , "…"
                        , (String.right 12 label)
                        ]
        else
          label

    optionRenderer =
      \( optId, optLabel ) ->
        option [ value <| optId
               , selected (optId == selectedOption)
               ]
          [ text <| optionLabel optLabel ]
  in
    div []
      [ select [ on "change" (Json.Decode.map updateMsg targetSelectedValue)
               , disabled isUploading
               ]
          (option [ value "" ] [ text "Select…" ]
             :: (List.map optionRenderer options))
      , button [ class "btn btn-small btn-add"
               , type_ "button"
               , onPreventDefaultClick (openFileSelectorMsg newFileInputId)
               , disabled isUploading
               ]
          [ text "Upload" ]
      , input [ type_ "file"
              , id newFileInputId
              , class "invisible"
              , name "file"
              , on "change" (Json.Decode.succeed <| uploadMsg newFileInputId)
              ]
          []
      ]
