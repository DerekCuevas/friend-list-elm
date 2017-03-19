module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (type_, placeholder, autocomplete, class)
import Html.Events exposing (on, onInput, onClick, keyCode)
import Json.Decode exposing (Decoder, int, string, list)
import Json.Decode.Pipeline exposing (decode, required)
import RemoteData exposing (..)
import Http


-- MODEL


type alias Friend =
    { id : Int
    , name : String
    , username : String
    }


type alias Friends =
    { count : Int
    , query : String
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
    | Search
    | FriendsResponse (WebData Friends)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetQuery query ->
            ( Model query Loading, getFriends query )

        Search ->
            ( { model | friends = Loading }, getFriends model.query )

        FriendsResponse response ->
            ( { model | friends = response }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ (viewSearchInput model.query)
        , (viewFriends model.friends)
        ]


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Json.Decode.succeed msg
            else
                Json.Decode.fail "not ENTER"
    in
        on "keydown" (Json.Decode.andThen isEnter keyCode)


viewSearchInput : String -> Html Msg
viewSearchInput query =
    input
        [ type_ "search"
        , placeholder "Search friends..."
        , class "search-input"
        , onInput SetQuery
        , onEnter Search
        ]
        [ text query ]


errorMessage : Http.Error -> String
errorMessage error =
    case error of
        Http.BadStatus { body } ->
            body

        _ ->
            "Request failed."


viewFriends : WebData Friends -> Html Msg
viewFriends friends =
    case friends of
        NotAsked ->
            text "Initialising."

        Loading ->
            text "Loading."

        Failure error ->
            viewError (errorMessage error)

        Success friends ->
            viewFriendList friends


viewError : String -> Html Msg
viewError message =
    div [ class "error-view" ]
        [ h5 []
            [ i [ class "fa fa-exclamation-triangle" ] []
            , span [ class "error-message" ] [ text message ]
            , span [ class "details", onClick Search ]
                [ text " Press enter or click to try again." ]
            ]
        ]


viewNoResults : String -> Html Msg
viewNoResults query =
    text ("No results for '" ++ query ++ "' found.")


viewFriendList : Friends -> Html Msg
viewFriendList { count, query, results } =
    if count == 0 then
        viewNoResults query
    else
        ul [ class "friend-list" ] (List.map viewFriend results)


viewFriend : Friend -> Html Msg
viewFriend friend =
    li [ class "friend-list-item" ]
        [ div [ class "friend" ]
            [ text (friend.name ++ " ")
            , span [ class "username" ] [ text friend.username ]
            ]
        ]



-- HTTP


decodeFriends : Decoder Friends
decodeFriends =
    decode Friends
        |> required "count" int
        |> required "query" string
        |> required "results" (list decodeFriend)


decodeFriend : Decoder Friend
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
