 

pragma solidity ^0.4.24;

contract EthCalendar {
     
    uint256 constant initialDayPrice = 3000000000000000 wei;

     
    address contractOwner;

     
    mapping(address => uint256) pendingWithdrawals;

     
    mapping(uint16 => Day) dayStructs;

     
    event DayBought(uint16 dayId);

     
    struct Day {
        address owner;
        string message;
        uint256 sellprice;
        uint256 buyprice;
    }

     
    constructor() public {
        contractOwner = msg.sender;
    }

     
    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "sender must be contract owner");
        _;
    }

     
    modifier onlyValidDay (uint16 dayId) {
        require(dayId >= 0 && dayId <= 365, "day id must be between 0 and 365");
        _;
    }

     
    modifier onlyDayOwner(uint16 dayId) {
        require(msg.sender == dayStructs[dayId].owner, "sender must be owner of day");
        _;
    }

     
    modifier notDayOwner(uint16 dayId) {
        require(msg.sender != dayStructs[dayId].owner, "sender can't be owner of day");
        _;
    }

     
    modifier onlyValidMessage(string message) {
        require(bytes(message).length > 0, "message has to be set");
        _;
    }

     
     
     
    modifier onlyValidSellprice(uint256 sellprice, uint256 baseprice) {
         
        require(sellprice > 0 && sellprice <= baseprice * 2, "new sell price must be lower than or equal to twice the paid price");
        _;
    }

     
    modifier onlySufficientPayment(uint16 dayId) {
         
         
        require(msg.value >= getCurrentPrice(dayId), "tx value must be greater than or equal to price of day");
        _;
    }

     
     
     
     
    function buyDay(uint16 dayId, uint256 sellprice, string message) public payable
        onlyValidDay(dayId)
        notDayOwner(dayId)
        onlyValidMessage(message)
        onlySufficientPayment(dayId)
        onlyValidSellprice(sellprice, msg.value) {

        if (hasOwner(dayId)) {
             
             
            uint256 contractOwnerCut = (msg.value * 200) / 10000;
            uint256 dayOwnerShare = msg.value - contractOwnerCut;

             
            pendingWithdrawals[contractOwner] += contractOwnerCut;
            pendingWithdrawals[dayStructs[dayId].owner] += dayOwnerShare;
        } else {
             
             
            pendingWithdrawals[contractOwner] += msg.value;
        }

         
        dayStructs[dayId].owner = msg.sender;
        dayStructs[dayId].message = message;
        dayStructs[dayId].sellprice = sellprice;
        dayStructs[dayId].buyprice = msg.value;

        emit DayBought(dayId);
    }

     
    function changePrice(uint16 dayId, uint256 sellprice) public
        onlyValidDay(dayId)
        onlyDayOwner(dayId)
        onlyValidSellprice(sellprice, dayStructs[dayId].buyprice) {
        dayStructs[dayId].sellprice = sellprice;
    }

     
    function changeMessage(uint16 dayId, string message) public
        onlyValidDay(dayId)
        onlyDayOwner(dayId)
        onlyValidMessage(message) {
        dayStructs[dayId].message = message;
    }

     
    function transferDay(uint16 dayId, address recipient) public
        onlyValidDay(dayId)
        onlyDayOwner(dayId) {
        dayStructs[dayId].owner = recipient;
    }

     
    function getDay (uint16 dayId) public view
        onlyValidDay(dayId)
    returns (uint16 id, address owner, string message, uint256 sellprice, uint256 buyprice) {
        return(  
            dayId,
            dayStructs[dayId].owner,
            dayStructs[dayId].message,
            getCurrentPrice(dayId),
            dayStructs[dayId].buyprice
        );    
    }

     
    function getBalance() public view
    returns (uint256 amount) {
        return pendingWithdrawals[msg.sender];
    }

     
    function withdraw() public {
        uint256 amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

     
    function hasOwner(uint16 dayId) private view
    returns (bool dayHasOwner) {
        return dayStructs[dayId].owner != address(0);
    }

     
    function getCurrentPrice(uint16 dayId) private view
    returns (uint256 currentPrice) {
        return hasOwner(dayId) ?
            dayStructs[dayId].sellprice :
            initialDayPrice;
    }
}