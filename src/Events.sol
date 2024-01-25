// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract Events {
    struct EventDetails {
        address creator;
        string name;
        string location;
        uint endingDate;
        uint startDate;
        bool raffleDraw;
        bool raffleDrawEnd;
        uint rafflePrice;
        uint totalBalance;
        uint totalRafflePrice;
        PriceCategory price;
        EventStatus status;
        EventParticipant[] _eventParticipants;
        EventParticipant[] _raffleDrawParticipants;
    }

    struct EventParticipant {
        address _eventParticipant;
        string ticketType;
    }
    struct PriceCategory {
        uint regularPrice;
        uint vipPrice;
    }

    enum EventStatus {
        Pending,
        Active,
        Ongoing,
        Ended
    }

    mapping(address => EventDetails) public eventsMapping;
    mapping(uint => EventDetails) public eventsId;
    mapping(address => mapping(uint => EventParticipant)) public eventGoers;

    error AlreadyHaveActiveEvent(string name);
    error InvalidEvent();
    error NotEventParticipant();
    error InsufficientFeeForNonRaffleEvent();
    error InsufficientFeeForRaffleEvent();
    error PastDate();
    error NotRafflePriceNeeded();
    error RegularPriceNeeded();
    error NotRaffleEvent();
    error RaffleDrawNotEnded();
    error VipPriceNeeded();
    error NotCreator();
    error StartingTimeHasnotReached();
    error EventOngoing();
    error EventEnded();
    error EventHasnotStarted();

    uint totalBalance;
    uint eventsID;

    uint raffleDrawEventCreationPrice = 1e18;
    uint normalEventCreationPrice = 0.5e18;

    function createEvent(
        string memory _name,
        string memory _location,
        uint _endingDate,
        uint _startDate,
        bool _raffleDraw,
        uint _rafflePrice,
        uint _regularPrice,
        uint _vipPrice
    ) external payable {
        EventDetails storage eventDetails = eventsMapping[msg.sender];

        if (
            eventDetails.creator == msg.sender &&
            eventDetails.endingDate < block.timestamp
        ) {
            revert AlreadyHaveActiveEvent(_name);
        }
        if (msg.value < normalEventCreationPrice && !_raffleDraw) {
            revert InsufficientFeeForNonRaffleEvent();
        }
        if (msg.value < raffleDrawEventCreationPrice && _raffleDraw) {
            revert InsufficientFeeForRaffleEvent();
        }
        if (_endingDate < block.timestamp || _startDate < block.timestamp) {
            revert PastDate();
        }
        if (_raffleDraw && _rafflePrice < 0) {
            revert NotRafflePriceNeeded();
        }
        if (_regularPrice < 0) {
            revert RegularPriceNeeded();
        }
        if (_vipPrice < 0) {
            revert VipPriceNeeded();
        }

        eventsID++;

        eventsId[eventsID] = eventDetails;

        eventDetails.creator = msg.sender;
        eventDetails.name = _name;
        eventDetails.location = _location;
        eventDetails.startDate = _startDate;
        eventDetails.raffleDraw = _raffleDraw;
        eventDetails.rafflePrice = _rafflePrice;
        eventDetails.price.regularPrice = _regularPrice;
        eventDetails.price.vipPrice = _vipPrice;
        eventDetails.endingDate = _endingDate;
        eventDetails.status = EventStatus.Pending;

        totalBalance += msg.value;
    }

    function startEvent() public {
        EventDetails storage eventDetails = eventsMapping[msg.sender];
        if (eventDetails.creator != msg.sender) {
            revert NotCreator();
        }
        if (eventDetails.startDate < block.timestamp) {
            revert StartingTimeHasnotReached();
        }
        if (eventDetails.status == EventStatus.Active) {
            revert EventOngoing();
        }
        if (eventDetails.status == EventStatus.Ended) {
            revert EventEnded();
        }

        eventDetails.status = EventStatus.Active;
    }

    function endEvent(uint _eventId) external {
        EventDetails storage eventDetails = eventsId[_eventId];

        if (eventDetails.creator != msg.sender) {
            revert NotCreator();
        }
        if (eventDetails.startDate < block.timestamp) {
            revert EventHasnotStarted();
        }
        if (
            eventDetails.startDate > block.timestamp &&
            eventDetails.endingDate < block.timestamp
        ) {
            revert EventOngoing();
        }
        if (eventDetails.raffleDraw && !eventDetails.raffleDrawEnd) {
            revert RaffleDrawNotEnded();
        }

        //add function to send out event tickets money to event creator (MAYOWA)

        eventDetails.status = EventStatus.Ended;
    }

    function buyEventTicket(uint _eventId) external payable {
        EventDetails storage eventDetails = eventsId[_eventId];
        EventParticipant memory _participant;

        if (_eventId > eventsID) {
            revert InvalidEvent();
        }
        if (eventDetails.status == EventStatus.Active) {
            revert EventOngoing();
        }
        if (eventDetails.status == EventStatus.Ended) {
            revert EventEnded();
        }

        if (eventDetails.price.regularPrice == msg.value) {
            _participant._eventParticipant = msg.sender;
            _participant.ticketType = "Regular";
        }
        if (eventDetails.price.vipPrice == msg.value) {
            _participant._eventParticipant = msg.sender;
            _participant.ticketType = "VIP";
        }

        eventDetails.totalBalance += msg.value;

        eventGoers[msg.sender][_eventId] = _participant;
        eventDetails._eventParticipants.push(_participant);
    }

    function buyEventRaffleDraw(uint _eventId) external payable {
        EventDetails storage eventDetails = eventsId[_eventId];
        EventParticipant storage _participant = eventGoers[msg.sender][
            _eventId
        ];

        if (_eventId > eventsID) {
            revert InvalidEvent();
        }
        if (eventDetails.status == EventStatus.Ended) {
            revert EventEnded();
        }
        if (!eventDetails.raffleDraw) {
            revert NotRaffleEvent();
        }
        if (
            keccak256(abi.encodePacked(_participant.ticketType)) ==
            keccak256(abi.encodePacked(("")))
        ) {
            revert NotEventParticipant();
        }
        if (msg.value < eventDetails.rafflePrice) {
            revert NotRafflePriceNeeded();
        }

        eventDetails.totalRafflePrice += msg.value;

        _participant._eventParticipant = msg.sender;
        _participant.ticketType = "Raffle Draw";
        eventDetails._raffleDrawParticipants.push(_participant);
    }

    //add function to end raffle draw using random number feature and pay out the total price to winner (MAYOWA)
    function endRaffleDraw(uint _eventId) external {}

    function getEvent() public view returns (EventDetails memory _event) {
        EventDetails storage eventDetails = eventsMapping[msg.sender];
        _event = eventDetails;
    }
}
