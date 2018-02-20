# slugrat

A basic IRC Event Organiser

**ALPHA RELEASE**


## Help Commands

    <johnbull> slugrat: help
    -slugrat:#chan123- Commands: list, show, accept, reject, add, edit, delete, open, close, voters
    -slugrat:#chan123- For more details, use: slugrat: help <command>


### Help User Commands

    <johnbull> slugrat: help list
    -slugrat:#chan123- To list events, use: slugrat: list {all|created|open|closed|Event ID}

    <johnbull> slugrat: help show
    -slugrat:#chan123- To show an event, use: slugrat: show <number>

    <johnbull> slugrat: help accept
    -slugrat:#chan123- To accept for a date, use: slugrat: accept <event number> <date A> <date B>...
    -slugrat:#chan123- This will replace any previous response for the event

    <johnbull> slugrat: help reject
    -slugrat:#chan123- To reject all dates for an event, use: slugrat: reject <event number>
    -slugrat:#chan123- This will replace any previous response for the event


### Help Admin Commands

    <majorbull> slugrat: help add
    -slugrat:#chan123- To add an event, use: slugrat: add "Name of event" <ISO Date 1> <ISO Date 2> ...

    <majorbull> slugrat: help edit
    -slugrat:#chan123- To edit an event, use: slugrat: edit <event number> "Name of event" <ISO Date 1> <ISO Date 2> ...

    <majorbull> slugrat: help delete
    -slugrat:#chan123- To delete an event, use: slugrat: delete <event number>

    <majorbull> slugrat: help open
    -slugrat:#chan123- Opening an event will announce event to the channel and allow responses
    -slugrat:#chan123- To open an event, use: slugrat: open <number> <optional message>

    <majorbull> slugrat: help close
    -slugrat:#chan123- Closing an event will stop allowing responses and will show results to the channel
    -slugrat:#chan123- To close an event, use: slugrat: close <number>


## Example Conversations


### Create an event

    <majorbull> slugrat: add "Pub Meet" 2018-02-06 2018-02-13 2018-02-21
    -slugrat:#chan123- Event 1 "Pub Meet" created successfully
    -slugrat:#chan123- To open the event, use: slugrat: open 1

    <majorbull> slugrat: show 1
    -slugrat:#chan123- A - Pub Meet on 2018-02-06 - 0 votes
    -slugrat:#chan123- B - Pub Meet on 2018-02-13 - 0 votes
    -slugrat:#chan123- C - Pub Meet on 2018-02-21 - 0 votes
    -slugrat:#chan123- To open the event, use: slugrat: open 1

    <majorbull> slugrat: open 1
    -slugrat:#chan123- Pub Meet is being organised on one of the following dates:
    -slugrat:#chan123- A - Pub Meet on 2018-02-06 - 0 votes
    -slugrat:#chan123- B - Pub Meet on 2018-02-13 - 0 votes
    -slugrat:#chan123- C - Pub Meet on 2018-02-21 - 0 votes
    -slugrat:#chan123- To attend the event, use: slugrat: accept 1ABC


### Accept an event

    <johnbull> slugrat: accept 1AC
    -slugrat:#chan123- johnbull: Thank you, you are able to attend Pub Meet on 2018-02-06 and 2018-02-21.

    <janebull> slugrat: reject 1
    -slugrat:#chan123- janebull: Thank you, you are unable to attend Pub Meet on any date.

    <jillbull> slugrat: accept 1B
    -slugrat:#chan123- jillbull: Thank you, you are able to attend Pub Meet on 2018-02-13.

    <fuzzbutt> slugrat: accept 1A
    -slugrat:#chan123- fuzzbutt: Thank you, you are able to attend Pub Meet on 2018-02-06.


### Close an event

    <majorbull> close 1
    -slugrat:#chan123- You have closed event 1 - Pub Meet
    -slugrat:#chan123- A - Pub Meet on 2018-02-06 - 2 votes
    -slugrat:#chan123- B - Pub Meet on 2018-02-13 - 1 vote
    -slugrat:#chan123- C - Pub Meet on 2018-02-21 - 1 vote
    -slugrat:#chan123- To open the event, use: slugrat: open 1

    <majorbull> voters 1
    -slugrat:#chan123- A - Pub Meet on 2018-02-06 - 2 votes (johnbull, fuzzbutt)
    -slugrat:#chan123- B - Pub Meet on 2018-02-13 - 1 vote (jillbill)
    -slugrat:#chan123- C - Pub Meet on 2018-02-21 - 1 vote (johnbull)


