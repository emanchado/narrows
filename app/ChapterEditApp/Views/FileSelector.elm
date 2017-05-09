module ChapterEditApp.Views.FileSelector exposing (..)

import String
import Json.Decode
import Html exposing (Html, select, option, text)
import Html.Attributes exposing (selected, value)
import Html.Events exposing (on)
import ChapterEditApp.Messages exposing (Msg)


targetSelectedValue : Json.Decode.Decoder String
targetSelectedValue =
    Json.Decode.at [ "target", "value" ] Json.Decode.string


fileSelector : (String -> Msg) -> String -> List ( String, String ) -> Html Msg
fileSelector msg selectedOption options =
    let
        optionLabel =
            \label ->
                if String.length label > 25 then
                    String.concat
                        [ (String.left 12 label)
                        , "…"
                        , (String.right 12 label)
                        ]
                else
                    label

        optionRenderer =
            \( optId, optLabel ) ->
                option
                    [ value <| optId
                    , selected (optId == selectedOption)
                    ]
                    [ text <| optionLabel optLabel ]
    in
        select [ on "change" (Json.Decode.map msg targetSelectedValue) ]
            (option [ value "" ] [ text "Select…" ]
                :: (List.map optionRenderer options)
            )
