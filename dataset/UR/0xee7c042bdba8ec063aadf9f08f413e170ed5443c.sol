 

pragma solidity 0.5.6;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    uint8 public decimals;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract DAIHardFactory {
    event NewTrade(uint id, address tradeAddress, bool indexed initiatorIsPayer);

    ERC20Interface public daiContract;
    address payable public devFeeAddress;

    constructor(ERC20Interface _daiContract, address payable _devFeeAddress)
    public {
        daiContract = _daiContract;
        devFeeAddress = _devFeeAddress;
    }

    struct CreationInfo {
        address address_;
        uint blocknum;
    }

    CreationInfo[] public createdTrades;

    function getBuyerDeposit(uint tradeAmount)
    public
    pure
    returns (uint buyerDeposit) {
        return tradeAmount / 3;
    }

    function getDevFee(uint tradeAmount)
    public
    pure
    returns (uint devFee) {
        return tradeAmount / 100;
    }

    function getExtraFees(uint tradeAmount)
    public
    pure
    returns (uint buyerDeposit, uint devFee) {
        return (getBuyerDeposit(tradeAmount), getDevFee(tradeAmount));
    }

     

    function openDAIHardTrade(address payable _initiator, bool initiatorIsBuyer, uint[5] calldata uintArgs, string calldata _totalPrice, string calldata _fiatTransferMethods, string calldata _commPubkey)
    external
    returns (DAIHardTrade) {
        uint transferAmount;
        uint[6] memory newUintArgs;  

        if (initiatorIsBuyer) {
             
            transferAmount = SafeMath.add(SafeMath.add(getBuyerDeposit(uintArgs[0]), uintArgs[1]), getDevFee(uintArgs[0]));

            newUintArgs = [uintArgs[0], uintArgs[1], getDevFee(uintArgs[0]), uintArgs[2], uintArgs[3], uintArgs[4]];
        }
        else {
             
            transferAmount = SafeMath.add(SafeMath.add(uintArgs[0], uintArgs[1]), getDevFee(uintArgs[0]));

            newUintArgs = [getBuyerDeposit(uintArgs[0]), uintArgs[1], getDevFee(uintArgs[0]), uintArgs[2], uintArgs[3], uintArgs[4]];
        }

         
        DAIHardTrade newTrade = new DAIHardTrade(daiContract, devFeeAddress);
        createdTrades.push(CreationInfo(address(newTrade), block.number));
        emit NewTrade(createdTrades.length - 1, address(newTrade), initiatorIsBuyer);

         
        require(daiContract.transferFrom(msg.sender, address(newTrade), transferAmount), "Token transfer failed. Did you call approve() on the DAI contract?");
        newTrade.open(_initiator, initiatorIsBuyer, newUintArgs, _totalPrice, _fiatTransferMethods, _commPubkey);

        return newTrade;
    }

    function getNumTrades()
    external
    view
    returns (uint num) {
        return createdTrades.length;
    }
}