### Amend dates and re-open event

    <majorbull> slugrat: list 1
    slugrat: 1 "Pub Meet" 2018-02-06 2018-02-13 2018-02-21 (CREATED)
    <majorbull> slugrat: edit 1 "Pub Meet" 2018-02-06 2018-02-21 2018-02-28
    -slugrat:#chan123- Event 1 "Pub Meet" edited successfully
    -slugrat:#chan123- To open the event, use: slugrat: open 1
    
    <majorbull> slugrat: show 1
    -slugrat:#chan123- A - Pub Meet on 2018-02-06 - 2 votes
    -slugrat:#chan123- B - Pub Meet on 2018-02-21 - 1 vote
    -slugrat:#chan123- C - Pub Meet on 2018-02-28 - 0 votes
    -slugrat:#chan123- To open the event, use: slugrat: open 1

    <majorbull> slugrat: open 1
    -slugrat:#chan123- Pub Meet is being organised on one of the following dates:
    -slugrat:#chan123- A - Pub Meet on 2018-02-06 - 2 votes
    -slugrat:#chan123- B - Pub Meet on 2018-02-21 - 1 votes
    -slugrat:#chan123- C - Pub Meet on 2018-02-28 - 0 votes
    -slugrat:#chan123- To attend the event, use: slugrat: accept 1ABC

    <johnbull> slugrat: accept 1ABC
    -slugrat:#chan123- johnbull: Thank you, you are able to attend Pub Meet on 2018-02-06, 2018-02-21 and 2018-02-28.

    <janebull> slugrat: accept 1C
    -slugrat:#chan123- janebull: Thank you, you are able to attend Pub Meet on 2018-02-28.

    <fuzzbutt> slugrat: accept 1AC
    -slugrat:#chan123- fuzzbutt: Thank you, you are able to attend Pub Meet on 2018-02-06 and 2018-02-28.

    <majorbull> slugrat: show 1
    -slugrat:#chan123- A - Pub Meet on 2018-02-06 - 2 votes
    -slugrat:#chan123- B - Pub Meet on 2018-02-21 - 1 vote
    -slugrat:#chan123- C - Pub Meet on 2018-02-28 - 3 votes
    -slugrat:#chan123- To attend the event, use: slugrat: accept 1ABC

    <majorbull> slugrat: close 1
    -slugrat:#chan123- You have closed event 1 - Pub Meet
    -slugrat:#chan123- A - Pub Meet on 2018-02-06 - 2 votes
    -slugrat:#chan123- B - Pub Meet on 2018-02-21 - 1 vote
    -slugrat:#chan123- C - Pub Meet on 2018-02-28 - 3 votes
    -slugrat:#chan123- To open the event, use: slugrat: open 1

    <majorbull> slugrat: select 1AC
    -slugrat:#chan123- Thank you, you have selected the following dates for the Pub Meet: 2018-02-06 and 2018-02-28


### List and close events

    <majorbull> slugrat: list
    -slugrat:#chan123- 1 "Pub Meet" is scheduled for 2018-02-28
    -slugrat:#chan123- 2 "Curry Night" 2018-03-24 2018-03-27 (OPEN)
    -slugrat:#chan123- 3 "Tiddlywinks Evening" 2018-04-02 2018-04-08 2018-04-12 (CLOSED)
    -slugrat:#chan123- 4 "Pub Meet" 2018-02-10 2018-02-12 2018-02-14 (CREATED)
    -slugrat:#chan123- To view detail, use: slugrat: show <event number>

    <majorbull> slugrat: delete 1
    -slugrat:#chan123- 1 - Pub Meet - deleted

    <majorbull> slugrat: delete 3
    -slugrat:#chan123- 3 - Tiddlywinks Evening - deleted

    <majorbull> slugrat: edit 4 "Spring Pub Meet"
    -slugrat:#chan123- Updated 4 - Spring Pub Meet

    <majorbull> slugrat: list
    -slugrat:#chan123- 2 - Curry Night - open
    -slugrat:#chan123- 4 - Spring Pub Meet - created
    -slugrat:#chan123- To view detail, use: slugrat: show <event number>


## Data storage

Possible data structure:

    $events = {
        '1' = {
            NAME    = "Pub Meet",
            OWNER   = 'majorbull',
            CHANNEL = '#chanabc',
            DATES   = [
                '2018-02-13',
                '2018-02-20',
                '2018-02-27',
            ],
            STATUS  = 'SCHEDULED',
            SCHEDULED = [
                '2018-02-27',
            ],

        },        
    }
    
Votes to be appended in simple CSV file, in format:

    channel,nick,event_id,dates...
    #chanabc,majorbull,1,2018-02-13,2018-02-20

