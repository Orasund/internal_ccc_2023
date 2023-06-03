module Game exposing (..)

import Dict exposing (Dict)
import Track exposing (Track)


type alias PlatformId =
    Int


type PlayerPos
    = OnPlatform PlatformId
    | Jumping { from : PlatformId, to : PlatformId }


type alias Game =
    { track : Track
    , platforms : Dict PlatformId { position : ( Int, Int ), active : Bool }
    , rows : Dict Int (List PlatformId)
    , player : PlayerPos
    }


togglePlatform : PlatformId -> Game -> Game
togglePlatform id game =
    { game
        | platforms =
            game.platforms
                |> Dict.update id
                    (Maybe.map (\platform -> { platform | active = not platform.active }))
    }


getNextPossiblePlatforms : Game -> PlatformId -> List PlatformId
getNextPossiblePlatforms game from =
    game.platforms
        |> Dict.get from
        |> Maybe.map .position
        |> Maybe.andThen (\( _, y ) -> game.rows |> Dict.get (y + 1))
        |> Maybe.withDefault []
        |> List.filter
            (\next ->
                game.platforms
                    |> Dict.get next
                    |> Maybe.map .active
                    |> (==) (Just True)
            )


recheckNextPlayerPos : Game -> Game
recheckNextPlayerPos game =
    case game.player of
        OnPlatform platformId ->
            if getNextPossiblePlatforms game platformId /= [] then
                nextPlayerPos game

            else
                game

        Jumping _ ->
            game


nextPlayerPos : Game -> Game
nextPlayerPos game =
    let
        currentPos =
            case game.player of
                OnPlatform platformId ->
                    platformId

                Jumping { to } ->
                    to

        player =
            currentPos
                |> getNextPossiblePlatforms game
                |> List.head
                |> Maybe.map
                    (\next ->
                        Jumping { from = currentPos, to = next }
                    )
                |> Maybe.withDefault (OnPlatform currentPos)
    in
    { game | player = player }


new : Game
new =
    let
        track =
            Track.default

        platforms =
            track
                |> List.indexedMap
                    (\j list ->
                        list |> List.map (\i -> { position = ( i, j ), active = False })
                    )
                |> List.concat
                |> List.indexedMap Tuple.pair
                |> Dict.fromList

        rows =
            platforms
                |> Dict.foldl
                    (\id { position } ->
                        let
                            ( _, y ) =
                                position
                        in
                        Dict.update y
                            (\maybe ->
                                maybe
                                    |> Maybe.withDefault []
                                    |> (::) id
                                    |> Just
                            )
                    )
                    Dict.empty

        player =
            OnPlatform 0
    in
    { track = track
    , platforms = platforms
    , player = player
    , rows = rows
    }