contract DAIHardTrade {
    enum Phase {Created, Open, Committed, Claimed, Closed}
    Phase public phase;

    modifier inPhase(Phase p) {
        require(phase == p, "inPhase check failed.");
        _;
    }

    enum ClosedReason {NotClosed, Recalled, Aborted, Released, Burned}
    ClosedReason public closedReason;

    uint[5] public phaseStartTimestamps;
    uint[5] public phaseStartBlocknums;

    function changePhase(Phase p)
    internal {
        phase = p;
        phaseStartTimestamps[uint(p)] = block.timestamp;
        phaseStartBlocknums[uint(p)] = block.number;
    }


    address payable public initiator;
    address payable public responder;

     
     

    bool public initiatorIsBuyer;
    address payable public buyer;
    address payable public seller;

    modifier onlyInitiator() {
        require(msg.sender == initiator, "msg.sender is not Initiator.");
        _;
    }
    modifier onlyResponder() {
        require(msg.sender == responder, "msg.sender is not Responder.");
        _;
    }
    modifier onlyBuyer() {
        require (msg.sender == buyer, "msg.sender is not Buyer.");
        _;
    }
    modifier onlySeller() {
        require (msg.sender == seller, "msg.sender is not Seller.");
        _;
    }
    modifier onlyContractParty() {  
        require(msg.sender == initiator || msg.sender == responder, "msg.sender is not a party in this contract.");
        _;
    }

    ERC20Interface daiContract;
    address payable devFeeAddress;

    constructor(ERC20Interface _daiContract, address payable _devFeeAddress)
    public {
        changePhase(Phase.Created);
        closedReason = ClosedReason.NotClosed;

        daiContract = _daiContract;
        devFeeAddress = _devFeeAddress;

        pokeRewardSent = false;
    }

    uint public daiAmount;
    string public price;
    uint public buyerDeposit;

    uint public responderDeposit;  

    uint public autorecallInterval;
    uint public autoabortInterval;
    uint public autoreleaseInterval;

    uint public pokeReward;
    uint public devFee;

    bool public pokeRewardSent;

     

    event Opened(string fiatTransferMethods, string commPubkey);

     

    function open(address payable _initiator, bool _initiatorIsBuyer, uint[6] memory uintArgs, string memory _price, string memory fiatTransferMethods, string memory commPubkey)
    public
    inPhase(Phase.Created) {
        require(getBalance() > 0, "You can't open a trade without first depositing DAI.");

        responderDeposit = uintArgs[0];
        pokeReward = uintArgs[1];
        devFee = uintArgs[2];

        autorecallInterval = uintArgs[3];
        autoabortInterval = uintArgs[4];
        autoreleaseInterval = uintArgs[5];

        initiator = _initiator;
        initiatorIsBuyer = _initiatorIsBuyer;
        if (initiatorIsBuyer) {
            buyer = initiator;
            daiAmount = responderDeposit;
            buyerDeposit = SafeMath.sub(getBalance(), SafeMath.add(pokeReward, devFee));
        }
        else {
            seller = initiator;
            daiAmount = SafeMath.sub(getBalance(), SafeMath.add(pokeReward, devFee));
            buyerDeposit = responderDeposit;
        }

        price = _price;

        changePhase(Phase.Open);
        emit Opened(fiatTransferMethods, commPubkey);
    }

     

    event Recalled();
    event Committed(address responder, string commPubkey);


    function recall()
    external
    inPhase(Phase.Open)
    onlyInitiator() {
       internalRecall();
    }

    function internalRecall()
    internal {
        require(daiContract.transfer(initiator, getBalance()), "Recall of DAI to initiator failed!");

        changePhase(Phase.Closed);
        closedReason = ClosedReason.Recalled;

        emit Recalled();
    }

    function autorecallAvailable()
    public
    view
    inPhase(Phase.Open)
    returns(bool available) {
        return (block.timestamp >= SafeMath.add(phaseStartTimestamps[uint(Phase.Open)], autorecallInterval));
    }

    function commit(string calldata commPubkey)
    external
    inPhase(Phase.Open) {
        require(daiContract.transferFrom(msg.sender, address(this), responderDeposit), "Can't transfer the required deposit from the DAI contract. Did you call approve first?");
        require(!autorecallAvailable(), "autorecallInterval has passed; this offer has expired.");

        responder = msg.sender;

        if (initiatorIsBuyer) {
            seller = responder;
        }
        else {
            buyer = responder;
        }

        changePhase(Phase.Committed);
        emit Committed(responder, commPubkey);
    }

     

    event Claimed();
    event Aborted();

    function abort()
    external
    inPhase(Phase.Committed)
    onlyBuyer() {
        internalAbort();
    }

    function internalAbort()
    internal {
         
         
         
        uint burnAmount = buyerDeposit / 4;

         
         
        require(daiContract.transfer(address(0x0), burnAmount*2), "Token burn failed!");

         
        require(daiContract.transfer(buyer, SafeMath.sub(buyerDeposit, burnAmount)), "Token transfer to Buyer failed!");
        require(daiContract.transfer(seller, SafeMath.sub(daiAmount, burnAmount)), "Token transfer to Seller failed!");

        uint sendBackToInitiator = devFee;
         
        if (!pokeRewardSent) {
            sendBackToInitiator = SafeMath.add(sendBackToInitiator, pokeReward);
        }
        
        require(daiContract.transfer(initiator, sendBackToInitiator), "Token refund of devFee+pokeReward to Initiator failed!");
        
         

        changePhase(Phase.Closed);
        closedReason = ClosedReason.Aborted;

        emit Aborted();
    }

    function autoabortAvailable()
    public
    view
    inPhase(Phase.Committed)
    returns(bool passed) {
        return (block.timestamp >= SafeMath.add(phaseStartTimestamps[uint(Phase.Committed)], autoabortInterval));
    }

    function claim()
    external
    inPhase(Phase.Committed)
    onlyBuyer() {
        require(!autoabortAvailable(), "The deposit deadline has passed!");

        changePhase(Phase.Claimed);
        emit Claimed();
    }

     

    event Released();
    event Burned();

    function release()
    external
    inPhase(Phase.Claimed)
    onlySeller() {
        internalRelease();
    }

    function internalRelease()
    internal {
         
        if (!pokeRewardSent) {
            require(daiContract.transfer(initiator, pokeReward), "Refund of pokeReward to Initiator failed!");
        }

         
        require(daiContract.transfer(devFeeAddress, devFee), "Token transfer to devFeeAddress failed!");

         
        require(daiContract.transfer(buyer, getBalance()), "Final release transfer to buyer failed!");

        changePhase(Phase.Closed);
        closedReason = ClosedReason.Released;

        emit Released();
    }

    function autoreleaseAvailable()
    public
    view
    inPhase(Phase.Claimed)
    returns(bool available) {
        return (block.timestamp >= SafeMath.add(phaseStartTimestamps[uint(Phase.Claimed)], autoreleaseInterval));
    }

    function burn()
    external
    inPhase(Phase.Claimed)
    onlySeller() {
        require(!autoreleaseAvailable());

        internalBurn();
    }

    function internalBurn()
    internal {
        require(daiContract.transfer(address(0x0), getBalance()), "Final DAI burn failed!");

        changePhase(Phase.Closed);
        closedReason = ClosedReason.Burned;

        emit Burned();
    }

     

    function getState()
    external
    view
    returns(uint balance, Phase phase, uint phaseStartTimestamp, address responder, ClosedReason closedReason) {
        return (getBalance(), this.phase(), phaseStartTimestamps[uint(this.phase())], this.responder(), this.closedReason());
    }

    function getBalance()
    public
    view
    returns(uint) {
        return daiContract.balanceOf(address(this));
    }

    function getParameters()
    external
    view
    returns (address initiator, bool initiatorIsBuyer, uint daiAmount, string memory totalPrice, uint buyerDeposit, uint autorecallInterval, uint autoabortInterval, uint autoreleaseInterval, uint pokeReward)
    {
        return (this.initiator(), this.initiatorIsBuyer(), this.daiAmount(), this.price(), this.buyerDeposit(), this.autorecallInterval(), this.autoabortInterval(), this.autoreleaseInterval(), this.pokeReward());
    }

    function getPhaseStartInfo()
    external
    view
    returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint)
    {
        return (phaseStartBlocknums[0], phaseStartBlocknums[1], phaseStartBlocknums[2], phaseStartBlocknums[3], phaseStartBlocknums[4], phaseStartTimestamps[0], phaseStartTimestamps[1], phaseStartTimestamps[2], phaseStartTimestamps[3], phaseStartTimestamps[4]);
    }

     
     

    event Poke();

    function pokeNeeded()
    public
    view
    returns (bool needed) {
        return (  (phase == Phase.Open      && autorecallAvailable() )
               || (phase == Phase.Committed && autoabortAvailable()  )
               || (phase == Phase.Claimed   && autoreleaseAvailable())
               );
    }

    function poke()
    external 
    returns (bool moved) {
        if (pokeNeeded()) {
            daiContract.transfer(msg.sender, pokeReward);
            pokeRewardSent = true;
            emit Poke();
        }
        else return false;

        if (phase == Phase.Open) {
            if (autorecallAvailable()) {
                internalRecall();
                return true;
            }
        }
        else if (phase == Phase.Committed) {
            if (autoabortAvailable()) {
                internalAbort();
                return true;
            }
        }
        else if (phase == Phase.Claimed) {
            if (autoreleaseAvailable()) {
                internalRelease();
                return true;
            }
        }
    }

     
     


    event InitiatorStatementLog(string encryptedForInitiator, string encryptedForResponder);
    event ResponderStatementLog(string encryptedForInitiator, string encryptedForResponder);

    function initiatorStatement(string memory encryptedForInitiator, string memory encryptedForResponder)
    public
    onlyInitiator() {
        require(phase >= Phase.Committed);
        emit InitiatorStatementLog(encryptedForInitiator, encryptedForResponder);
    }

    function responderStatement(string memory encryptedForInitiator, string memory encryptedForResponder)
    public
    onlyResponder() {
        require(phase >= Phase.Committed);
        emit ResponderStatementLog(encryptedForInitiator, encryptedForResponder);
    }
}