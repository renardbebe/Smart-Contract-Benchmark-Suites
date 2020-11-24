 

pragma solidity ^0.4.13; 


 


 
 
contract MultiSigWallet {

    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this))
            throw;
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
            throw;
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            throw;
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0)
            throw;
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner])
            throw;
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner])
            throw;
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed)
            throw;
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0)
            throw;
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (   ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0)
            throw;
        _;
    }

     
    function()
        payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

     
     
     
     
    function MultiSigWallet(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0)
                throw;
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

     
     
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

     
     
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

     
     
     
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

     
     
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required);
    }

     
     
     
     
     
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

     
     
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

     
     
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

     
     
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction tx = transactions[transactionId];
            tx.executed = true;
            if (tx.destination.call.value(tx.value)(tx.data))
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
                tx.executed = false;
            }
        }
    }

     
     
     
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

     
     
     
     
     
     
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        Submission(transactionId);
    }

     
     
     
     
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

     
     
     
     
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

     
     
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

     
     
     
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

     
     
     
     
     
     
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}


 


contract SafeMathLib {
  function safeMul(uint a, uint b) constant returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) constant returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) constant returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
}




 
contract Ownable {
  address public owner;
  address public newOwner;
  event OwnershipTransferred(address indexed _from, address indexed _to);
   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 

 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address _owner) constant returns (uint balance);
  function transfer(address _to, uint _value) returns (bool success);
  event Transfer(address indexed _from, address indexed _to, uint _value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender) constant returns (uint remaining);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  function approve(address _spender, uint _value) returns (bool success);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}



 
