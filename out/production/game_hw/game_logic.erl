%%%-------------------------------------------------------------------
%%% @author belovpavel
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. июн 2015 15:42
%%%-------------------------------------------------------------------
-module(game_logic).
-author("belovpavel").
%-behaviour(gen_server).
-export([terminate/2,init/1, handle_cast/2, handle_info/2, start_link/0, handle_call/3,  who_won/1, join_game/2,who_plays/1, try_make_turn/4,  get_cell/3,start_game/0 ]).

-record(world_information,
{ list_of_symbols=[],
  is_alive=[],
  list_of_all_players=[],
  queue_of_players =[],
  current_player =[],
  winner=null,
  gamefield = dict:new() }).




try_make_turn(X,Y,PlayerName,State) ->
  Is_Cell = get_cell(X,Y,State),
  Who_should_play = lists:nth(1,State#world_information.current_player),
  if Who_should_play == PlayerName ->
    if Is_Cell == empty_cell ->
      if State#world_information.winner == null -> make_turn(X,Y,PlayerName,State);
        State#world_information.winner /= null -> {end_game, State}
      end;
      Is_Cell /= empty_cell -> {cell_is_not_empty, State}
    end;
    Who_should_play /= PlayerName -> {not_current_player, State}
  end
.

make_turn(X,Y,PlayerName,State) ->
  Field_changed = dict:append({X,Y},PlayerName,State#world_information.gamefield),
  Winner = check_winner(X,Y,PlayerName,Field_changed),
  if Winner == PlayerName -> {end_game,State#world_information{winner = PlayerName, gamefield = Field_changed}};
    Winner /= PlayerName ->
      if State#world_information.queue_of_players /= [] ->
        Next_Player = lists:nth(1,State#world_information.queue_of_players),
        Cut_queue = lists:delete(Next_Player,State#world_information.queue_of_players),
        Rotated_queue = lists:append([Cut_queue,[PlayerName]]),
        {no_winner,State#world_information{queue_of_players = Rotated_queue, current_player = [Next_Player], gamefield = Field_changed}};
        State#world_information.queue_of_players == [] ->{new_player,State}
      end
  end
.

check_winner(X,Y,Name,Field) ->
  We_have_winner = somebody_won(X,Y,Name,Field),
  if We_have_winner == true -> Name;
     We_have_winner == false -> no_winner
  end
.

get_cell(X, Y, State) ->
  Who_is_there = dict:find({X,Y},State#world_information.gamefield),
  if Who_is_there == error -> empty_cell;
    Who_is_there /= error -> {_, Name} = dict:find({X,Y},State#world_information.gamefield), Name
  end
.

join_game(Name, State) ->
  Playing = State#world_information.current_player,
  Players = State#world_information.current_player ++ State#world_information.queue_of_players,
  Unique_name = lists:member(Name,Players),
  Extended_is_alive = State#world_information.is_alive ++ [Name],
  Extended_all_players = State#world_information.list_of_all_players ++ [Name],
  Extended_list_of_symbols = State#world_information.list_of_symbols ++ [Name],
  if length(Players) == 2 -> {full, State};
    length(Players) /= 2 ->
      if Unique_name == true -> {not_ok, State};
        Unique_name /= true ->
          if Playing == [] -> {ok, State#world_information{list_of_all_players = Extended_all_players, is_alive = Extended_is_alive, current_player = [Name], list_of_symbols = Extended_list_of_symbols}};
            Playing /= [] -> {ok, State#world_information{list_of_all_players = Extended_all_players, is_alive = Extended_is_alive, queue_of_players = State#world_information.queue_of_players ++ [Name], list_of_symbols = Extended_list_of_symbols}}
          end
      end
  end
.

somebody_won(X,Y,Name,Field) ->
  Num_of_cells_1 = count_cells(X,Y,Name,Field,1, 0) + count_cells(X,Y,Name,Field, -1, 0) - 1,
  Num_of_cells_2 = count_cells(X,Y,Name,Field,1, 1) + count_cells(X,Y,Name,Field, -1, -1) - 1,
  Num_of_cells_3 = count_cells(X,Y,Name,Field, 0, 1) + count_cells(X,Y,Name,Field, 0, -1) - 1,
  Num_of_cells_4 =  count_cells(X,Y,Name,Field,1, -1) + count_cells(X,Y,Name,Field, -1, 1) - 1,
  if ((Num_of_cells_1 >= 5) or (Num_of_cells_2 >= 5) or (Num_of_cells_3 >= 5) or (Num_of_cells_4 >= 5)) -> true;
    true -> false
  end
.

count_cells(X,Y,Name,Field, Dx, Dy) ->
  Check_cell = dict:find({X,Y},Field),
  if Check_cell == error -> Who_owns_the_cell = ["baaaaaaaadyouwontevercreatenamelikethis"];
    Check_cell /= error -> {_, Who_owns_the_cell} = Check_cell
  end,
  [Target_name] = Who_owns_the_cell,
  if Target_name /= Name -> 0;
   % case Where_we_go of
   %   _ -> 0
   % end;
    Target_name == Name -> count_cells(X + Dx,Y + Dy,Name,Field,Dx, Dy) + 1
      %case Where_we_go of
      %  up -> count_cells(X,Y+1,Name,Field,Dx, Dy) + 1;
      %  down -> count_cells(X,Y-1,Name,Field,Where_we_go) + 1;
      %  right -> count_cells(X+1,Y,Name,Field,Where_we_go) + 1;
      %  left -> count_cells(X-1,Y,Name,Field,Where_we_go) + 1;
      %  diag_2 -> count_cells(X+1,Y+1,Name,Field,Where_we_go) + 1;
      %  diag_1 -> count_cells(X-1,Y+1,Name,Field,Where_we_go) + 1;
      %  diag_3 -> count_cells(X+1,Y-1,Name,Field,Where_we_go) + 1;
      %  diag_4 -> count_cells(X-1,Y-1,Name,Field,Where_we_go) + 1
      %end
  end
.

who_plays(State) ->
  State#world_information.list_of_symbols
.


who_won(State) ->
  State#world_information.winner
.

start_link() -> gen_server:start_link({global, logic}, ?MODULE, [], []).
init([]) -> { ok, game_logic:start_game() }.
handle_call( {who_plays} , _, State) -> { reply, who_plays(State), State } ;
handle_call( {who_won} , _, State) -> {reply, who_won(State), State};
handle_call( {get_cell, X, Y}, _, State) -> {reply, get_cell(X, Y, State), State};
handle_call( {get_field}, _, State) -> {reply, State#world_information.gamefield, State};
handle_call( {make_turn, PlayerName, X, Y}, _, State) ->
  {Status, NewState} = game_logic:try_make_turn(X, Y, PlayerName, State),
  {reply, Status, NewState};
handle_call( {join, Name}, _, State) ->
  {Status, NewState} = join_game(Name, State),
  {reply, Status, NewState}.
handle_cast( {reset}, _ ) -> {noreply, #world_information{}}.

start_game() -> #world_information{}.
terminate(_Reason, _State) -> ok.
handle_info(_, State) -> { noreply, State }.