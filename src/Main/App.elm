module Main.App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Time exposing (Time)
import Http
import Json.Decode as Json exposing (Decoder)
import Json.Decode.Pipeline as Pipeline
import Navigation exposing (..)
import UrlParser as Url exposing ((<?>))
import RemoteData exposing (RemoteData(..), WebData)
import Debounce


main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { view = view
        , init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- HELPERS


parseQuery : Location -> Maybe String
parseQuery location =
    Url.parsePath (Url.s "" <?> Url.stringParam "q") location
        |> Maybe.andThen identity


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Json.succeed msg
            else
                Json.fail "not ENTER"
    in
        on "keydown" (Json.andThen isEnter keyCode)



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


decodeFriends : Decoder Friends
decodeFriends =
    Pipeline.decode Friends
        |> Pipeline.required "count" Json.int
        |> Pipeline.required "query" Json.string
        |> Pipeline.required "results" (Json.list decodeFriend)


decodeFriend : Decoder Friend
decodeFriend =
    Pipeline.decode Friend
        |> Pipeline.required "id" Json.int
        |> Pipeline.required "name" Json.string
        |> Pipeline.required "username" Json.string


type alias Model =
    { query : String
    , friends : WebData Friends
    , debouncer : Debounce.Model String
    }


init : Location -> ( Model, Cmd Msg )
init location =
    let
        query =
            Maybe.withDefault "" (parseQuery location)

        debouncer =
            Debounce.init (100 * Time.millisecond) query
    in
        ( Model query Loading debouncer, getFriends query )



-- UPDATE


type Msg
    = SetQuery String
    | Search
    | SearchResponse String (WebData Friends)
    | UrlChange Location
    | DebouncerMsg (Debounce.Msg String)


nextUrl : String -> String
nextUrl query =
    if String.length query == 0 then
        "/"
    else
        "/?q=" ++ (Http.encodeUri query)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetQuery query ->
            { model | query = query }
                |> updateDebouncer (Debounce.Change query)

        Search ->
            ( { model | friends = Loading }
            , getFriends model.query
            )

        SearchResponse query response ->
            if model.query == query then
                ( { model | friends = response }, Cmd.none )
            else
                ( model, Cmd.none )

        UrlChange location ->
            let
                query =
                    Maybe.withDefault "" (parseQuery location)
            in
                if model.query /= query then
                    ( { model | query = query }, getFriends query )
                else
                    ( model, Cmd.none )

        DebouncerMsg dmsg ->
            updateDebouncer dmsg model


updateDebouncer : Debounce.Msg String -> Model -> ( Model, Cmd Msg )
updateDebouncer dmsg model =
    let
        ( nextDebouncer, cmd, settledQuery ) =
            Debounce.update dmsg model.debouncer

        nextModel =
            { model | debouncer = nextDebouncer }
    in
        case settledQuery of
            Nothing ->
                ( nextModel, Cmd.map DebouncerMsg cmd )

            Just query ->
                ( nextModel
                , Cmd.batch
                    [ newUrl (nextUrl query)
                    , getFriends query
                    ]
                )



-- VIEW


view : Model -> Html Msg
view { query, friends } =
    div [ class "app" ]
        [ viewSearchInput query
        , viewFriendsWebData friends
        ]


viewSearchInput : String -> Html Msg
viewSearchInput query =
    input
        [ type_ "search"
        , placeholder "Search friends..."
        , class "search-input"
        , value query
        , onInput SetQuery
        , onEnter Search
        ]
        [ text query ]


getErrorMessage : Http.Error -> String
getErrorMessage error =
    case error of
        Http.BadStatus { body } ->
            body

        _ ->
            "Request failed."


viewFriendsWebData : WebData Friends -> Html Msg
viewFriendsWebData friendsWebData =
    case friendsWebData of
        NotAsked ->
            text "Not Asked."

        Loading ->
            text "Loading."

        Failure error ->
            viewError error

        Success friends ->
            viewFriendList friends


viewError : Http.Error -> Html Msg
viewError error =
    div [ class "error-view" ]
        [ h5 []
            [ span [ class "error-message" ]
                [ text (getErrorMessage error) ]
            , span [ class "details" ]
                [ text " Press enter to try again." ]
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
        ul [ class "friend-list" ]
            (List.map viewFriend results)


viewFriend : Friend -> Html Msg
viewFriend friend =
    li [ class "friend-list-item" ]
        [ div [ class "friend" ]
            [ text (friend.name ++ " ")
            , span [ class "username" ] [ text friend.username ]
            ]
        ]



-- HTTP


friendsUrl : String -> String
friendsUrl query =
    "http://localhost:8000/api/friends?q=" ++ query


getFriends : String -> Cmd Msg
getFriends query =
    Http.get (friendsUrl query) decodeFriends
        |> RemoteData.sendRequest
        |> Cmd.map (SearchResponse query)
