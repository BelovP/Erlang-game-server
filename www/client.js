const W = 100;
const H = 100;
const CellSize = 20;
const PossibleSigns = ["X","O"];
const ApiURLBase = "/api/game_http_server/";
const WhoPlaysURL = ApiURLBase + "who_plays";
const JoinNewPlayerURL = ApiURLBase + "join";
const LeaveGameURL = ApiURLBase + "leave";
const GetFieldURL = ApiURLBase + "get_field";
const MakeTurnURL = ApiURLBase + "make_turn";
const ResetURL = ApiURLBase + "reset";
const WhoWonURL = ApiURLBase + "who_won";

$(document).ready(
function() {
    var array = [];
    function reset() {
        $.ajax({url:ResetURL, dataType:"text"}).done(
        function (status) {
            if (status == "ok") {
                $("#join-button").text("Присоединиться");
                $("#player-name").val("");
                draw_field();
                who_plays()
            }
        })
    }

    function draw_field() {
        var field = $("#field");
        field.html("");
        for (var i = 0; i < H; ++i) {
            for (var j = 0; j < W; ++j) {
                var cell = "<div class = 'cell' x = '%1' y = '%2' style = 'top:%3px; left:%4px; width:%5px; height:%6px' />".
                replace("%1",i).replace("%2",j).replace("%3",CellSize*i).replace("%4",CellSize*j).replace("%5",CellSize).replace("%6",CellSize);
                field.append(cell)
            }
        }

        $(".cell").click(
        function() {
            var who_move = $("#player-name").val();
            var x = $(this).attr("x");
            var y = $(this).attr("y");
            make_turn(who_move, x, y)
        })
    }

    function set_symbol(i) {
        return PossibleSigns[i]
    }

    function get_symbol(player_name) {
        for (var i = 0; i < array.length; ++i) {
            if (player_name == array[i].name) {
                return array[i].symbol
            }
        }
    }

    function make_turn(who_move, x, y) {
        $.ajax({url:MakeTurnURL + "/" + who_move + "/" + x + "/" + y, dataType:"text"}).done(
        function (status) {
            if (status == "ok") {
                who_plays()
            }
            else
                if (status == "not_your_turn"){
                    alert("Сейчас ход другого игрока!")
                }
        })
    }

    function who_plays() {
        $.ajax({url:WhoPlaysURL, dataType:"json"}).done(
        function(r) {
            var list_of_players = r.players;
            var list = "";
            array = [];
            for (var i = 0; i < list_of_players.length; ++i) {
                var player = list_of_players[i];
                var s = set_symbol(i);
                array.push({symbol:s, name:player});
                list += player + "(" + s + ")"
            }
            $("#who-plays").html(list);
            draw_symbol()
        })
    }

    function draw_symbol(){
        $.ajax({url:GetFieldURL, dataType:"json"}).done(
        function(q){
            for(var i = 0; i < q.length; ++i) {
                var field = q[i];
                var s = get_symbol(field.player);
                $(".cell[x='" + field.x + "'][y='" + field.y + "']").text(s)
            }
        })
    }

    function join_new_player() {
        var login = $("#player-name").val();
        if (login.length != 0) {
            $.ajax({url:JoinNewPlayerURL + "/" + login, dataType:"text"}).done(
                function (status) {
                    if (status == "ok") {
                        who_plays()
                    }
                    else {
                        if (status == "not_ok") {
                            alert("Игрок с таким именем уже существует")
                        }
                        if (status == "full") {
                            alert("Нет мест")
                        }
                    }
                })
        }
    }

    $("#join-button").button().click(
    function() {
        join_new_player()
    });

    $("#reset-button").button().click(reset);
    draw_field();
    setInterval(who_plays, 1000);
    setInterval(who_won, 1000);

    function who_won() {
        $.ajax({url:WhoWonURL, dataType:"text"}).done (
        function(winner) {
            var current_player = $("#player-name").val();

            if ( winner != "nobody" && current_player != winner)
                $("#game-over-dialog").text("Вы проиграли! Победил " + winner + ".").dialog("open")
            else {

                if (winner != "nobody" && current_player == winner)
                    $("#game-over-dialog").text("Вы выиграли!").dialog("open")
            }
        });
    }

    $("#game-over-dialog").dialog({
        title:"Игра окончена", modal:true, autoOpen:false, buttons:[{text:"Начать заново",click:
        function() {
            reset();
            $(this).dialog("close")
        }}]
    })
});