contract StandardToken is ERC20, SafeMathLib {
   
  event Minted(address receiver, uint amount);

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) returns (bool success) {
    if (balances[msg.sender] >= _value 
        && _value > 0 
        && balances[_to] + _value > balances[_to]
        ) {
      balances[msg.sender] = safeSub(balances[msg.sender],_value);
      balances[_to] = safeAdd(balances[_to],_value);
      Transfer(msg.sender, _to, _value);
      return true;
    }
    else{
      return false;
    }
    
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    if (balances[_from] >= _value    
        && _allowance >= _value     
        && _value > 0               
        && balances[_to] + _value > balances[_to]   
        ){
    balances[_to] = safeAdd(balances[_to],_value);
    balances[_from] = safeSub(balances[_from],_value);
    allowed[_from][msg.sender] = safeSub(_allowance,_value);
    Transfer(_from, _to, _value);
    return true;
        }
    else {
      return false;
    }
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


    

 
contract MintableToken is StandardToken, Ownable {

  bool public mintingFinished = false;

   
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state  );

   
  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    totalSupply = safeAdd(totalSupply, amount);
    balances[receiver] = safeAdd(balances[receiver], amount);
     
     
    Transfer(0, receiver, amount);
  }

   
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
     
    require(mintAgents[msg.sender]);
    _;
  }

   
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
}



 
contract ReleasableToken is ERC20, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender) {

    if (!released) {
        require(transferAgents[_sender]);
    }

    _;
  }

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

   
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
     
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

}


 

 
contract UpgradeAgent {
  uint public originalSupply;
   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }
  function upgradeFrom(address _from, uint256 _value) public;
}

 
contract UpgradeableToken is StandardToken {

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint256 public totalUpgraded;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

   
  event UpgradeAgentSet(address agent);

   
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

   
  function upgrade(uint256 value) public {
    UpgradeState state = getUpgradeState();
    require((state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading));
     
    require(value!=0);

    balances[msg.sender] = safeSub(balances[msg.sender],value);

     
    totalSupply = safeSub(totalSupply,value);
    totalUpgraded = safeAdd(totalUpgraded,value);

     
    upgradeAgent.upgradeFrom(msg.sender, value);
    Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) external {
    require(canUpgrade());
    require(agent != 0x0);
     
    require(msg.sender == upgradeMaster);
     
    require(getUpgradeState() != UpgradeState.Upgrading);

    upgradeAgent = UpgradeAgent(agent);

     
    require(upgradeAgent.isUpgradeAgent());
     
    require(upgradeAgent.originalSupply() == totalSupply);

    UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public constant returns(UpgradeState) {
    if (!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

   
  function setUpgradeMaster(address master) public {
    require(master != 0x0);
    require(msg.sender == upgradeMaster);
    upgradeMaster = master;
  }

   
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}


 
contract DayToken is  ReleasableToken, MintableToken, UpgradeableToken {

    enum sellingStatus {NOTONSALE, EXPIRED, ONSALE}

      
    struct Contributor {
        address adr;
        uint256 initialContributionDay;
        uint256 lastUpdatedOn;  
        uint256 mintingPower;
        uint expiryBlockNumber;
        uint256 minPriceInDay;
        sellingStatus status;
    }

     
    uint256 public maxMintingDays = 1095;

     
    mapping (address => uint) public idOf;
     
    mapping (uint256 => Contributor) public contributors;
     
    mapping (address => uint256) public teamIssuedTimestamp;
    mapping (address => bool) public soldAddresses;
    mapping (address => uint256) public sellingPriceInDayOf;

     
    uint256 public firstContributorId;
     
    uint256 public totalNormalContributorIds;
     
    uint256 public totalNormalContributorIdsAllocated = 0;
    
     
    uint256 public firstTeamContributorId;
     
    uint256 public totalTeamContributorIds;
     
    uint256 public totalTeamContributorIdsAllocated = 0;

     
    uint256 public firstPostIcoContributorId;
     
    uint256 public totalPostIcoContributorIds;
     
    uint256 public totalPostIcoContributorIdsAllocated = 0;

     
    uint256 public maxAddresses;

     
    uint256 public minMintingPower;
     
    uint256 public maxMintingPower;
     
    uint256 public halvingCycle; 
     
    uint256 public initialBlockTimestamp;
     
    bool public isInitialBlockTimestampSet;
     
    uint256 public mintingDec; 

     
    uint256 public minBalanceToSell;
     
    uint256 public teamLockPeriodInSec;   
     
    uint256 public DayInSecs;

    event UpdatedTokenInformation(string newName, string newSymbol); 
    event MintingAdrTransferred(uint id, address from, address to);
    event ContributorAdded(address adr, uint id);
    event TimeMintOnSale(uint id, address seller, uint minPriceInDay, uint expiryBlockNumber);
    event TimeMintSold(uint id, address buyer, uint offerInDay);
    event PostInvested(address investor, uint weiAmount, uint tokenAmount, uint customerId, uint contributorId);
    
    event TeamAddressAdded(address teamAddress, uint id);
     
    event Invested(address receiver, uint weiAmount, uint tokenAmount, uint customerId, uint contributorId);

    modifier onlyContributor(uint id){
        require(isValidContributorId(id));
        _;
    }

    string public name; 

    string public symbol; 

    uint8 public decimals; 

     
    function DayToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals, 
        bool _mintable, uint _maxAddresses, uint _firstTeamContributorId, uint _totalTeamContributorIds, 
        uint _totalPostIcoContributorIds, uint256 _minMintingPower, uint256 _maxMintingPower, uint _halvingCycle, 
        uint256 _minBalanceToSell, uint256 _dayInSecs, uint256 _teamLockPeriodInSec) 
        UpgradeableToken(msg.sender) {
        
         
         
         
        owner = msg.sender; 
        name = _name; 
        symbol = _symbol;  
        totalSupply = _initialSupply; 
        decimals = _decimals; 
         
        balances[owner] = totalSupply; 
        maxAddresses = _maxAddresses;
        require(maxAddresses > 1);  
        
        firstContributorId = 1;
        totalNormalContributorIds = maxAddresses - _totalTeamContributorIds - _totalPostIcoContributorIds;

         
        require(totalNormalContributorIds >= 1);

        firstTeamContributorId = _firstTeamContributorId;
        totalTeamContributorIds = _totalTeamContributorIds;
        totalPostIcoContributorIds = _totalPostIcoContributorIds;
        
         
        firstPostIcoContributorId = maxAddresses - totalPostIcoContributorIds + 1;
        minMintingPower = _minMintingPower;
        maxMintingPower = _maxMintingPower;
        halvingCycle = _halvingCycle;
         
         
        initialBlockTimestamp = 1577836800;
        isInitialBlockTimestampSet = false;
         
        mintingDec = 19;
        minBalanceToSell = _minBalanceToSell;
        DayInSecs = _dayInSecs;
        teamLockPeriodInSec = _teamLockPeriodInSec;
        
        if (totalSupply > 0) {
            Minted(owner, totalSupply); 
        }

        if (!_mintable) {
            mintingFinished = true; 
            require(totalSupply != 0); 
        }
    }

     
    function setInitialBlockTimestamp(uint _initialBlockTimestamp) internal onlyOwner {
        require(!isInitialBlockTimestampSet);
        isInitialBlockTimestampSet = true;
        initialBlockTimestamp = _initialBlockTimestamp;
    }

     
    function isDayTokenActivated() constant returns (bool isActivated) {
        return (block.timestamp >= initialBlockTimestamp);
    }


     
    function isValidContributorId(uint _id) constant returns (bool isValidContributor) {
        return (_id > 0 && _id <= maxAddresses && contributors[_id].adr != 0 
            && idOf[contributors[_id].adr] == _id);  
    }

     
    function isValidContributorAddress(address _address) constant returns (bool isValidContributor) {
        return isValidContributorId(idOf[_address]);
    }


     
    function isTeamLockInPeriodOverIfTeamAddress(address _address) constant returns (bool isLockInPeriodOver) {
        isLockInPeriodOver = true;
        if (teamIssuedTimestamp[_address] != 0) {
                if (block.timestamp - teamIssuedTimestamp[_address] < teamLockPeriodInSec)
                    isLockInPeriodOver = false;
        }

        return isLockInPeriodOver;
    }

     
    function setMintingDec(uint256 _mintingDec) onlyOwner {
        require(!isInitialBlockTimestampSet);
        mintingDec = _mintingDec;
    }

     
    function releaseTokenTransfer() public onlyOwner {
        require(isInitialBlockTimestampSet);
        mintingFinished = true; 
        super.releaseTokenTransfer(); 
    }

     
    function canUpgrade() public constant returns(bool) {
        return released && super.canUpgrade(); 
    }

     
    function setTokenInformation(string _name, string _symbol) onlyOwner {
        name = _name; 
        symbol = _symbol; 
        UpdatedTokenInformation(name, symbol); 
    }

     
    function getPhaseCount(uint _day) public constant returns (uint phase) {
        phase = (_day/halvingCycle) + 1; 
        return (phase); 
    }
     
    function getDayCount() public constant returns (uint daySinceMintingEpoch) {
        daySinceMintingEpoch = 0;
        if (isDayTokenActivated())
            daySinceMintingEpoch = (block.timestamp - initialBlockTimestamp)/DayInSecs; 

        return daySinceMintingEpoch; 
    }
     
    function setInitialMintingPowerOf(uint256 _id) internal onlyContributor(_id) {
        contributors[_id].mintingPower = 
            (maxMintingPower - ((_id-1) * (maxMintingPower - minMintingPower)/(maxAddresses-1))); 
    }

     
    function getMintingPowerById(uint _id) public constant returns (uint256 mintingPower) {
        return contributors[_id].mintingPower/(2**(getPhaseCount(getDayCount())-1)); 
    }

     
    function getMintingPowerByAddress(address _adr) public constant returns (uint256 mintingPower) {
        return getMintingPowerById(idOf[_adr]);
    }


     
    function availableBalanceOf(uint256 _id, uint _dayCount) internal returns (uint256) {
        uint256 balance = balances[contributors[_id].adr]; 
        uint maxUpdateDays = _dayCount < maxMintingDays ? _dayCount : maxMintingDays;
        uint i = contributors[_id].lastUpdatedOn + 1;
        while(i <= maxUpdateDays) {
             uint phase = getPhaseCount(i);
             uint phaseEndDay = phase * halvingCycle - 1;  
             uint constantFactor = contributors[_id].mintingPower / 2**(phase-1);

            for (uint j = i; j <= phaseEndDay && j <= maxUpdateDays; j++) {
                balance = safeAdd( balance, constantFactor * balance / 10**(mintingDec + 2) );
            }

            i = j;
            
        } 
        return balance; 
    }

     
    function updateBalanceOf(uint256 _id) internal returns (bool success) {
         
        if (isValidContributorId(_id)) {
            uint dayCount = getDayCount();
             
            if (contributors[_id].lastUpdatedOn != dayCount && contributors[_id].lastUpdatedOn < maxMintingDays) {
                address adr = contributors[_id].adr;
                uint oldBalance = balances[adr];
                totalSupply = safeSub(totalSupply, oldBalance);
                uint newBalance = availableBalanceOf(_id, dayCount);
                balances[adr] = newBalance;
                totalSupply = safeAdd(totalSupply, newBalance);
                contributors[_id].lastUpdatedOn = dayCount;
                Transfer(0, adr, newBalance - oldBalance);
                return true; 
            }
        }
        return false;
    }


     
    function balanceOf(address _adr) constant returns (uint balance) {
        uint id = idOf[_adr];
        if (id != 0)
            return balanceById(id);
        else 
            return balances[_adr]; 
    }


     
    function balanceById(uint _id) public constant returns (uint256 balance) {
        address adr = contributors[_id].adr; 
        if (isDayTokenActivated()) {
            if (isValidContributorId(_id)) {
                return ( availableBalanceOf(_id, getDayCount()) );
            }
        }
        return balances[adr]; 
    }

     
    function getTotalSupply() public constant returns (uint) {
        return totalSupply;
    }

     
    function updateTimeMintBalance(uint _id) public returns (bool) {
        require(isDayTokenActivated());
        return updateBalanceOf(_id);
    }

     
    function updateMyTimeMintBalance() public returns (bool) {
        require(isDayTokenActivated());
        return updateBalanceOf(idOf[msg.sender]);
    }

     
    function transfer(address _to, uint _value) public returns (bool success) {
        require(isDayTokenActivated());
         
        require(isTeamLockInPeriodOverIfTeamAddress(msg.sender));

        updateBalanceOf(idOf[msg.sender]);

         
        require ( balanceOf(msg.sender) >= _value && _value != 0 ); 
        
        updateBalanceOf(idOf[_to]);

        balances[msg.sender] = safeSub(balances[msg.sender], _value); 
        balances[_to] = safeAdd(balances[_to], _value); 
        Transfer(msg.sender, _to, _value);

        return true;
    }
    

     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(isDayTokenActivated());

         
        require(isTeamLockInPeriodOverIfTeamAddress(_from));

        uint _allowance = allowed[_from][msg.sender];

        updateBalanceOf(idOf[_from]);

         
         
        require ( balanceOf(_from) >= _value && _value != 0  &&  _value <= _allowance); 

        updateBalanceOf(idOf[_to]);

        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
    
        Transfer(_from, _to, _value);
        
        return true;
    }


     
  function addContributor(uint contributorId, address _adr, uint _initialContributionDay) internal onlyOwner {
        require(contributorId <= maxAddresses);
         
        require(!isValidContributorAddress(_adr));
         
        require(!isValidContributorId(contributorId));
        contributors[contributorId].adr = _adr;
        idOf[_adr] = contributorId;
        setInitialMintingPowerOf(contributorId);
        contributors[contributorId].initialContributionDay = _initialContributionDay;
        contributors[contributorId].lastUpdatedOn = getDayCount();
        ContributorAdded(_adr, contributorId);
        contributors[contributorId].status = sellingStatus.NOTONSALE;
    }


     
    function sellMintingAddress(uint256 _minPriceInDay, uint _expiryBlockNumber) public returns (bool) {
        require(isDayTokenActivated());
        require(_expiryBlockNumber > block.number);

         
        require(isTeamLockInPeriodOverIfTeamAddress(msg.sender));

        uint id = idOf[msg.sender];
        require(contributors[id].status == sellingStatus.NOTONSALE);

         
        updateBalanceOf(id);
        require(balances[msg.sender] >= minBalanceToSell);
        contributors[id].minPriceInDay = _minPriceInDay;
        contributors[id].expiryBlockNumber = _expiryBlockNumber;
        contributors[id].status = sellingStatus.ONSALE;
        balances[msg.sender] = safeSub(balances[msg.sender], minBalanceToSell);
        balances[this] = safeAdd(balances[this], minBalanceToSell);
        Transfer(msg.sender, this, minBalanceToSell);
        TimeMintOnSale(id, msg.sender, contributors[id].minPriceInDay, contributors[id].expiryBlockNumber);
        return true;
    }


     
    function cancelSaleOfMintingAddress() onlyContributor(idOf[msg.sender]) public {
        uint id = idOf[msg.sender];
         
        require(contributors[id].status == sellingStatus.ONSALE);
        contributors[id].status = sellingStatus.EXPIRED;
    }


     
    function getOnSaleIds() constant public returns(uint[]) {
        uint[] memory idsOnSale = new uint[](maxAddresses);
        uint j = 0;
        for(uint i=1; i <= maxAddresses; i++) {

            if ( isValidContributorId(i) &&
                block.number <= contributors[i].expiryBlockNumber && 
                contributors[i].status == sellingStatus.ONSALE ) {
                    idsOnSale[j] = i;
                    j++;     
            }
            
        }
        return idsOnSale;
    }


     
    function getSellingStatus(uint _id) constant public returns(sellingStatus status) {
        require(isValidContributorId(_id));
        status = contributors[_id].status;
        if ( block.number > contributors[_id].expiryBlockNumber && 
                status == sellingStatus.ONSALE )
            status = sellingStatus.EXPIRED;

        return status;
    }

     
    function buyMintingAddress(uint _offerId, uint256 _offerInDay) public returns(bool) {
        if (contributors[_offerId].status == sellingStatus.ONSALE 
            && block.number > contributors[_offerId].expiryBlockNumber)
        {
            contributors[_offerId].status = sellingStatus.EXPIRED;
        }
        address soldAddress = contributors[_offerId].adr;
        require(contributors[_offerId].status == sellingStatus.ONSALE);
        require(_offerInDay >= contributors[_offerId].minPriceInDay);

         
        contributors[_offerId].status = sellingStatus.NOTONSALE;

         
         
        balances[msg.sender] = safeSub(balances[msg.sender], _offerInDay);
        balances[this] = safeAdd(balances[this], _offerInDay);
        Transfer(msg.sender, this, _offerInDay);
        if(transferMintingAddress(contributors[_offerId].adr, msg.sender)) {
             
            sellingPriceInDayOf[soldAddress] = _offerInDay;
            soldAddresses[soldAddress] = true; 
            TimeMintSold(_offerId, msg.sender, _offerInDay);  
        }
        return true;
    }


     
    function transferMintingAddress(address _from, address _to) internal onlyContributor(idOf[_from]) returns (bool) {
        require(isDayTokenActivated());

         
        require(!isValidContributorAddress(_to));
        
        uint id = idOf[_from];
         
        updateBalanceOf(id);

        contributors[id].adr = _to;
        idOf[_to] = id;
        idOf[_from] = 0;
        contributors[id].initialContributionDay = 0;
         
        contributors[id].lastUpdatedOn = getDayCount();
        contributors[id].expiryBlockNumber = 0;
        contributors[id].minPriceInDay = 0;
        MintingAdrTransferred(id, _from, _to);
        return true;
    }


     
    function fetchSuccessfulSaleProceed() public  returns(bool) {
        require(soldAddresses[msg.sender] == true);
         
        soldAddresses[msg.sender] = false;
        uint saleProceed = safeAdd(minBalanceToSell, sellingPriceInDayOf[msg.sender]);
        balances[this] = safeSub(balances[this], saleProceed);
        balances[msg.sender] = safeAdd(balances[msg.sender], saleProceed);
        Transfer(this, msg.sender, saleProceed);
        return true;
                
    }

     
    function refundFailedAuctionAmount() onlyContributor(idOf[msg.sender]) public returns(bool){
        uint id = idOf[msg.sender];
        if(block.number > contributors[id].expiryBlockNumber && contributors[id].status == sellingStatus.ONSALE)
        {
            contributors[id].status = sellingStatus.EXPIRED;
        }
        require(contributors[id].status == sellingStatus.EXPIRED);
         
        contributors[id].status = sellingStatus.NOTONSALE;
        balances[this] = safeSub(balances[this], minBalanceToSell);
         
        updateBalanceOf(id);
        balances[msg.sender] = safeAdd(balances[msg.sender], minBalanceToSell);
        contributors[id].minPriceInDay = 0;
        contributors[id].expiryBlockNumber = 0;
        Transfer(this, msg.sender, minBalanceToSell);
        return true;
    }


     
    function addTeamTimeMints(address _adr, uint _id, uint _tokens, bool _isTest) public onlyOwner {
         
        require(_id >= firstTeamContributorId && _id < firstTeamContributorId + totalTeamContributorIds);
        require(totalTeamContributorIdsAllocated < totalTeamContributorIds);
        addContributor(_id, _adr, 0);
        totalTeamContributorIdsAllocated++;
         
        if(!_isTest) teamIssuedTimestamp[_adr] = block.timestamp;
        mint(_adr, _tokens);
        TeamAddressAdded(_adr, _id);
    }


     
    function postAllocateAuctionTimeMints(address _receiver, uint _customerId, uint _id) public onlyOwner {

         
        require(_id >= firstPostIcoContributorId && _id < firstPostIcoContributorId + totalPostIcoContributorIds);
        require(totalPostIcoContributorIdsAllocated < totalPostIcoContributorIds);
        
        require(released == true);
        addContributor(_id, _receiver, 0);
        totalPostIcoContributorIdsAllocated++;
        PostInvested(_receiver, 0, 0, _customerId, _id);
    }


     
    function allocateNormalTimeMints(address _receiver, uint _customerId, uint _id, uint _tokens, uint _weiAmount) public onlyOwner {
         
        require(_id >= firstContributorId && _id <= totalNormalContributorIds);
        require(totalNormalContributorIdsAllocated < totalNormalContributorIds);
        addContributor(_id, _receiver, _tokens);
        totalNormalContributorIdsAllocated++;
        mint(_receiver, _tokens);
        Invested(_receiver, _weiAmount, _tokens, _customerId, _id);
        
    }


     
    function releaseToken(uint _initialBlockTimestamp) public onlyOwner {
        require(!released);  
        
        setInitialBlockTimestamp(_initialBlockTimestamp);

         
        releaseTokenTransfer();
    }
    
}