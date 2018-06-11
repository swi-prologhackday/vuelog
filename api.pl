:- module(api, [init_state/1, handle_event/3]).


:- use_module(library(clpfd)).
:- use_module(library(http/json), [atom_json_dict/3]).
:- use_module(util, [ts_day/2]).

% State calculations

state_check_meals_type(State0, State1) :-
    % because the meals-per-day field gets set by an input, sometimes
    % it ends up as a string
    ensure_number(State0.meals_per_day, MPD),
    debug(pengine, "ensure meals per day ~w", [MPD]),
    State1 = State0.put(meals_per_day, MPD).

state_gen_slots(State0, State1) :-
    _{end_day: EndD, start_day: StartD, meals_per_day: PerDay} :< State0,
    ts_day(EndTs, EndD), ts_day(StartTs, StartD),
    NSlots is round((EndTs - StartTs) / (3600*24)),
    debug(pengine, "Gen slots for ~w days", [NSlots]),
    length(Slots, NSlots),
    Test #= NSlots * PerDay,
    maplist({PerDay,Test}/[X]>>(
                length(X, PerDay),
                maplist(=(Test), X)
            ),
            Slots),
    State1 = State0.put(slots, Slots).

update_state -->
    { debug(pengine, "update state", []) },
    state_check_meals_type,
    state_gen_slots.

init_state(State) :-
    get_time(Start),
    End is Start + 7*3600*24,
    ts_day(Start, StartDay),
    ts_day(End, EndDay),
    % get meals for user
    State0 = _{start_day: StartDay,
               end_day: EndDay,
               meals_per_day: 2,
               meals: [_{name: "Spaghetti d'olio",
                         id: 1,
                         tags: [pasta]},
                       _{name: "Caldo Verde",
                         id: 2,
                         tags: [soup]}]},
    update_state(State0, State).

% Events

handle_event(State0, update, State1) :-
    update_state(State0, State1).

handle_event(State, Event, State) :-
    debug(pengine, "Unknown Pengine event ~w ~w", [State, Event]).

% Helpers

ensure_number(N, N) :- number(N), !.
ensure_number(S, N) :-
    string(S), number_string(N, S), !.
ensure_number(_, 0).
