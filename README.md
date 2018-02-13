# slugrat

Proposal for an IRC Event Organiser

**THIS IS A PROPOSAL ONLY - THERE IS NO CODE**


## Help Commands

    <johnbull> slugrat: help
    <slugrat> Commands: list, show, accept, reject, add, edit, delete, open, close, voters
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
    <slugrat> To add an event, use: slugrat: add "Name of event" <ISO Date 1> <ISO Date 2> ...

    <majorbull> slugrat: help edit
    <slugrat> To edit an event, use: slugrat: edit <event number> "Name of event" <ISO Date 1> <ISO Date 2> ...

    <majorbull> slugrat: help delete
    <slugrat> To delete an event, use: slugrat: delete <event number>

    <majorbull> slugrat: help open
    <slugrat> Opening an event will announce event to the channel and allow responses
    <slugrat> To open an event, use: slugrat: open <number> <optional message>

    <majorbull> slugrat: help close
    <slugrat> Closing an event will stop allowing responses and will show results to the channel
    <slugrat> To close an event, use: slugrat: close <number>


## Example Conversations


### Create an event

    <majorbull> slugrat: add "Pub Meet" 2018-02-06 2018-02-13 2018-02-21
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
    <slugrat> To attend the event, use: slugrat: accept 1ABC


### Accept an event

    <johnbull> slugrat: accept 1AC
    <slugrat> johnbull: Thank you, you are able to attend Pub Meet on 2018-02-06 and 2018-02-21.

    <janebull> slugrat: reject 1
    <slugrat> janebull: Thank you, you are unable to attend Pub Meet on any date.

    <jillbull> slugrat: accept 1B
    <slugrat> jillbull: Thank you, you are able to attend Pub Meet on 2018-02-13.

    <fuzzbutt> slugrat: accept 1A
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

    <majorbull> slugrat: edit 1 "Pub Meet" 2018-02-06 2018-02-21 2018-02-28
    <slugrat> majorbull: Event 1 "Pub Meet" edited successfully
    <slugrat> To open the event, use: slugrat: open 1
    
    <majorbull> slugrat: show 1
    <slugrat> A - Pub Meet on 2018-02-06 - 2 votes
    <slugrat> B - Pub Meet on 2018-02-21 - 1 vote
    <slugrat> C - Pub Meet on 2018-02-28 - 0 votes
    <slugrat> To open the event, use: slugrat: open 1

    <majorbull> slugrat: open 1
    <slugrat> Pub Meet is being organised on one of the following dates:
    <slugrat> A - Pub Meet on 2018-02-06 - 2 votes
    <slugrat> B - Pub Meet on 2018-02-21 - 1 votes
    <slugrat> C - Pub Meet on 2018-02-28 - 0 votes
    <slugrat> To attend the event, use: slugrat: accept 1ABC

    <johnbull> slugrat: accept 1ABC
    <slugrat> johnbull: Thank you, you are able to attend Pub Meet on 2018-02-06, 2018-02-21 and 2018-02-28.

    <janebull> slugrat: accept 1C
    <slugrat> janebull: Thank you, you are able to attend Pub Meet on 2018-02-28.

    <fuzzbutt> slugrat: accept 1AC
    <slugrat> fuzzbutt: Thank you, you are able to attend Pub Meet on 2018-02-06 and 2018-02-28.

    <majorbull> slugrat: show 1
    <slugrat> A - Pub Meet on 2018-02-06 - 2 votes
    <slugrat> B - Pub Meet on 2018-02-21 - 1 vote
    <slugrat> C - Pub Meet on 2018-02-28 - 3 votes
    <slugrat> To attend the event, use: slugrat: accept 1ABC

    <majorbull> slugrat: close 1
    <slugrat> You have closed event 1 - Pub Meet
    <slugrat> A - Pub Meet on 2018-02-06 - 2 votes
    <slugrat> B - Pub Meet on 2018-02-21 - 1 vote
    <slugrat> C - Pub Meet on 2018-02-28 - 3 votes
    <slugrat> To open the event, use: slugrat: open 1

    <majorbull> slugrat: select 1C
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

    <majorbull> slugrat: edit 4 "Spring Pub Meet"
    <slugrat> Updated 4 - Spring Pub Meet

    <majorbull> slugrat: list
    <slugrat> 2 - Curry Night - open
    <slugrat> 4 - Spring Pub Meet - created
    <slugrat> To view detail, use: slugrat: show <event number>

## Data storage

Possible data structure:

    $events = {
        '1' = {
            name    = "Pub Meet",
            owner   = 'majorbull',
            channel = '#chanabc',
            dates   = [
                '2018-02-13',
            ],
        },        
    }
    
Votes to be appended in simple CSV file, in format:

    channel,nick,event_id,dates...
    #chanabc,majorbull,1,2018-02-13,2018-02-20

