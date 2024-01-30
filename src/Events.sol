// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "airnode/contracts/rrp/requesters/RrpRequesterV0.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract Events is RrpRequesterV0, Ownable {
// Events
    event RequestedRandomNumber(bytes32 indexed requestId);
    event ReceivedRandomNumber(bytes32 indexed requestId, uint256 randomNumber);

    struct EventDetails {
        address creator;
        string name;
        string location;
        uint256 endingDate;
        uint256 startDate;
        bool raffleDraw;
        bool raffleDrawEnd;
        uint256 rafflePrice;
        uint256 totalBalance;
        uint256 totalRafflePrice;
        PriceCategory price;
        EventStatus status;
        EventParticipant[] _eventParticipants;
        EventParticipant[] _raffleDrawParticipants;
    }

    struct EventParticipant {
        address _eventParticipant;
        string ticketType;
    }

    struct RaffleDrawInfo {
        bool raffleDrawEventFinalized;
        address raffleDrawWinner;
    }

    struct PriceCategory {
        uint256 regularPrice;
        uint256 vipPrice;
    }

    enum EventStatus {
        Pending,
        Active,
        Ongoing,
        Ended
    }

    mapping(address => EventDetails) public eventsMapping;
    mapping(uint256 => EventDetails) public eventsId;
    mapping(address => mapping(uint256 => EventParticipant)) public eventGoers;
    mapping(bytes32 => bool) public pendingRequestIds;
    mapping(uint256 => bytes32) public eventRequestIds;
    mapping(bytes32 => uint256) public eventFufilledIds;
    mapping(uint256 => RaffleDrawInfo) public raffleDrawInfoMapping;

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
    error RequestIdNotFufilled();
    error raffleDrawEventNotFinalized();

    address public constant airnodeAddress = 0x6238772544f029ecaBfDED4300f13A3c4FE84E1D;
    bytes32 public constant endpointId = 0x94555f83f1addda23fdaa7c74f27ce2b764ed5cc430c66f5ff1bcf39d583da36;
    address payable public sponsorWallet;

    uint256 totalBalance;
    uint256 eventsID;

    // uint256 raffleDrawEventCreationPrice = 1e18;
    // uint256 normalEventCreationPrice = 0.5e18;

    uint256 raffleDrawEventCreationPrice = 0.0001 ether;
    uint256 normalEventCreationPrice = 0.00005 ether;

    modifier onlyCreator(uint256 _eventId) {
        if (eventsId[_eventId].creator != msg.sender) revert NotCreator();
        _;
    }

    constructor(address _airnodeRrpAddress) RrpRequesterV0(_airnodeRrpAddress) Ownable(msg.sender) {}

    function createEvent(
        string memory _name,
        string memory _location,
        // uint256 _endingDate,
        // uint256 _startDate,
        bool _raffleDraw,
        uint256 _rafflePrice,
        uint256 _regularPrice,
        uint256 _vipPrice
    ) external payable {
        EventDetails storage eventDetails = eventsMapping[msg.sender];

        if (eventDetails.creator == msg.sender && eventDetails.endingDate < block.timestamp) {
            revert AlreadyHaveActiveEvent(_name);
        }
        if (msg.value < normalEventCreationPrice && !_raffleDraw) {
            revert InsufficientFeeForNonRaffleEvent();
        }
        if (msg.value < raffleDrawEventCreationPrice && _raffleDraw) {
            revert InsufficientFeeForRaffleEvent();
        }
        // if (_endingDate < block.timestamp || _startDate < block.timestamp) {
        //     revert PastDate();
        // }
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

        // eventsId[eventsID] = eventDetails;

        eventDetails.creator = msg.sender;
        eventDetails.name = _name;
        eventDetails.location = _location;
        eventDetails.startDate = block.timestamp + 1 minutes;
        eventDetails.raffleDraw = _raffleDraw;
        eventDetails.rafflePrice = _rafflePrice;
        eventDetails.price.regularPrice = _regularPrice;
        eventDetails.price.vipPrice = _vipPrice;
        eventDetails.endingDate = block.timestamp + 1 hours;
        eventDetails.status = EventStatus.Pending;

        eventsId[eventsID] = eventDetails;

        totalBalance += msg.value;
    }

    function startEvent() public {
        EventDetails storage eventDetails = eventsMapping[msg.sender];
        if (eventDetails.creator != msg.sender) {
            revert NotCreator();
        }
        // if (eventDetails.startDate < block.timestamp) {
        //     revert StartingTimeHasnotReached();
        // }
        if (eventDetails.startDate > block.timestamp) {
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

    function endEvent(uint256 _eventId) external {
        EventDetails storage eventDetails = eventsId[_eventId];

        if (eventDetails.creator != msg.sender) {
            revert NotCreator();
        }
        // if (eventDetails.startDate < block.timestamp) {
        //     revert EventHasnotStarted();
        // }
        if (eventDetails.startDate > block.timestamp) {
            revert EventHasnotStarted();
        }
        // if (eventDetails.startDate > block.timestamp && eventDetails.endingDate < block.timestamp) {
        //     revert EventOngoing();
        // }
        if (eventDetails.startDate < block.timestamp && eventDetails.endingDate > block.timestamp) {
            revert EventOngoing();
        }
        
        if (eventDetails.raffleDraw && !eventDetails.raffleDrawEnd) {
            revert RaffleDrawNotEnded();
        }

        //add function to send out event tickets money to event creator (MAYOWA)
        if (
            eventDetails.status == EventStatus.Pending && eventDetails._eventParticipants.length > 0
                || eventDetails._raffleDrawParticipants.length > 0
        ) {
            if (eventDetails._eventParticipants.length > 0) {
                for (uint256 i; i < eventDetails._eventParticipants.length; i++) {
                    if (
                        keccak256(abi.encodePacked(eventDetails._eventParticipants[i].ticketType))
                            == keccak256(abi.encodePacked(("Regular")))
                    ) {
                        eventDetails.totalBalance -= eventDetails.price.regularPrice;
                        payable(eventDetails._eventParticipants[i]._eventParticipant).call{
                            value: eventDetails.price.regularPrice
                        }("");
                    }
                    if (
                        keccak256(abi.encodePacked(eventDetails._eventParticipants[i].ticketType))
                            == keccak256(abi.encodePacked(("VIP")))
                    ) {
                        eventDetails.totalBalance -= eventDetails.price.vipPrice;
                        payable(eventDetails._eventParticipants[i]._eventParticipant).call{
                            value: eventDetails.price.vipPrice
                        }("");
                    }
                }
            }
            if (eventDetails._raffleDrawParticipants.length > 0) {
                for (uint256 i; i < eventDetails._raffleDrawParticipants.length; i++) {
                    eventDetails.totalBalance -= eventDetails.rafflePrice;
                    payable(eventDetails._eventParticipants[i]._eventParticipant).call{value: eventDetails.rafflePrice}(
                        ""
                    );
                }
            }
        }
        uint256 _totalBalance = eventDetails.totalBalance;
        eventDetails.totalBalance = 0;
        payable(eventDetails.creator).call{value: _totalBalance}("");

        eventDetails.status = EventStatus.Ended;
    }

    function buyEventTicket(uint256 _eventId) external payable {
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

    function buyEventRaffleDraw(uint256 _eventId) external payable {
        EventDetails storage eventDetails = eventsId[_eventId];
        EventParticipant storage _participant = eventGoers[msg.sender][_eventId];

        if (_eventId > eventsID) {
            revert InvalidEvent();
        }
        if (eventDetails.status == EventStatus.Ended) {
            revert EventEnded();
        }
        if (!eventDetails.raffleDraw) {
            revert NotRaffleEvent();
        }
        if (keccak256(abi.encodePacked(_participant.ticketType)) == keccak256(abi.encodePacked(("")))) {
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

    function getEvent() public view returns (EventDetails memory _event) {
        EventDetails storage eventDetails = eventsMapping[msg.sender];
        _event = eventDetails;
    }

    function normalEventParticipants(uint256 _eventId)
        public
        view
        returns (EventParticipant[] memory eventParticipants)
    {
        if (eventsId[_eventId].startDate > block.timestamp) {
            revert EventHasnotStarted();
        }
        eventParticipants = eventsId[_eventId]._eventParticipants;
    }

    function raffleDrawParticipants(uint256 _eventId)
        public
        view
        returns (EventParticipant[] memory _raffleDrawParticipants)
    {
        if (eventsId[_eventId].startDate > block.timestamp) {
            revert EventHasnotStarted();
        }
        _raffleDrawParticipants = eventsId[_eventId]._eventParticipants;
    }

    function getRaffleDrawWinner(uint256 _eventId) public view returns (address _raffleWinner) {
        if (!raffleDrawInfoMapping[_eventId].raffleDrawEventFinalized) revert raffleDrawEventNotFinalized();
        _raffleWinner = raffleDrawInfoMapping[_eventId].raffleDrawWinner;
    }

    function setSponsorWallet(address payable _sponsorWallet) external onlyOwner {
        sponsorWallet = _sponsorWallet;
    }

    function startRaffleDraw(uint256 _eventId) external payable onlyCreator(_eventId) {
        if (eventsId[_eventId].startDate > block.timestamp) {
            revert EventHasnotStarted();
        }
        require(msg.value >= 0.001 ether, "Please top up sponsor wallet"); // user needs to send 0.01 ether with the transaction
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnodeAddress, endpointId, address(this), sponsorWallet, address(this), this.fufillRaffleDraw.selector, ""
        );
        pendingRequestIds[requestId] = true;
        eventRequestIds[_eventId] = requestId;
        emit RequestedRandomNumber(requestId);
        sponsorWallet.call{value: msg.value}(""); // Send funds to sponsor wallet
    }

    function fufillRaffleDraw(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp {
        require(pendingRequestIds[requestId], "No such request made");
        delete pendingRequestIds[requestId];
        uint256 _randomNumber = abi.decode(data, (uint256));
        eventFufilledIds[requestId] = _randomNumber;
        emit ReceivedRandomNumber(requestId, _randomNumber);
    }

    function endRaffleDraw(uint256 _eventId, bytes32 _requestId) external onlyCreator(_eventId) {
        if (eventsId[_eventId].startDate > block.timestamp) revert EventHasnotStarted();
        if (pendingRequestIds[_requestId]) revert RequestIdNotFufilled();
        EventDetails storage eventDetails = eventsId[_eventId];
        RaffleDrawInfo memory raffleDrawInfo = raffleDrawInfoMapping[_eventId];
        uint256 maxIndex = eventDetails._raffleDrawParticipants.length;
        uint256 raffleWinnerIndex = eventFufilledIds[_requestId] % maxIndex;
        address raffleWinner = eventDetails._raffleDrawParticipants[raffleWinnerIndex]._eventParticipant;
        uint256 totalRafflePrice = eventDetails.totalRafflePrice;
        eventDetails.raffleDrawEnd = true;
        raffleDrawInfo.raffleDrawEventFinalized = true;
        raffleDrawInfo.raffleDrawWinner = raffleWinner;
        eventDetails.totalRafflePrice = 0;
        payable(raffleWinner).call{value: totalRafflePrice}("");
    }
    
}
