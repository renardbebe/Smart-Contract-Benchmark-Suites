 

pragma solidity ^0.4.13;

interface MigrationAgent {
  function migrateFrom(address _from, uint256 _value);
}

contract PoolAllocations {

   
  ERC20Basic public token;

  
  mapping (address => lockEntry) public allocations;

   
  struct lockEntry {
      uint256 totalAmount;         
      uint256 firstReleaseAmount;  
      uint256 nextRelease;         
      uint256 restOfTokens;        
      bool isFirstRelease;         
      uint numPayoutCycles;        
  }

   
  uint public maxNumOfPayoutCycles;

   
  uint public startDay;

   
  uint public cyclesStartFrom = 1;

  uint public payoutCycleInDays;

  function PoolAllocations(ERC20Basic _token) public {
    token = _token;
  }

   
  function claim() public {
    require(now >= startDay);

     var elem = allocations[msg.sender];
    require(elem.numPayoutCycles > 0);

    uint256 tokens = 0;
    uint cycles = getPayoutCycles(elem.numPayoutCycles);

    if (elem.isFirstRelease) {
      elem.isFirstRelease = false;
      tokens += elem.firstReleaseAmount;
      tokens += elem.restOfTokens;
    } else {
      require(cycles > 0);
    }

    tokens += elem.nextRelease * cycles;

    elem.numPayoutCycles -= cycles;

    assert(token.transfer(msg.sender, tokens));
  }

  function getPayoutCycles(uint payoutCyclesLeft) private constant returns (uint) {
    uint cycles = uint((now - startDay) / payoutCycleInDays) + cyclesStartFrom;

    if (cycles > maxNumOfPayoutCycles) {
       cycles = maxNumOfPayoutCycles;
    }

    return cycles - (maxNumOfPayoutCycles - payoutCyclesLeft);
  }

  function createAllocationEntry(uint256 total, uint256 first, uint256 next, uint256 rest) internal returns(lockEntry) {
    return lockEntry(total,  
                     first,  
                     next,   
                     rest,   
                     true,   
                     maxNumOfPayoutCycles);  
  }
}

contract PoolBLock is PoolAllocations {

  uint256 public constant totalAmount = 911567810300063801255851777;

  function PoolBLock(ERC20Basic _token) PoolAllocations(_token) {

     
    maxNumOfPayoutCycles = 5;  
    startDay = now;
    cyclesStartFrom = 1;  
    payoutCycleInDays = 180 days;  

     
    allocations[0x2f09079059b85c11DdA29ed62FF26F99b7469950] = createAllocationEntry(182313562060012760251170355, 0, 36462712412002552050234071, 0);
    allocations[0x3634acA3cf97dCC40584dB02d53E290b5b4b65FA] = createAllocationEntry(182313562060012760251170355, 0, 36462712412002552050234071, 0);
    allocations[0x768D9F044b9c8350b041897f08cA77AE871AeF1C] = createAllocationEntry(182313562060012760251170355, 0, 36462712412002552050234071, 0);
    allocations[0xb96De72d3fee8c7B6c096Ddeab93bf0b3De848c4] = createAllocationEntry(182313562060012760251170355, 0, 36462712412002552050234071, 0);
    allocations[0x2f97bfD7a479857a9028339Ce2426Fc3C62D96Bd] = createAllocationEntry(182313562060012760251170357, 0, 36462712412002552050234071, 2);
  }
}

contract PoolCLock is PoolAllocations {

  uint256 public constant totalAmount = 911567810300063801255851777;

  function PoolCLock(ERC20Basic _token) PoolAllocations(_token) {
    
     
    maxNumOfPayoutCycles = 5;  
    startDay = now;
    cyclesStartFrom = 1;  
    payoutCycleInDays = 180 days;  

     
    allocations[0x0d02A3365dFd745f76225A0119fdD148955f821E] = createAllocationEntry(182313562060012760251170355, 0, 36462712412002552050234071, 0);
    allocations[0x0deF4A4De337771c22Ac8C8D4b9C5Fec496841A5] = createAllocationEntry(182313562060012760251170355, 0, 36462712412002552050234071, 0);
    allocations[0x467600367BdBA1d852dbd8C1661a5E6a2Be5F6C8] = createAllocationEntry(182313562060012760251170355, 0, 36462712412002552050234071, 0);
    allocations[0x92E01739142386E4820eC8ddC3AFfF69de99641a] = createAllocationEntry(182313562060012760251170355, 0, 36462712412002552050234071, 0);
    allocations[0x1E0a7E0706373d0b76752448ED33cA1E4070753A] = createAllocationEntry(182313562060012760251170357, 0, 36462712412002552050234071, 2);
  }
}

