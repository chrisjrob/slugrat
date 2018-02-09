# slugrat

Proposal for an IRC Event Organiser


## Help Commands

<johnbull> slugrat: help
<slugrat> User commands: list, show, accept, reject
<slugrat> Admin commands: add, delete, rename, open, close, voters
<slugrat> For more details, use: slugrat: help <command>


### Help User Commands

<johnbull> slugrat: help list
<slugrat> To list events, use: slugrat: list

<johnbull> slugrat: help show
<slugrat> To show an event, use: slugrat: show <number>

<johnbull> slugrat: help accept
<slugrat> To accept for a date, use: slugrat: accept <event number> <date A> <date B>...
<slugrat> This will replace any previous response for the event

<johnbull> slugrat: help reject
<slugrat> To reject all dates for an event, use: slugrat: reject <event number>
<slugrat> This will replace any previous response for the event


### Help Admin Commands

<majorbull> slugrat: help add
<slugrat> Sub-commands: event, date
<slugrat> For more details, use: slugrat: help add <sub-command>

<majorbull> slugrat: help add event
<slugrat> To add an event, use: slugrat: add event "Name of event" <ISO Date 1> <ISO Date 2> ...

<majorbull> slugrat: help add date
<slugrat> To add a date to an event, please use: slugrat: add date <event number> <ISO Date>

<majorbull> slugrat: help delete
<slugrat> Sub-commands: event, date
<slugrat> For more details, use: slugrat: help delete <sub-command>

<majorbull> slugrat: help delete event
<slugrat> To delete an event, use: slugrat: delete event <event number>

<majorbull> slugrat: help delete date
<slugrat> To delete a date from an event, please use: slugrat: delete date <event number> <ISO Date>

<majorbull> slugrat: help rename
<slugrat> To rename an event, use: slugrat: rename <number> "New Name"

<majorbull> slugrat: help open
<slugrat> Opening an event will announce event to the channel and allow responses
<slugrat> To open an event, use: slugrat: open <number> <optional message>

<majorbull> slugrat: help close
<slugrat> Closing an event will stop allowing responses and will show results to the channel
<slugrat> To close an event, use: slugrat: close <number>


## Example Conversations


### Create an event

<majorbull> slugrat: add event "Pub Meet" 2018-02-06 2018-02-13 2018-02-21
<slugrat> majorbull: Event 1 "Pub Meet" created successfully
<slugrat> To open the event, use: slugrat: open 1

<majorbull> slugrat: show 1
<slugrat> A - Pub Meet on 2018-02-06 - 0 votes
<slugrat> B - Pub Meet on 2018-02-13 - 0 votes
<slugrat> C - Pub Meet on 2018-02-21 - 0 votes
<slugrat> To open the event, use: slugrat: open 1

<majorbull> slugrat: open 1
<slugrat> Pub Meet is being organised on one of the following dates:
<slugrat> A - Pub Meet on 2018-02-06 - 0 votes
<slugrat> B - Pub Meet on 2018-02-13 - 0 votes
<slugrat> C - Pub Meet on 2018-02-21 - 0 votes
<slugrat> To attend the event, use: slugrat: accept 1 A B C


### Accept an event

<johnbull> slugrat: accept 1 A C
<slugrat> johnbull: Thank you, you are able to attend Pub Meet on 2018-02-06 and 2018-02-21.

<janebull> slugrat: reject 1
<slugrat> janebull: Thank you, you are unable to attend Pub Meet on any date.

<jillbull> slugrat: accept 1 B
<slugrat> jillbull: Thank you, you are able to attend Pub Meet on 2018-02-13.

<fuzzbutt> slugrat: accept 1 A
<slugrat> fuzzbutt: Thank you, you are able to attend Pub Meet on 2018-02-06.


### Close an event

<majorbull> close 1
<slugrat> You have closed event 1 - Pub Meet
<slugrat> A - Pub Meet on 2018-02-06 - 2 votes
<slugrat> B - Pub Meet on 2018-02-13 - 1 vote
<slugrat> C - Pub Meet on 2018-02-21 - 1 vote
<slugrat> To open the event, use: slugrat: open 1

<majorbull> voters 1
<slugrat> A - Pub Meet on 2018-02-06 - 2 votes (johnbull, fuzzbutt)
<slugrat> B - Pub Meet on 2018-02-13 - 1 vote (jillbill)
<slugrat> C - Pub Meet on 2018-02-21 - 1 vote (johnbull)


### Amend dates and re-open event

<majorbull> slugrat: delete date 1 B
<slugrat> Date 2018-02-13 removed from Pub Meet

<majorbull> slugrat: add date 1 2018-02-28
<slugrat> Date 2018-02-28 added to Pub Meet

<majorbull> slugrat: show 1
<slugrat> A - Pub Meet on 2018-02-06 - 2 votes
<slugrat> C - Pub Meet on 2018-02-21 - 1 vote
<slugrat> D - Pub Meet on 2018-02-28 - 0 votes
<slugrat> To open the event, use: slugrat: open 1

<majorbull> slugrat: open 1
<slugrat> Pub Meet is being organised on one of the following dates:
<slugrat> A - Pub Meet on 2018-02-06 - 2 votes
<slugrat> C - Pub Meet on 2018-02-21 - 1 votes
<slugrat> D - Pub Meet on 2018-02-28 - 0 votes
<slugrat> To attend the event, use: slugrat: accept 1 A C D

<johnbull> slugrat: accept 1 A C D
<slugrat> johnbull: Thank you, you are able to attend Pub Meet on 2018-02-06 and 2018-02-21.

<janebull> slugrat: accept 1 D
<slugrat> janebull: Thank you, you are unable to attend Pub Meet on any date.

<fuzzbutt> slugrat: accept 1 A D
<slugrat> fuzzbutt: Thank you, you are able to attend Pub Meet on 2018-02-06.

<majorbull> slugrat: show 1
<slugrat> A - Pub Meet on 2018-02-06 - 2 votes
<slugrat> C - Pub Meet on 2018-02-21 - 1 vote
<slugrat> D - Pub Meet on 2018-02-28 - 3 votes
<slugrat> To attend the event, use: slugrat: accept 1 A C D

<majorbull> slugrat: close 1
<slugrat> You have closed event 1 - Pub Meet
<slugrat> A - Pub Meet on 2018-02-06 - 2 votes
<slugrat> C - Pub Meet on 2018-02-21 - 1 vote
<slugrat> D - Pub Meet on 2018-02-28 - 3 votes
<slugrat> To open the event, use: slugrat: open 1

<majorbull> slugrat: select 1 D
<slugrat> Thank you, you have selected date 2018-02-28 for Pub Meet.


### List and close events

<majorbull> slugrat: list
<slugrat> 1 - Pub Meet - selected 2018-02-28
<slugrat> 2 - Curry Night - open
<slugrat> 3 - Tiddlywinks Evening - closed
<slugrat> 4 - Pub Meet - created
<slugrat> To view detail, use: slugrat: show <event number>

<majorbull> slugrat: delete 1
<slugrat> 1 - Pub Meet - deleted

<majorbull> slugrat: delete 3
<slugrat> 3 - Tiddlywinks Evening - deleted

<majorbull> slugrat: rename 4 "Spring Pub Meet"
<slugrat> Renamed 4 - Spring Pub Meet

<majorbull> slugrat: list
<slugrat> 2 - Curry Night - open
<slugrat> 4 - Spring Pub Meet - created
<slugrat> To view detail, use: slugrat: show <event number>


