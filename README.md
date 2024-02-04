# Event Management
This repository contains an event management system with these key functionalities.
1. A platform to create events
2. An avenue for users to buy ticket for events you have created
3. An avenue to add raffle draws to events you have created
4. Use of Random Number Generation to determine who wins an event raffle draw.
5. Ability to transfer ticket bought to another user.

## MOTIVATION
The motivation behind building this project was to provide a practical solution to a real-world problem using blockchain technology. By adhering to the challenge requirements, this project aims to demonstrate the potential of dApps in event management.

## TECHNOLOGIES USED
- **Solidity:** This is the primary programming language for writing smart contracts on the Ethereum blockchain. It was used because of its robust features for developing secure and efficient contracts.

- **Airnode/contracts:** This is a set of smart contracts for the Airnode protocol, which allows smart contracts to interact with regular APIs. It was used to enable the contract to make requests to Airnode-enabled APIs.

- **OpenZeppelin/contracts:** This is a library for secure smart contract development on Ethereum and other EVM-compatible blockchains. It provides implementations of standards like ERC20 and ERC721 which you can deploy as-is or extend to suit your needs, as well as Solidity components to build custom contracts and more complex decentralized systems. The Ownable contract was used to provide basic authorization control functions.

- **LightLink Chain:** This is the blockchain where the event management contract was deployed. Selected for its interoperability and performance. Lightlink is the best choice for this contract deployment.

- **Blockscout:** This is the platform used for verifying the contract and for adding private and public tasks.

- **Forward**: This is the platform for creating the frontend application. Forward provides a friendly interface for developing decentralized applications. It's ease of use, customization and seamless integration with various blockchains makes it a desirable choice for this project.

## SMART CONTRACT OVERVIEW
The following are functions used to implement the event management system.
- The `createEvent` function to create a new event.
- The `startEvent` function to start the event.
- The `buyEventTicket` function to buy a ticket for the event.
- If the event is a raffle draw, call the `buyEventRaffleDraw` function to buy a raffle draw ticket.
- The `startRaffleDraw` function to start the raffle draw.
- The `endRaffleDraw` function to end the raffle draw and determine the winner.
- The `endEvent` function to end the event.

## SMART CONTRACT DETAIL
The smart contract `Events` is a contract for managing events, including the creation of events, buying tickets, and conducting raffle draws.

The smart contract Events inherits from RrpRequesterV0 and Ownable. RrpRequesterV0 is a contract from the Airnode protocol, which enables the contract to make requests to Airnode-enabled APIs. Ownable is a contract from the OpenZeppelin library that provides basic authorization control functions.

The contract includes several structs to manage event details, participants, raffle draw information, and price categories. It also includes an enum to manage the status of events.

Mappings are used to manage events, participants, and raffle draw information. The contract also includes several error types to handle various error conditions.

The contract includes a constructor that sets the Airnode RRP address and the owner of the contract.

The contract includes several functions to manage events, including creating events, starting and ending events, buying tickets, and conducting raffle draws. It also includes view functions to get event details and participants.

These functions are defined in the contract:

1. **createEvent**: This function allows a user to create an event. The user provides details such as the event name, location, whether it's a raffle draw, the raffle price, and the prices for regular and VIP tickets. The function checks if the user already has an active event and if the correct fee has been paid. It then stores the event details in the `eventsMapping` and `eventsId` mappings.

2. **startEvent**: This function allows the creator of an event to start it. It checks if the event's start date has been reached and if the event is not already active or ended. It then sets the event's status to `Active`.

3. **endEvent**: This function allows the creator of an event to end it. It checks if the event's start date has been reached, if the event is ongoing, and if the raffle draw (if any) has ended. It then sets the event's status to `Ended` and transfers the total balance of the event to the creator.

4. **buyEventTicket**: This function allows a user to buy a ticket for an event. The user provides the event ID and the payment. The function checks if the event is valid and if the correct price has been paid for the ticket. It then updates the event's total balance and stores the participant's details in the `eventGoers` and `_eventParticipants` mappings.

5. **buyEventRaffleDraw**: This function allows a user to buy a raffle draw ticket for an event. The user provides the event ID and the payment. The function checks if the event is valid, if it's a raffle event, and if the correct price has been paid for the ticket. It then updates the event's total raffle price and stores the participant's details in the `_raffleDrawParticipants` mapping.

6. **getEvent**: This function allows a user to get the details of an event they created. It returns the event details from the `eventsMapping` mapping.

7. **normalEventParticipants**: This function allows a user to get the participants of an event. It checks if the event has started and then returns the participants from the `_eventParticipants` mapping.

8. **raffleDrawParticipants**: This function allows a user to get the raffle draw participants of an event. It checks if the event has started and then returns the participants from the `_raffleDrawParticipants` mapping.

9. **getRaffleDrawWinner**: This function allows a user to get the winner of a raffle draw for an event. It checks if the raffle draw event has been finalized and then returns the winner from the `raffleDrawInfoMapping` mapping.

10. **setSponsorWallet**: This function allows the owner of the contract to set the sponsor wallet address. It updates the `sponsorWallet` state variable.

11. **startRaffleDraw**: This function allows the creator of an event to start a raffle draw. The user provides the event ID and the payment. The function checks if the event has started and if the correct fee has been paid. It then makes a request to the Airnode oracle and emits a `RequestedRandomNumber` event.

12. **fufillRaffleDraw**: This function is called by the Airnode oracle to fulfill a raffle draw request. It checks if the request is valid and then stores the random number provided by the oracle in the `eventFufilledIds` mapping and emits a `ReceivedRandomNumber` event.

13. **endRaffleDraw**: This function allows the creator of an event to end a raffle draw. The user provides the event ID and the request ID. The function checks if the event has started and if the request has been fulfilled. It then calculates the winner of the raffle draw, updates the `raffleDrawInfoMapping` mapping, and transfers the total raffle price to the winner.


## WHY QRNG?
Once an event is created, a raffle draw can be created for that event. The winner of the raffle draw is determined using a random number generator which is provided using the airnode library used in the smart contract and shown in the technologies used section above.

## REWARDS
There are rewards for users who use this event and ticketing platform.
1. Users that purchase event ticket get rewarded an NFT once an event ends.
2. The User who wins the raffle draw based on the Random Number Generator is rewarded the total amount deposited to the raffle draw pool.


