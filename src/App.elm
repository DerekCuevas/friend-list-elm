module App exposing (..)

import Html exposing (Html, Attribute, div, span, input, ul, li, h5, text, i)
import Html.Attributes exposing (type_, placeholder, autocomplete, class, value)
import Html.Events exposing (on, onInput, onClick, keyCode)
import Json.Decode exposing (Decoder, int, string, list)
import Json.Decode.Pipeline exposing (decode, required)
import RemoteData exposing (..)
import Http
import Navigation exposing (Location, newUrl)
import UrlParser exposing (parsePath, s, stringParam, (<?>))
import Debounce
import Time exposing (..)


-- HELPERS


parseQuery : Location -> Maybe String
parseQuery location =
    let
        query =
            parsePath (s "" <?> stringParam "q") location
    in
        Maybe.withDefault Nothing query


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
    , debouncer : Debounce.Model String
    }


settleTime : Time
settleTime =
    100 * millisecond


init : Location -> ( Model, Cmd Msg )
init location =
    let
        query =
            Maybe.withDefault "" (parseQuery location)

        debouncer =
            Debounce.init settleTime query
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
        "/?q=" ++ query


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetQuery query ->
            { model | query = query }
                |> updateDebouncer (Debounce.Change query)

        Search ->
            ( { model | friends = Loading }, getFriends model.query )

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
                , Cmd.batch [ newUrl (nextUrl query), getFriends query ]
                )



-- VIEW


view : Model -> Html Msg
view { query, friends } =
    div [ class "app" ]
        [ (viewSearchInput query)
        , (viewFriends friends)
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
            [ span [ class "error-message" ] [ text message ]
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
        |> Cmd.map (SearchResponse query)
