port module ReaderApp.Ports exposing (..)

import Common.Models exposing (DeviceSettings)

port receiveDeviceSettingsReader : (DeviceSettings -> msg) -> Sub msg
