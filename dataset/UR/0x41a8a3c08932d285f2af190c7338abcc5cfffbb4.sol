 

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
    using SafeMath for uint;

    event NewTrade(uint id, address tradeAddress, bool indexed initiatorIsCustodian);

    ERC20Interface public daiContract;
    address public founderFeeAddress;

    constructor(ERC20Interface _daiContract, address _founderFeeAddress)
    public {
        daiContract = _daiContract;
        founderFeeAddress = _founderFeeAddress;
    }

    struct CreationInfo {
        address address_;
        uint blocknum;
    }

    CreationInfo[] public createdTrades;

    function getFounderFee(uint tradeAmount)
    public
    pure
    returns (uint founderFee) {
        return tradeAmount / 200;
    }

     

    function createOpenTrade(address[2] calldata addressArgs,
                             bool initiatorIsCustodian,
                             uint[8] calldata uintArgs,
                             string calldata terms,
                             string calldata _commPubkey
                             )
    external
    returns (DAIHardTrade) {
        uint initialTransfer;
        uint[8] memory newUintArgs;  

        if (initiatorIsCustodian) {
            initialTransfer = uintArgs[0].add(uintArgs[3]).add(getFounderFee(uintArgs[0])).add(uintArgs[7]);
             

            newUintArgs = [uintArgs[1], uintArgs[2], uintArgs[3], uintArgs[4], uintArgs[5], uintArgs[6], getFounderFee(uintArgs[0]), uintArgs[7]];
             
        }
        else {
            initialTransfer = uintArgs[1].add(uintArgs[3]).add(getFounderFee(uintArgs[0])).add(uintArgs[7]);
             

            newUintArgs = [uintArgs[0], uintArgs[2], uintArgs[3], uintArgs[4], uintArgs[5], uintArgs[6], getFounderFee(uintArgs[0]), uintArgs[7]];
             
        }

         
         
         
        DAIHardTrade newTrade = new DAIHardTrade(daiContract, founderFeeAddress, addressArgs[1]);
        createdTrades.push(CreationInfo(address(newTrade), block.number));
        emit NewTrade(createdTrades.length - 1, address(newTrade), initiatorIsCustodian);

         
        require(daiContract.transferFrom(msg.sender, address(newTrade), initialTransfer),
                "Token transfer failed. Did you call approve() on the DAI contract?"
                );
        newTrade.beginInOpenPhase(addressArgs[0], initiatorIsCustodian, newUintArgs, terms, _commPubkey);

        return newTrade;
    }

     

    function createCommittedTrade(address[3] calldata addressArgs,
                                  bool initiatorIsCustodian,
                                  uint[7] calldata uintArgs,
                                  string calldata _terms,
                                  string calldata _initiatorCommPubkey,
                                  string calldata _responderCommPubkey
                                  )
    external
    returns (DAIHardTrade) {
        uint initialTransfer = uintArgs[0].add(uintArgs[1]).add(uintArgs[3]).add(getFounderFee(uintArgs[0]).add(uintArgs[6]));
         

        uint[7] memory newUintArgs = [uintArgs[1], uintArgs[2], uintArgs[3], uintArgs[4], uintArgs[5], getFounderFee(uintArgs[0]), uintArgs[6]];
         

        DAIHardTrade newTrade = new DAIHardTrade(daiContract, founderFeeAddress, addressArgs[2]);
        createdTrades.push(CreationInfo(address(newTrade), block.number));
        emit NewTrade(createdTrades.length - 1, address(newTrade), initiatorIsCustodian);

        require(daiContract.transferFrom(msg.sender, address(newTrade), initialTransfer),
                                         "Token transfer failed. Did you call approve() on the DAI contract?"
                                         );
        newTrade.beginInCommittedPhase(addressArgs[0],
                                       addressArgs[1],
                                       initiatorIsCustodian,
                                       newUintArgs,
                                       _terms,
                                       _initiatorCommPubkey,
                                       _responderCommPubkey
                                       );

        return newTrade;
    }

    function numTrades()
    external
    view
    returns (uint num) {
        return createdTrades.length;
    }
}

