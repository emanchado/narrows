port module NovelReaderApp.Ports exposing (..)

import Common.Models exposing (DeviceSettings)

port scrollTo : Int -> Cmd msg

port receiveDeviceSettingsNovelReader : (DeviceSettings -> msg) -> Sub msg
