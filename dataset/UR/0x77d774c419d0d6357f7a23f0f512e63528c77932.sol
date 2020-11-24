 

pragma solidity ^0.5.7;

 

contract Master {

    address payable ownerAddress;
    address constant oracleAddress = 0xE8013bD526100Ebf67ace0E0F21a296D8974f0A4;

    mapping (uint => bool) public validDueDate;


    event NewContract (
        address contractAddress
    );


    modifier onlyByOwner () {
        require(msg.sender ==  ownerAddress);
        _;
    }


    constructor () public {
        ownerAddress = msg.sender;
    }


     
    function createConditionalPayment
    (
        address payable creator,
        bool long,
        uint256 dueDate,
        uint256 strikePrice
    )
        payable
        public
        returns(address newDerivativeAddress)
    {
        require(validDueDate[dueDate]);
        ConditionalPayment conditionalPayment = (new ConditionalPayment).value(msg.value)
        (
            creator,
            long,
            dueDate,
            strikePrice
        );

        emit NewContract(address(conditionalPayment));

        return address(conditionalPayment);
    }

     
    function settle
    (
        uint256 dueDate
    )
        public
        payable
        returns (uint256)
    {
        Oracle o = Oracle(oracleAddress);
        return o.sendPrice(dueDate);
    }


     

    function setValidDueDate
    (
        uint dueDate,
        bool valid
    )
        public
        onlyByOwner
    {
        validDueDate[dueDate] = valid;
    }

    function withdrawFees ()
        public
        onlyByOwner
    {
        msg.sender.transfer(address(this).balance);
    }

    function balanceOfFactory ()
        public
        view
        returns (uint256)
    {
        return (address(this).balance);
    }

}



 
contract ConditionalPayment {

    address payable public masterAddress;

    address constant public withdrawFunctionsAddress = 0x0b564F0aD4dcb35Cd43eff2f26Bf96B670eaBF5e;

    address payable public creator;

    uint256 public dueDate;
    uint256 public strikePrice;
    bool public creatorLong;

    uint8 public countCounterparties;

    bool public isSettled;
    uint256 public settlementPrice;

    uint256 public totalStakeCounterparties;

    mapping(address => uint256) public stakes;


    event ContractAltered ();

    event UpdatedParticipant
    (
        address indexed participant,
        uint256 stake
    );


    modifier onlyByCreator()
    {
        require(msg.sender ==  creator);
        _;
    }

    modifier onlyIncremental(uint amount)
    {
        require(amount % (0.1 ether) == 0);
        _;
    }

    modifier nonZeroMsgValue()
    {
        require(msg.value > 0);
        _;
    }

    modifier dueDateInFuture()
    {
        _;
        require(now < dueDate);
    }

    modifier nonZeroStrikePrice(uint256 newStrikePrice)
    {
        require(newStrikePrice > 0);
        _;
    }

    modifier emitsContractAlteredEvent()
    {
        _;
        emit ContractAltered();
    }

    modifier emitsUpdatedParticipantEvent(address participant)
    {
        _;
        emit UpdatedParticipant(participant,stakes[participant]);
    }


    constructor
    (
        address payable _creator,
        bool _long,
        uint256 _dueDate,
        uint256 _strikePrice
    )
        payable
        public
        onlyIncremental(msg.value)
        nonZeroStrikePrice(_strikePrice)
        nonZeroMsgValue
        dueDateInFuture
        emitsUpdatedParticipantEvent(_creator)
    {
        masterAddress = msg.sender;

        creator = _creator;
        creatorLong = _long;
        stakes[creator] = msg.value;

        strikePrice = _strikePrice;
        dueDate = _dueDate;
    }


     
    function changeStrikePrice (uint256 newStrikePrice)
        public
        nonZeroStrikePrice(newStrikePrice)
        onlyByCreator
        emitsContractAlteredEvent
    {
        require(countCounterparties == 0);

        strikePrice = newStrikePrice;
    }


     
    function reduceStake (uint256 amount)
        public
        onlyByCreator
        onlyIncremental(amount)
        emitsContractAlteredEvent
        emitsUpdatedParticipantEvent(creator)
    {
        uint256 maxWithdrawAmount = stakes[msg.sender] - totalStakeCounterparties;
        if(amount < maxWithdrawAmount)
        {
            stakes[msg.sender] -= amount;
            msg.sender.transfer(amount);
        }
        else
        {
            stakes[msg.sender] -= maxWithdrawAmount;
            msg.sender.transfer(maxWithdrawAmount);
        }
    }


     
    function addStake ()
        public
        payable
        onlyByCreator
        onlyIncremental(msg.value)
        emitsContractAlteredEvent
        emitsUpdatedParticipantEvent(creator)
    {
        stakes[msg.sender] += msg.value;
    }


     
    function signContract (uint256 requestedStrikePrice)
        payable
        public
        onlyIncremental(msg.value)
        nonZeroMsgValue
        dueDateInFuture
        emitsContractAlteredEvent
        emitsUpdatedParticipantEvent(msg.sender)
    {
        require(msg.sender != creator);
        require(requestedStrikePrice == strikePrice);
        totalStakeCounterparties += msg.value;
        require(totalStakeCounterparties <= stakes[creator]);

        if (stakes[msg.sender] == 0)
        {
            countCounterparties += 1;
        }
        stakes[msg.sender] += msg.value;
    }


     
    function withdraw ()
        public
        emitsContractAlteredEvent
    {
        require(now > dueDate);
        require(countCounterparties > 0);

        if (isSettled == false)
        {
            Master m = Master(masterAddress);
            settlementPrice = m.settle.value(totalStakeCounterparties/200)(dueDate);
            isSettled = true;
        }

        uint256 stakeMemory = stakes[msg.sender];
        Withdraw w = Withdraw(withdrawFunctionsAddress);
        if (msg.sender == creator)
        {
            stakes[msg.sender] = 0;
            msg.sender.transfer(w.amountCreator(
                creatorLong,
                stakeMemory,
                settlementPrice,
                strikePrice,
                totalStakeCounterparties));
        }
        if (stakes[msg.sender] != 0)
        {
            stakes[msg.sender] = 0;
            msg.sender.transfer(w.amountCounterparty(
                creatorLong,
                stakeMemory,
                settlementPrice,
                strikePrice));
        }
    }


     
    function unsettledWithdraw ()
        public
        emitsContractAlteredEvent
    {
        require (now > dueDate + 90 days);
        require (isSettled == false);

        uint256 stakeMemory = stakes[msg.sender];
        stakes[msg.sender] = 0;
        msg.sender.transfer(stakeMemory);
    }

}




interface Oracle {

    function sendPrice (uint256 dueDate)
        external
        view
        returns (uint256);

}


interface Withdraw {

    function amountCreator
    (
        bool makerLong,
        uint256 stakeMemory,
        uint256 settlementPrice,
        uint256 strikePrice,
        uint256 totalStakeAllTakers
    )
        external
        pure
        returns (uint256);


    function amountCounterparty
    (
        bool makerLong,
        uint256 stakeMemory,
        uint256 settlementPrice,
        uint256 strikePrice
    )
        external
        pure
        returns (uint256);

}