contract DAIHardTrade {
    using SafeMath for uint;

    enum Phase {Creating, Open, Committed, Judgment, Closed}
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


    address public initiator;
    address public responder;

     
     
     

    bool public initiatorIsCustodian;
    address public custodian;
    address public beneficiary;

    modifier onlyInitiator() {
        require(msg.sender == initiator, "msg.sender is not Initiator.");
        _;
    }
    modifier onlyResponder() {
        require(msg.sender == responder, "msg.sender is not Responder.");
        _;
    }
    modifier onlyCustodian() {
        require (msg.sender == custodian, "msg.sender is not Custodian.");
        _;
    }
    modifier onlyBeneficiary() {
        require (msg.sender == beneficiary, "msg.sender is not Beneficiary.");
        _;
    }
    modifier onlyContractParty() {  
         
         
        require(msg.sender == initiator || msg.sender == responder, "msg.sender is not a party in this contract.");
        _;
    }

    ERC20Interface public daiContract;
    address public founderFeeAddress;
    address public devFeeAddress;

    bool public pokeRewardGranted;

    constructor(ERC20Interface _daiContract, address _founderFeeAddress, address _devFeeAddress)
    public {
         
         
         

         
         
         

        daiContract = _daiContract;
        founderFeeAddress = _founderFeeAddress;
        devFeeAddress = _devFeeAddress;
    }

    uint public tradeAmount;
    uint public beneficiaryDeposit;
    uint public abortPunishment;

    uint public autorecallInterval;
    uint public autoabortInterval;
    uint public autoreleaseInterval;

    uint public pokeReward;
    uint public founderFee;
    uint public devFee;

     

    event Initiated(string terms, string commPubkey);

     

    function beginInOpenPhase(address _initiator,
                              bool _initiatorIsCustodian,
                              uint[8] memory uintArgs,
                              string memory terms,
                              string memory commPubkey
                              )
    public
    inPhase(Phase.Creating)
      {
        uint responderDeposit = uintArgs[0];
        abortPunishment = uintArgs[1];
        pokeReward = uintArgs[2];

        autorecallInterval = uintArgs[3];
        autoabortInterval = uintArgs[4];
        autoreleaseInterval = uintArgs[5];

        founderFee = uintArgs[6];
        devFee = uintArgs[7];

        initiator = _initiator;
        initiatorIsCustodian = _initiatorIsCustodian;
        if (initiatorIsCustodian) {
            custodian = initiator;
            tradeAmount = getBalance().sub(pokeReward.add(founderFee).add(devFee));
            beneficiaryDeposit = responderDeposit;
        }
        else {
            beneficiary = initiator;
            tradeAmount = responderDeposit;
            beneficiaryDeposit = getBalance().sub(pokeReward.add(founderFee).add(devFee));
        }

        require(beneficiaryDeposit <= tradeAmount, "A beneficiaryDeposit greater than tradeAmount is not allowed.");
        require(abortPunishment <= beneficiaryDeposit, "An abortPunishment greater than beneficiaryDeposit is not allowed.");

        changePhase(Phase.Open);
        emit Initiated(terms, commPubkey);
    }

     

    function beginInCommittedPhase(address _custodian,
                                   address _beneficiary,
                                   bool _initiatorIsCustodian,
                                   uint[7] memory uintArgs,
                                   string memory terms,
                                   string memory initiatorCommPubkey,
                                   string memory responderCommPubkey
                                   )
    public
    inPhase(Phase.Creating)
     {
        beneficiaryDeposit = uintArgs[0];
        abortPunishment = uintArgs[1];
        pokeReward = uintArgs[2];

        autoabortInterval = uintArgs[3];
        autoreleaseInterval = uintArgs[4];

        founderFee = uintArgs[5];
        devFee = uintArgs[6];

        custodian = _custodian;
        beneficiary = _beneficiary;
        initiatorIsCustodian = _initiatorIsCustodian;

        if (initiatorIsCustodian) {
            initiator = custodian;
            responder = beneficiary;
        }
        else {
            initiator = beneficiary;
            responder = custodian;
        }

        tradeAmount = getBalance().sub(beneficiaryDeposit.add(pokeReward).add(founderFee).add(devFee));

        require(beneficiaryDeposit <= tradeAmount, "A beneficiaryDeposit greater than tradeAmount is not allowed.");
        require(abortPunishment <= beneficiaryDeposit, "An abortPunishment greater than beneficiaryDeposit is not allowed.");

        changePhase(Phase.Committed);

        emit Initiated(terms, initiatorCommPubkey);
        emit Committed(responder, responderCommPubkey);
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
        changePhase(Phase.Closed);
        closedReason = ClosedReason.Recalled;

        emit Recalled();

        require(daiContract.transfer(initiator, getBalance()), "Recall of DAI to initiator failed!");
         
         
    }

    function autorecallAvailable()
    public
    view
    inPhase(Phase.Open)
    returns(bool available) {
        return (block.timestamp >= phaseStartTimestamps[uint(Phase.Open)].add(autorecallInterval));
    }

    function commit(address _responder, string calldata commPubkey)
    external
    inPhase(Phase.Open)
      {
        require(!autorecallAvailable(), "autorecallInterval has passed; this offer has expired.");

        responder = _responder;

        if (initiatorIsCustodian) {
            beneficiary = responder;
        }
        else {
            custodian = responder;
        }

        changePhase(Phase.Committed);
        emit Committed(responder, commPubkey);

        require(daiContract.transferFrom(msg.sender, address(this), getResponderDeposit()),
                                         "Can't transfer the required deposit from the DAI contract. Did you call approve first?"
                                         );
    }

     

    event Claimed();
    event Aborted();

    function abort()
    external
    inPhase(Phase.Committed)
    onlyBeneficiary() {
        internalAbort();
    }

    function internalAbort()
    internal {
        changePhase(Phase.Closed);
        closedReason = ClosedReason.Aborted;

        emit Aborted();

         
         
        require(daiContract.transfer(address(0x0), abortPunishment*2), "Token burn failed!");
         
         
         
         

         
        require(daiContract.transfer(beneficiary, beneficiaryDeposit.sub(abortPunishment)), "Token transfer to Beneficiary failed!");
        require(daiContract.transfer(custodian, tradeAmount.sub(abortPunishment)), "Token transfer to Custodian failed!");

         
        uint sendBackToInitiator = founderFee.add(devFee);
         
        if (!pokeRewardGranted) {
            sendBackToInitiator = sendBackToInitiator.add(pokeReward);
        }

        require(daiContract.transfer(initiator, sendBackToInitiator), "Token refund of founderFee+devFee+pokeReward to Initiator failed!");
    }

    function autoabortAvailable()
    public
    view
    inPhase(Phase.Committed)
    returns(bool passed) {
        return (block.timestamp >= phaseStartTimestamps[uint(Phase.Committed)].add(autoabortInterval));
    }

    function claim()
    external
    inPhase(Phase.Committed)
    onlyBeneficiary() {
        require(!autoabortAvailable(), "The deposit deadline has passed!");

        changePhase(Phase.Judgment);
        emit Claimed();
    }

     

    event Released();
    event Burned();

    function release()
    external
    inPhase(Phase.Judgment)
    onlyCustodian() {
        internalRelease();
    }

    function internalRelease()
    internal {
        changePhase(Phase.Closed);
        closedReason = ClosedReason.Released;

        emit Released();

         
        if (!pokeRewardGranted) {
            require(daiContract.transfer(initiator, pokeReward), "Refund of pokeReward to Initiator failed!");
        }

         
         
        require(daiContract.transfer(founderFeeAddress, founderFee), "Token transfer to founderFeeAddress failed!");
        require(daiContract.transfer(devFeeAddress, devFee), "Token transfer to devFeeAddress failed!");

         
        require(daiContract.transfer(beneficiary, getBalance()), "Final release transfer to beneficiary failed!");
    }

    function autoreleaseAvailable()
    public
    view
    inPhase(Phase.Judgment)
    returns(bool available) {
        return (block.timestamp >= phaseStartTimestamps[uint(Phase.Judgment)].add(autoreleaseInterval));
    }

    function burn()
    external
    inPhase(Phase.Judgment)
    onlyCustodian() {
        require(!autoreleaseAvailable(), "autorelease has passed; you can no longer call burn.");

        internalBurn();
    }

    function internalBurn()
    internal {
        changePhase(Phase.Closed);
        closedReason = ClosedReason.Burned;

        emit Burned();

        require(daiContract.transfer(address(0x0), getBalance()), "Final DAI burn failed!");
         
    }

     

     

    event Poke();

    function pokeNeeded()
    public
    view
     
     
    returns (bool needed) {
        return (  (phase == Phase.Open      && autorecallAvailable() )
               || (phase == Phase.Committed && autoabortAvailable()  )
               || (phase == Phase.Judgment  && autoreleaseAvailable())
               );
    }

    function grantPokeRewardToSender()
    internal {
        require(!pokeRewardGranted, "The poke reward has already been sent!");  
        pokeRewardGranted = true;
        daiContract.transfer(msg.sender, pokeReward);
    }

    function poke()
    external
     
     
    returns (bool moved) {
        if (phase == Phase.Open && autorecallAvailable()) {
            grantPokeRewardToSender();
            emit Poke();

            internalRecall();
            return true;
        }
        else if (phase == Phase.Committed && autoabortAvailable()) {
            grantPokeRewardToSender();
            emit Poke();

            internalAbort();
            return true;
        }
        else if (phase == Phase.Judgment && autoreleaseAvailable()) {
            grantPokeRewardToSender();
            emit Poke();

            internalRelease();
            return true;
        }
        else return false;
    }

     

    event InitiatorStatementLog(string statement);
    event ResponderStatementLog(string statement);

    function initiatorStatement(string memory statement)
    public
     
    onlyInitiator() {
        emit InitiatorStatementLog(statement);
    }

    function responderStatement(string memory statement)
    public
     
    onlyResponder() {
        emit ResponderStatementLog(statement);
    }

     

    function getResponderDeposit()
    public
    view
     
     
    returns(uint responderDeposit) {
        if (initiatorIsCustodian) {
            return beneficiaryDeposit;
        }
        else {
            return tradeAmount;
        }
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
     
     
    returns (address initiator,
             bool initiatorIsCustodian,
             uint tradeAmount,
             uint beneficiaryDeposit,
             uint abortPunishment,
             uint autorecallInterval,
             uint autoabortInterval,
             uint autoreleaseInterval,
             uint pokeReward
             )
    {
        return (this.initiator(),
                this.initiatorIsCustodian(),
                this.tradeAmount(),
                this.beneficiaryDeposit(),
                this.abortPunishment(),
                this.autorecallInterval(),
                this.autoabortInterval(),
                this.autoreleaseInterval(),
                this.pokeReward()
                );
    }

    function getPhaseStartInfo()
    external
    view
     
     
    returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint)
    {
        return (phaseStartBlocknums[0],
                phaseStartBlocknums[1],
                phaseStartBlocknums[2],
                phaseStartBlocknums[3],
                phaseStartBlocknums[4],
                phaseStartTimestamps[0],
                phaseStartTimestamps[1],
                phaseStartTimestamps[2],
                phaseStartTimestamps[3],
                phaseStartTimestamps[4]
                );
    }
}