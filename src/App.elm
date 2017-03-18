module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (type_, placeholder, autocomplete, class)
import Html.Events exposing (..)
import Json.Decode exposing (Decoder, int, string, list)
import Json.Decode.Pipeline exposing (decode, required)
import Http
import RemoteData exposing (..)


-- MODEL


type alias Friend =
    { id : Int
    , name : String
    , username : String
    }


type alias Friends =
    { count : Int
    , results : List Friend
    }


type alias Model =
    { query : String
    , friends : WebData Friends
    }


init : ( Model, Cmd Msg )
init =
    ( Model "" Loading, getFriends "" )



-- UPDATE


type Msg
    = SetQuery String
    | FriendsResponse (WebData Friends)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetQuery query ->
            ( Model query Loading, getFriends query )

        FriendsResponse response ->
            ( { model | friends = response }, Cmd.none )



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


viewResults : WebData Friends -> Html Msg
viewResults friends =
    case friends of
        NotAsked ->
            text "Initialising."

        Loading ->
            text "Loading."

        Failure error ->
            text (toString error)

        Success friends ->
            viewFriendList friends.results


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


decodeFriends : Json.Decode.Decoder Friends
decodeFriends =
    decode Friends
        |> required "count" int
        |> required "results" (list decodeFriend)


decodeFriend : Json.Decode.Decoder Friend
decodeFriend =
    decode Friend
        |> required "id" int
        |> required "name" string
        |> required "username" string


friendsUrl : String -> String
friendsUrl query =
    "http://localhost:8000/api/friends?q=" ++ query


getFriends : String -> Cmd Msg
getFriends query =
    Http.get (friendsUrl query) decodeFriends
        |> RemoteData.sendRequest
        |> Cmd.map FriendsResponse



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
