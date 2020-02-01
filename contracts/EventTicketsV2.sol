pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    // DO I HAVE TO DECLARE IT PUBLIC?
    address payable public owner;

    uint   TICKET_PRICE = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }




    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);


    modifier isEventOpen (uint _eventId) {
        require (
            events[_eventId].isOpen,
            "Event is closed"
        );
        _;
    }
    modifier paidEnough (uint _nTickets) {
        require (
            msg.value >= TICKET_PRICE * _nTickets,
            "Not enough money"
        );
        _;
    }
    modifier enoughTixAvail (uint _eventId, uint _nTickets) {
        require (
            events[_eventId].totalTickets >= _nTickets,
            "Not enough tickets available"
        );
        _;
    }
    modifier paidTooMuch (uint _nTickets) {
        _;
        uint _refundAmount = msg.value - TICKET_PRICE * _nTickets;
        if (_refundAmount > 0) { msg.sender.transfer(_refundAmount); }
    }

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier isOwner () {
        require (
            msg.sender == owner,
            "Caller is not the owner"
            );
            _;
    }

    modifier boughtTickets (uint _eventId) {
        require (
            getBuyerNumberTickets(_eventId) > 0,
            "Buyer doesn't have any tickets"
        );
        _;
    }    

    /* The assignment didn't ask for a constructor but here it is */
    constructor() public {
        owner = msg.sender;
        idGenerator = 0;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _description, string memory _website, uint _totalTickets) 
    public 
    isOwner()
    returns(uint)
    {
        events[idGenerator].description = _description;
        events[idGenerator].website = _website;
        events[idGenerator].totalTickets = _totalTickets;
        events[idGenerator].isOpen = true;
        events[idGenerator].sales = 0;
        emit LogEventAdded (_description,_website, _totalTickets, idGenerator);
        return idGenerator++;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent (uint _eventId)
    public
    view
    returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen)
    {
        description = events[_eventId].description;
        website = events[_eventId].website;
        totalTickets = events[_eventId].totalTickets;
        sales = events[_eventId].sales;
        isOpen = events[_eventId].isOpen;
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint _eventId, uint _nTickets)
    public
    payable
    isEventOpen (_eventId)
    paidEnough (_nTickets)
    enoughTixAvail (_eventId, _nTickets)
    paidTooMuch (_nTickets)
    {
        events[_eventId].buyers[msg.sender] += _nTickets;
        events[_eventId].totalTickets -= _nTickets;
        events[_eventId].sales += _nTickets;
        emit LogBuyTickets (msg.sender, _eventId, _nTickets);
    }
    


    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _eventId)
    external
    payable
    boughtTickets(_eventId)
    {
        uint _nTickets = getBuyerNumberTickets(_eventId);
        events[_eventId].totalTickets += _nTickets;
        events[_eventId].sales -= _nTickets;
        events[_eventId].buyers[msg.sender] = 0;
        msg.sender.transfer(TICKET_PRICE * _nTickets);
        emit LogGetRefund (msg.sender, _eventId, _nTickets);
    }


    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _eventId)
    public
    view
    returns(uint _nTickets)
    {
        _nTickets = events[_eventId].buyers[msg.sender];
    }



    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    // IS IT A GOOD PRACTICE TO DECLARE THIS ONE EXTERNAL? SHOULD IT BE PAYABLE IF IS ONLY SENDING?
    function endSale(uint _eventId)
    external
    isOwner()
    isEventOpen(_eventId)
    {
        uint _balance = address(this).balance;
        events[_eventId].isOpen = false;
        owner.transfer(_balance);
        emit LogEndSale(msg.sender, _balance, _eventId);
    }


}