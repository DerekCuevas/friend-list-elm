module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (type_, placeholder, autocomplete, class)
import Html.Events exposing (..)
import Json.Decode exposing (Decoder, int, string, list)
import Json.Decode.Pipeline exposing (decode, required)


-- MODEL


mockFriends : List Friend
mockFriends =
    [ (Friend 0 "john" "@jj")
    , (Friend 1 "santa" "@s")
    , (Friend 2 "steve" "@apple")
    ]


type alias Response =
    { count : Int
    , results : List Friend
    }


type alias Friend =
    { id : Int
    , name : String
    , username : String
    }


type alias Model =
    { query : String
    , friends : List Friend
    }


init : ( Model, Cmd Msg )
init =
    ( Model "" mockFriends, Cmd.none )



-- UPDATE


type Msg
    = SetQuery String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetQuery newQuery ->
            ( { model | query = newQuery }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ (viewSearchInput model.query)
        , (viewResults model.friends)
        ]


viewSearchInput : String -> Html Msg
viewSearchInput query =
    input
        [ type_ "search"
        , placeholder "Search friends..."
        , autocomplete False
        , class "search-input"
        , onInput SetQuery
        ]
        [ text query ]



--TODO: switch on web data type - render error/loading/results


viewResults : List Friend -> Html Msg
viewResults friends =
    viewFriendList friends


viewFriendList : List Friend -> Html Msg
viewFriendList friends =
    ul [ class "friend-list" ] (List.map viewFriend friends)


viewFriend : Friend -> Html Msg
viewFriend friend =
    li [ class "friend-list-item" ]
        [ div [ class "friend" ]
            [ text (friend.name ++ " ")
            , span [ class "username" ] [ text friend.username ]
            ]
        ]



-- HTTP


decodeResponse : Json.Decode.Decoder Response
decodeResponse =
    decode Response
        |> required "count" int
        |> required "results" (list decodeFriend)


decodeFriend : Json.Decode.Decoder Friend
decodeFriend =
    decode Friend
        |> required "id" int
        |> required "name" string
        |> required "username" string



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