contract PoolDLock is PoolAllocations {

  uint256 public constant totalAmount = 546940686180038280753511066;

  function PoolDLock(ERC20Basic _token) PoolAllocations(_token) {
    
     
    maxNumOfPayoutCycles = 36;  
    startDay = now + 3 years;   
    cyclesStartFrom = 0;
    payoutCycleInDays = 30 days;  

     
    allocations[0x4311F6F65B411f546c7DD8841A344614297Dbf62] = createAllocationEntry(
      182313562060012760251170355,  
      91156781030006380125585177,   
      2532132806389066114599588,    
      10                            
    );
     allocations[0x3b52Ab408cd499A1456af83AC095fCa23C014e0d] = createAllocationEntry(
      182313562060012760251170355,  
      91156781030006380125585177,   
      2532132806389066114599588,    
      10                            
    );
     allocations[0x728D5312FbbdFBcC1b9582E619f6ceB6412B98E4] = createAllocationEntry(
      182313562060012760251170356,  
      91156781030006380125585177,   
      2532132806389066114599588,    
      11                            
    );
  }
}

contract Pausable {
  event Pause();
  event Unpause();

  bool public paused = false;
  address public owner;

  function Pausable(address _owner) {
    owner = _owner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract BlockvPublicLedger is Ownable {

  struct logEntry{
        string txType;
        string txId;
        address to;
        uint256 amountContributed;
        uint8 discount;
        uint256 blockTimestamp;
  }
  struct distributionEntry{
        string txId;
        address to;
        uint256 amountContributed;    
        uint8 discount;
        uint256 tokenAmount;
  }
  struct index {
    uint256 index;
    bool set;
  }
  uint256 public txCount = 0;
  uint256 public distributionEntryCount = 0;
  mapping (string => index) distributionIndex;
  logEntry[] public transactionLog;
  distributionEntry[] public distributionList;
  bool public distributionFixed = false;


   
  function BlockvPublicLedger() {
  }

   
  function appendToDistributionList(string _tx_id, address _to, uint256 _amount, uint8 _discount)  onlyOwner returns (bool) {
        index memory idx = distributionIndex[_tx_id];
        bool ret;
        logEntry memory le;
        distributionEntry memory de;

        if(distributionFixed) {  
          revert();
        }

        if ( _discount > 100 ) {
          revert();
        }
         
        if ( !idx.set ) {
            ret = false;
            le.txType = "INSERT";
        } else {
            ret = true;
            le.txType = "UPDATE";          
        }
        le.to = _to;
        le.amountContributed = _amount;
        le.blockTimestamp = block.timestamp;
        le.txId = _tx_id;
        le.discount = _discount;
        transactionLog.push(le);
        txCount++;

         
        de.txId = _tx_id;
        de.to = _to;
        de.amountContributed = _amount;
        de.discount = _discount;
        de.tokenAmount = 0;
        if (!idx.set) {
          idx.index = distributionEntryCount;
          idx.set = true;
          distributionIndex[_tx_id] = idx;
          distributionList.push(de);
          distributionEntryCount++;
        } else {
          distributionList[idx.index] = de;
        }
        return ret;
  }


   
  function fixDistribution(uint8 _tokenPrice, uint256 _usdToEthConversionRate) onlyOwner {

    distributionEntry memory de;
    logEntry memory le;
    uint256 i = 0;

    if(distributionFixed) {  
      revert();
    }

    for(i = 0; i < distributionEntryCount; i++) {
      de = distributionList[i];
      de.tokenAmount = (de.amountContributed * _usdToEthConversionRate * 100) / (_tokenPrice  * de.discount / 100);
      distributionList[i] = de;
    }
    distributionFixed = true;
  
    le.txType = "FIXED";
    le.blockTimestamp = block.timestamp;
    le.txId = "__FIXED__DISTRIBUTION__";
    transactionLog.push(le);
    txCount++;

  }

}

contract PoolAContract is Ownable {
    uint256 private ledgerContractSize = 0;
    uint256 public currentIndex = 0;
    uint public chunkSize = 0;

    bool public done = false;

    uint constant decimals = 18;

    uint256 public constant oneTokenInWei = 69164622576285;

    uint constant defaultDiscount = 100;
    uint256 constant discountMultiplier = 10 ** 24;
    mapping(uint8 => uint256) discounts;

    address public ledgerContractAddr;
    address public blockVContractAddr;

    BlockvToken blockVContract;
    BlockvPublicLedger ledgerContract; 

    function PoolAContract(address _ledgerContractAddr, address _blockVContractAddr, uint _chunkSize) {
        ledgerContractAddr = _ledgerContractAddr;
        blockVContractAddr = _blockVContractAddr;

        chunkSize = _chunkSize;

        blockVContract = BlockvToken(_blockVContractAddr);
        ledgerContract = BlockvPublicLedger(_ledgerContractAddr);

        ledgerContractSize = ledgerContract.distributionEntryCount();

         
         
        discounts[1] = 79023092125237418622692649;
        discounts[2] = 80 * discountMultiplier;
        discounts[3] = 90 * discountMultiplier;
        discounts[100] = 100 * discountMultiplier;
    }

    function distribution() public onlyOwner {
        require(!done);

        uint256 i = currentIndex;
        for (; i < currentIndex + chunkSize && i < ledgerContractSize; i++) {
            var (, to, amount, discount,) = ledgerContract.distributionList(i);
            uint256 tokenAmount = getTokenAmount(amount, discount);
            assert(blockVContract.transferFrom(msg.sender, to, tokenAmount));
        }
        currentIndex = i;   

        if (currentIndex == ledgerContractSize) {
          done = true;
        }
    }

    function setChunkSize(uint _chunkSize) public onlyOwner {
        chunkSize = _chunkSize;
    }

    function getTokenAmount(uint256 amount, uint8 discountGroup) private constant returns(uint256) {
        uint256 discount = getTokenDiscount(discountGroup);
        return (amount * 10 ** decimals * discountMultiplier) / ((oneTokenInWei * discount) / 100);
    }

    function getTokenDiscount(uint8 discount) private constant returns(uint256) {
        uint r = discounts[discount];
        if (r != 0) {
            return r;
        }
        
        return defaultDiscount * discountMultiplier;
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  modifier onlyPayloadSize(uint numwords) {
      assert(msg.data.length == numwords * 32 + 4);
      _;
  }

   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) onlyPayloadSize(2) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract BlockvToken is StandardToken, Pausable {

  string public constant name = "BLOCKv Token";  
  string public constant symbol = "VEE";         
  uint8  public constant decimals = 18;          

  PoolBLock public poolBLock;
  PoolCLock public poolCLock;
  PoolDLock public poolDLock;

  uint256 public constant totalAmountOfTokens = 3646271241200255205023407108;
  uint256 public constant amountOfTokensPoolA = 1276194934420089321758192488;
  uint256 public constant amountOfTokensPoolB = 911567810300063801255851777;
  uint256 public constant amountOfTokensPoolC = 911567810300063801255851777;
  uint256 public constant amountOfTokensPoolD = 546940686180038280753511066;

   
  address public migrationMaster;
  address public migrationAgent;
  uint256 public totalMigrated;
  event Migrate(address indexed _from, address indexed _to, uint256 _value);

   
  function BlockvToken(address _migrationMaster) Pausable(_migrationMaster) {
    require(_migrationMaster != 0);
    migrationMaster = _migrationMaster;

    totalSupply = totalAmountOfTokens;  

    balances[msg.sender] = amountOfTokensPoolA;
    Transfer(0x0, msg.sender, amountOfTokensPoolA);
  
     
    poolBLock = new PoolBLock(this);
    poolCLock = new PoolCLock(this);
    poolDLock = new PoolDLock(this);

    balances[poolBLock] = amountOfTokensPoolB;
    balances[poolCLock] = amountOfTokensPoolC;
    balances[poolDLock] = amountOfTokensPoolD;

    Transfer(0x0, poolBLock, amountOfTokensPoolB);
    Transfer(0x0, poolCLock, amountOfTokensPoolC);
    Transfer(0x0, poolDLock, amountOfTokensPoolD);
  }

   
  function transfer(address _to, uint256 _value) whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_to != address(this));
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_from != _to);
    require(_to != address(this));
    return super.transferFrom(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) whenNotPaused returns (bool) {
    require(_spender != address(0));
    require(_spender != address(this));
    return super.approve(_spender, _value);
  }

   

   
  function migrate(uint256 _value) external {
    require(migrationAgent != 0);
    require(_value != 0);
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    totalMigrated = totalMigrated.add(_value);
    MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
    
    Migrate(msg.sender, migrationAgent, _value);
  }

   
  function setMigrationAgent(address _agent) external {
    require(_agent != 0);
    require(migrationAgent == 0);
    require(msg.sender == migrationMaster);

    migrationAgent = _agent;
  }

  function setMigrationMaster(address _master) external {
    require(_master != 0);
    require(msg.sender == migrationMaster);

    migrationMaster = _master;
  }
}