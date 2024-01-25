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
        uint rafflePrice;
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

    error AlreadyHaveActiveEvent(string name);
    error InsufficientFeeForNonRaffleEvent();
    error InsufficientFeeForRaffleEvent();
    error PastDate();
    error RafflePriceNeeded();
    error RegularPriceNeeded();
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

    function addEvent(
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
            revert RafflePriceNeeded();
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

    function endEvent() public {
        EventDetails storage eventDetails = eventsMapping[msg.sender];
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
        eventDetails.status = EventStatus.Ended;
    }

    function buyEventTicket(uint _eventId) external payable {
        EventDetails storage eventDetails = eventsId[_eventId];
        EventParticipant memory _participant;

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
            eventDetails._raffleDrawParticipants.push(_participant);
        }

        eventDetails._eventParticipants.push(_participant);
    }

    function getEvent() public view returns (EventDetails memory _event) {
        EventDetails storage eventDetails = eventsMapping[msg.sender];
        _event = eventDetails;
    }
}
