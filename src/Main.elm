module Main exposing (..)

import App exposing (..)
import Navigation exposing (program)


main =
    program UrlChange
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
