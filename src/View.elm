module View exposing (..)

import Config
import Dict exposing (Dict)
import Game exposing (Game, Platform, PlatformId, PlayerPos(..))
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Layout
import Note exposing (Note(..))


titleScreen : { start : msg } -> Html msg
titleScreen args =
    [ "<Game Title>"
        |> Html.text
        |> Layout.heading1 [ Html.Attributes.style "color" Config.playerColor ]
    , Layout.textButton [] { onPress = Just args.start, label = "Start" }
    ]
        |> Layout.column [ Layout.gap 100 ]
        |> Layout.el
            (Layout.centered
                ++ [ Html.Attributes.style "position" "relative"
                   , Html.Attributes.style "background-color" Config.backgroundColor
                   , Html.Attributes.style "height" (String.fromFloat Config.screenHeight ++ "px")
                   , Html.Attributes.style "width" (String.fromFloat Config.screenWidth ++ "px")
                   ]
            )


fromGame :
    { ratioToNextBeat : Float
    , onClick : PlatformId -> msg
    , beatsPlayed : Int
    }
    -> Game
    -> Html msg
fromGame args game =
    let
        getPlatformPosition id =
            game.platforms
                |> Dict.get id
                |> Maybe.map (\{ start, note } -> ( note, start ))
                |> Maybe.withDefault ( C1, 0 )

        playerPos =
            case game.player of
                OnPlatform id ->
                    getPlatformPosition id
                        |> calcPlayerPositionOnPlatform
                            { ratioToNextBeat = args.ratioToNextBeat
                            , beatsPlayed = args.beatsPlayed
                            }

                Jumping { from, to } ->
                    calcPlayerJumpingPosition
                        { from = getPlatformPosition from
                        , to = getPlatformPosition to
                        , ratioToNextBeat = args.ratioToNextBeat
                        , beatsPlayed = args.beatsPlayed
                        }
    in
    [ game.platforms |> platforms args
    , [ playerPos |> player ]
    ]
        |> List.concat
        |> Html.div
            [ Html.Attributes.style "position" "relative"
            , Html.Attributes.style "background-color" Config.backgroundColor
            , Html.Attributes.style "height" (String.fromFloat Config.screenHeight ++ "px")
            , Html.Attributes.style "width" (String.fromFloat Config.screenWidth ++ "px")
            ]


player : ( Float, Float ) -> Html msg
player ( x, y ) =
    Html.div
        [ Html.Attributes.style "width" (String.fromFloat Config.playerSize ++ "px")
        , Html.Attributes.style "height" (String.fromFloat Config.playerSize ++ "px")
        , Html.Attributes.style "background-color" Config.playerColor
        , Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "top" (String.fromFloat y ++ "px")
        , Html.Attributes.style "left" (String.fromFloat x ++ "px")
        ]
        []


platforms :
    { ratioToNextBeat : Float
    , onClick : PlatformId -> msg
    , beatsPlayed : Int
    }
    -> Dict PlatformId Platform
    -> List (Html msg)
platforms args dict =
    dict
        |> Dict.toList
        |> List.map
            (\( platformId, { start, note, active } ) ->
                platform { active = active, onClick = args.onClick platformId }
                    (calcPlatformPosition
                        { ratioToNextBeat = args.ratioToNextBeat
                        , beatsPlayed = args.beatsPlayed
                        , start = start
                        , note = note
                        }
                    )
            )


calcPlayerJumpingPosition :
    { from : ( Note, Int )
    , to : ( Note, Int )
    , ratioToNextBeat : Float
    , beatsPlayed : Int
    }
    -> ( Float, Float )
calcPlayerJumpingPosition args =
    let
        calcPosition =
            calcPlayerPositionOnPlatform
                { ratioToNextBeat = args.ratioToNextBeat
                , beatsPlayed = args.beatsPlayed
                }

        ( x1, y1 ) =
            calcPosition args.to

        ( x2, y2 ) =
            calcPosition args.from

        ratio =
            if args.ratioToNextBeat > (1 - Config.jumpTime) then
                (args.ratioToNextBeat - (1 - Config.jumpTime)) / Config.jumpTime

            else
                0
    in
    ( x2 + (x1 - x2) * ratio, y2 + (y1 - y2) * ratio )


calcPlayerPositionOnPlatform :
    { ratioToNextBeat : Float
    , beatsPlayed : Int
    }
    -> ( Note, Int )
    -> ( Float, Float )
calcPlayerPositionOnPlatform args ( note, start ) =
    let
        ( x, y ) =
            calcPlatformPosition
                { ratioToNextBeat = args.ratioToNextBeat
                , beatsPlayed = args.beatsPlayed
                , start = start
                , note = note
                }
    in
    ( x + Config.platformWidth / 2 - Config.playerSize / 2
    , y + Config.platformHeight / 2 - Config.playerSize / 2
    )


calcPlatformPosition : { ratioToNextBeat : Float, beatsPlayed : Int, start : Int, note : Note } -> ( Float, Float )
calcPlatformPosition args =
    let
        ratio =
            args.ratioToNextBeat
    in
    ( Config.horizontalSpaceBetweenPlatforms
        * toFloat (Note.toInt args.note)
    , (Config.platformHeight + Config.verticalSpaceBetweenPlatforms)
        * (toFloat -args.start + ratio + toFloat args.beatsPlayed)
        + Config.screenHeight
        - (Config.platformHeight
            * 2
          )
    )


platform : { active : Bool, onClick : msg } -> ( Float, Float ) -> Html msg
platform args ( x, y ) =
    Html.button
        [ Html.Attributes.style "width" (String.fromFloat Config.platformWidth ++ "px")
        , Html.Attributes.style "height" (String.fromFloat Config.platformHeight ++ "px")
        , Html.Attributes.style "background-color"
            (if args.active then
                Config.activePlatformColor

             else
                Config.inactivePlatformColor
            )
        , Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "border" "0px"
        , Html.Attributes.style "border-radius" "100%"
        , Html.Attributes.style "top" (String.fromFloat y ++ "px")
        , Html.Attributes.style "left" (String.fromFloat x ++ "px")
        , Html.Events.onClick args.onClick
        ]
        []
