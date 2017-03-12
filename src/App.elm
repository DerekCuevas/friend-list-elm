module App exposing (..)

import Html exposing (..)


type alias Model =
    { message : String
    }


init : ( Model, Cmd Msg )
init =
    ( Model "Hello world!", Cmd.none )


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    text model.message


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
