 

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
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

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender)public view returns (uint256);
    function transferFrom(address from, address to, uint256 value)public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}
contract StandardToken is ERC20Interface {

    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply_;

     
     
    bool public migrationStart;
     
    TimeLock timeLockContract;

     
    modifier migrateStarted {
        if(migrationStart == true){
            require(msg.sender == address(timeLockContract));
        }
        _;
    }

    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public migrateStarted returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
        )
        public
        migrateStarted
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}
contract GTXERC20Migrate is Ownable {
    using SafeMath for uint256;

     
     

    mapping (address => uint256) public migratableGTX;

    GTXToken public ERC20;

    constructor(GTXToken _ERC20) public {
        ERC20 = _ERC20;
    }

     
     
    event GTXRecordUpdate(
        address indexed _recordAddress,
        uint256 _totalMigratableGTX
    );

     
    function initiateGTXMigration(uint256 _balanceToMigrate) public {
        uint256 migratable = ERC20.migrateTransfer(msg.sender,_balanceToMigrate);
        migratableGTX[msg.sender] = migratableGTX[msg.sender].add(migratable);
        emit GTXRecordUpdate(msg.sender, migratableGTX[msg.sender]);
    }

}
contract TimeLock {
     
    GTXToken public ERC20;
     
    struct accountData {
        uint256 balance;
        uint256 releaseTime;
    }

    event Lock(address indexed _tokenLockAccount, uint256 _lockBalance, uint256 _releaseTime);
    event UnLock(address indexed _tokenUnLockAccount, uint256 _unLockBalance, uint256 _unLockTime);

     
    mapping (address => accountData) public accounts;

     

    constructor(GTXToken _ERC20) public {
        ERC20 = _ERC20;
    }

    function timeLockTokens(uint256 _lockTimeS) public {

        uint256 lockAmount = ERC20.allowance(msg.sender, this);  
        require(lockAmount != 0);  
        if (accounts[msg.sender].balance > 0) {  
            accounts[msg.sender].balance = SafeMath.add(accounts[msg.sender].balance, lockAmount);
        } else {  
            accounts[msg.sender].balance = lockAmount;
            accounts[msg.sender].releaseTime = SafeMath.add(block.timestamp , _lockTimeS);
        }

        emit Lock(msg.sender, lockAmount, accounts[msg.sender].releaseTime);
        ERC20.transferFrom(msg.sender, this, lockAmount);

    }

    function tokenRelease() public {
         
        require (accounts[msg.sender].balance != 0 && accounts[msg.sender].releaseTime <= block.timestamp);
        uint256 transferUnlockedBalance = accounts[msg.sender].balance;
        accounts[msg.sender].balance = 0;
        accounts[msg.sender].releaseTime = 0;
        emit UnLock(msg.sender, transferUnlockedBalance, block.timestamp);
        ERC20.transfer(msg.sender, transferUnlockedBalance);
    }

     
    function getLockedFunds(address _account) view public returns (uint _lockedBalance) {
        return accounts[_account].balance;
    }

    function getReleaseTime(address _account) view public returns (uint _releaseTime) {
        return accounts[_account].releaseTime;
    }

}
contract GTXToken is StandardToken, Ownable{
    using SafeMath for uint256;
    event SetMigrationAddress(address GTXERC20MigrateAddress);
    event SetAuctionAddress(address GTXAuctionContractAddress);
    event SetTimeLockAddress(address _timeLockAddress);
    event Migrated(address indexed account, uint256 amount);
    event MigrationStarted();


     
    GTXRecord public gtxRecord;
    GTXPresale public gtxPresale;
    uint256 public totalAllocation;

     
    TimeLock timeLockContract;
    GTXERC20Migrate gtxMigrationContract;
    GTXAuction gtxAuctionContract;

     
    modifier onlyMigrate {
        require(msg.sender == address(gtxMigrationContract));
        _;
    }

     
    modifier onlyAuction {
        require(msg.sender == address(gtxAuctionContract));
        _;
    }

     
    constructor(uint256 _totalSupply, GTXRecord _gtxRecord, GTXPresale _gtxPresale, string _name, string _symbol, uint8 _decimals)
    StandardToken(_name,_symbol,_decimals) public {
        require(_gtxRecord != address(0), "Must provide a Record address");
        require(_gtxPresale != address(0), "Must provide a PreSale address");
        require(_gtxPresale.getStage() > 0, "Presale must have already set its allocation");
        require(_gtxRecord.maxRecords().add(_gtxPresale.totalPresaleTokens()) <= _totalSupply, "Records & PreSale allocation exceeds the proposed total supply");

        totalSupply_ = _totalSupply;  
        gtxRecord = _gtxRecord;
        gtxPresale = _gtxPresale;
    }

     
    function () public payable {
        revert ();
    }

     
    function recoverLost(ERC20Interface _token) public onlyOwner {
        _token.transfer(owner(), _token.balanceOf(this));
    }

     
    function setMigrationAddress(GTXERC20Migrate _gtxMigrateContract) public onlyOwner returns (bool) {
        require(_gtxMigrateContract != address(0), "Must provide a Migration address");
         
        require(_gtxMigrateContract.ERC20() == address(this), "Migration contract does not have this token assigned");

        gtxMigrationContract = _gtxMigrateContract;
        emit SetMigrationAddress(_gtxMigrateContract);
        return true;
    }

     
    function setAuctionAddress(GTXAuction _gtxAuctionContract) public onlyOwner returns (bool) {
        require(_gtxAuctionContract != address(0), "Must provide an Auction address");
         
        require(_gtxAuctionContract.ERC20() == address(this), "Auction contract does not have this token assigned");

        gtxAuctionContract = _gtxAuctionContract;
        emit SetAuctionAddress(_gtxAuctionContract);
        return true;
    }

     
    function setTimeLockAddress(TimeLock _timeLockContract) public onlyOwner returns (bool) {
        require(_timeLockContract != address(0), "Must provide a TimeLock address");
         
        require(_timeLockContract.ERC20() == address(this), "TimeLock contract does not have this token assigned");

        timeLockContract = _timeLockContract;
        emit SetTimeLockAddress(_timeLockContract);
        return true;
    }

     
    function startMigration() onlyOwner public returns (bool) {
        require(migrationStart == false, "startMigration has already been run");
         
        require(gtxMigrationContract != address(0), "Migration contract address must be set");
         
        require(gtxAuctionContract != address(0), "Auction contract address must be set");
         
        require(timeLockContract != address(0), "TimeLock contract address must be set");

        migrationStart = true;
        emit MigrationStarted();

        return true;
    }

     

    function passAuctionAllocation(uint256 _auctionAllocation) public onlyAuction {
         
        require(gtxRecord.lockRecords() == true, "GTXRecord contract lock state should be true");

        uint256 gtxRecordTotal = gtxRecord.totalClaimableGTX();
        uint256 gtxPresaleTotal = gtxPresale.totalPresaleTokens();

        totalAllocation = _auctionAllocation.add(gtxRecordTotal).add(gtxPresaleTotal);
        require(totalAllocation <= totalSupply_, "totalAllocation must be less than totalSupply");
        balances[gtxAuctionContract] = totalAllocation;
        emit Transfer(address(0), gtxAuctionContract, totalAllocation);
        uint256 remainingTokens = totalSupply_.sub(totalAllocation);
        balances[owner()] = remainingTokens;
        emit Transfer(address(0), owner(), totalAllocation);
    }

     
    function migrateTransfer(address _account, uint256 _amount) onlyMigrate public returns (uint256) {
        require(migrationStart == true);
        uint256 userBalance = balanceOf(_account);
        require(userBalance >= _amount);

        emit Migrated(_account, _amount);
        balances[_account] = balances[_account].sub(_amount);
        return _amount;
    }

     
    function getGTXRecord() public view returns (address) {
        return address(gtxRecord);
    }

     
    function getAuctionAllocation() public view returns (uint256){
        require(totalAllocation != 0, "Auction allocation has not been set yet");
        return totalAllocation;
    }
}
contract GTXRecord is Ownable {
    using SafeMath for uint256;

     
     
    uint256 public conversionRate;

     
    bool public lockRecords;

     
    uint256 public maxRecords;

     
    uint256 public totalClaimableGTX;

     
     
    mapping (address => uint256) public claimableGTX;

    event GTXRecordCreate(
        address indexed _recordAddress,
        uint256 _finPointAmount,
        uint256 _gtxAmount
    );

    event GTXRecordUpdate(
        address indexed _recordAddress,
        uint256 _finPointAmount,
        uint256 _gtxAmount
    );

    event GTXRecordMove(
        address indexed _oldAddress,
        address indexed _newAddress,
        uint256 _gtxAmount
    );

    event LockRecords();

     
    modifier canRecord() {
        require(conversionRate > 0);
        require(!lockRecords);
        _;
    }

     
    constructor (uint256 _maxRecords) public {
        maxRecords = _maxRecords;
    }

     
    function setConversionRate(uint256 _conversionRate) external onlyOwner{
        require(_conversionRate <= 1000);  
        require(_conversionRate > 0);  
        conversionRate = _conversionRate;
    }

    
    function lock() public onlyOwner returns (bool) {
        lockRecords = true;
        emit LockRecords();
        return true;
    }

     
    function recordCreate(address _recordAddress, uint256 _finPointAmount, bool _applyConversionRate) public onlyOwner canRecord {
        require(_finPointAmount >= 100000, "cannot be less than 100000 FIN (in WEI)");  
        uint256 afterConversionGTX;
        if(_applyConversionRate == true) {
            afterConversionGTX = _finPointAmount.mul(conversionRate).div(100);
        } else {
            afterConversionGTX = _finPointAmount;
        }
        claimableGTX[_recordAddress] = claimableGTX[_recordAddress].add(afterConversionGTX);
        totalClaimableGTX = totalClaimableGTX.add(afterConversionGTX);
        require(totalClaimableGTX <= maxRecords, "total token record (contverted GTX) cannot exceed GTXRecord token limit");
        emit GTXRecordCreate(_recordAddress, _finPointAmount, claimableGTX[_recordAddress]);
    }

     
    function recordUpdate(address _recordAddress, uint256 _finPointAmount, bool _applyConversionRate) public onlyOwner canRecord {
        require(_finPointAmount >= 100000, "cannot be less than 100000 FIN (in WEI)");  
        uint256 afterConversionGTX;
        totalClaimableGTX = totalClaimableGTX.sub(claimableGTX[_recordAddress]);
        if(_applyConversionRate == true) {
            afterConversionGTX  = _finPointAmount.mul(conversionRate).div(100);
        } else {
            afterConversionGTX  = _finPointAmount;
        }
        claimableGTX[_recordAddress] = afterConversionGTX;
        totalClaimableGTX = totalClaimableGTX.add(claimableGTX[_recordAddress]);
        require(totalClaimableGTX <= maxRecords, "total token record (contverted GTX) cannot exceed GTXRecord token limit");
        emit GTXRecordUpdate(_recordAddress, _finPointAmount, claimableGTX[_recordAddress]);
    }

     
    function recordMove(address _oldAddress, address _newAddress) public onlyOwner canRecord {
        require(claimableGTX[_oldAddress] != 0, "cannot move a zero record");
        require(claimableGTX[_newAddress] == 0, "destination must not already have a claimable record");

        claimableGTX[_newAddress] = claimableGTX[_oldAddress];
        claimableGTX[_oldAddress] = 0;

        emit GTXRecordMove(_oldAddress, _newAddress, claimableGTX[_newAddress]);
    }

}
contract GTXPresale is Ownable {
    using SafeMath for uint256;

     
    bool public lockRecords;

     
    uint256 public totalPresaleTokens;

     
    uint256 public totalClaimableGTX;

     
    mapping (address => uint256) public presaleGTX;
    mapping (address => uint256) public bonusGTX;
    mapping (address => uint256) public claimableGTX;

     
    uint256[11] public bonusPercent;  
    uint256[11] public bonusThreshold;  

     
    Stages public stage;

     
    enum Stages {
        PresaleDeployed,
        Presale,
        ClaimingStarted
    }

     
    modifier atStage(Stages _stage) {
        require(stage == _stage, "function not allowed at current stage");
        _;
    }

    event Setup(
        uint256 _maxPresaleTokens,
        uint256[] _bonusThreshold,
        uint256[] _bonusPercent
    );

    event GTXRecordCreate(
        address indexed _recordAddress,
        uint256 _gtxTokens
    );

    event GTXRecordUpdate(
        address indexed _recordAddress,
        uint256 _gtxTokens
    );

    event GTXRecordMove(
        address indexed _oldAddress,
        address indexed _newAddress,
        uint256 _gtxTokens
    );

    event LockRecords();

    constructor() public{
        stage = Stages.PresaleDeployed;
    }

    
    function lock() public onlyOwner returns (bool) {
        lockRecords = true;
        stage = Stages.ClaimingStarted;
        emit LockRecords();
        return true;
    }

     
    function setup(uint256 _maxPresaleTokens, uint256[] _bonusThreshold, uint256[] _bonusPercent) external onlyOwner atStage(Stages.PresaleDeployed) {
        require(_bonusPercent.length == _bonusThreshold.length, "Length of bonus percent array and bonus threshold should be equal");
        totalPresaleTokens =_maxPresaleTokens;
        for(uint256 i=0; i< _bonusThreshold.length; i++) {
            bonusThreshold[i] = _bonusThreshold[i];
            bonusPercent[i] = _bonusPercent[i];
        }
        stage = Stages.Presale;  
        emit Setup(_maxPresaleTokens,_bonusThreshold,_bonusPercent);
    }

     
    function recordCreate(address _recordAddress, uint256 _gtxTokens) public onlyOwner atStage(Stages.Presale) {
         
        require(_gtxTokens >= 100000, "Minimum allowed GTX tokens is 100000 Bosons");
        totalClaimableGTX = totalClaimableGTX.sub(claimableGTX[_recordAddress]);
        presaleGTX[_recordAddress] = presaleGTX[_recordAddress].add(_gtxTokens);
        bonusGTX[_recordAddress] = calculateBonus(_recordAddress);
        claimableGTX[_recordAddress] = presaleGTX[_recordAddress].add(bonusGTX[_recordAddress]);

        totalClaimableGTX = totalClaimableGTX.add(claimableGTX[_recordAddress]);
        require(totalClaimableGTX <= totalPresaleTokens, "total token record (presale GTX + bonus GTX) cannot exceed presale token limit");
        emit GTXRecordCreate(_recordAddress, claimableGTX[_recordAddress]);
    }


     
    function recordUpdate(address _recordAddress, uint256 _gtxTokens) public onlyOwner atStage(Stages.Presale){
         
        require(_gtxTokens >= 100000, "Minimum allowed GTX tokens is 100000 Bosons");
        totalClaimableGTX = totalClaimableGTX.sub(claimableGTX[_recordAddress]);
        presaleGTX[_recordAddress] = _gtxTokens;
        bonusGTX[_recordAddress] = calculateBonus(_recordAddress);
        claimableGTX[_recordAddress] = presaleGTX[_recordAddress].add(bonusGTX[_recordAddress]);
        
        totalClaimableGTX = totalClaimableGTX.add(claimableGTX[_recordAddress]);
        require(totalClaimableGTX <= totalPresaleTokens, "total token record (presale GTX + bonus GTX) cannot exceed presale token limit");
        emit GTXRecordUpdate(_recordAddress, claimableGTX[_recordAddress]);
    }

     
    function recordMove(address _oldAddress, address _newAddress) public onlyOwner atStage(Stages.Presale){
        require(claimableGTX[_oldAddress] != 0, "cannot move a zero record");
        require(claimableGTX[_newAddress] == 0, "destination must not already have a claimable record");

         
        presaleGTX[_newAddress] = presaleGTX[_oldAddress];
        presaleGTX[_oldAddress] = 0;

         
        bonusGTX[_newAddress] = bonusGTX[_oldAddress];
        bonusGTX[_oldAddress] = 0;

         
        claimableGTX[_newAddress] = claimableGTX[_oldAddress];
        claimableGTX[_oldAddress] = 0;

        emit GTXRecordMove(_oldAddress, _newAddress, claimableGTX[_newAddress]);
    }


     
    function calculateBonus(address _receiver) public view returns(uint256 bonus) {
        uint256 gtxTokens = presaleGTX[_receiver];
        for(uint256 i=0; i < bonusThreshold.length; i++) {
            if(gtxTokens >= bonusThreshold[i]) {
                bonus = (bonusPercent[i].mul(gtxTokens)).div(100);
            }
        }
        return bonus;
    }

     
    function getStage() public view returns (uint256) {
        return uint(stage);
    }

}
contract GTXAuction is Ownable {
    using SafeMath for uint256;

     
    event Setup(uint256 etherPrice, uint256 hardCap, uint256 ceiling, uint256 floor, uint256[] bonusThreshold, uint256[] bonusPercent);
    event BidSubmission(address indexed sender, uint256 amount);
    event ClaimedTokens(address indexed recipient, uint256 sentAmount);
    event Collected(address collector, address multiSigAddress, uint256 amount);
    event SetMultiSigAddress(address owner, address multiSigAddress);

     
     
    GTXToken public ERC20;
    GTXRecord public gtxRecord;
    GTXPresale public gtxPresale;

     
    uint256 public maxTokens;  
    uint256 public remainingCap;  
    uint256 public totalReceived;  
    uint256 public maxTotalClaim;  
    uint256 public totalAuctionTokens;  
    uint256 public fundsClaimed;   

     
    uint256 public startBlock;  
    uint256 public biddingPeriod;  
    uint256 public endBlock;  
    uint256 public waitingPeriod;  

     
    uint256 public etherPrice;  
    uint256 public ceiling;  
    uint256 public floor;  
    uint256 public hardCap;  
    uint256 public priceConstant;  
    uint256 public finalPrice;  
    uint256 constant public WEI_FACTOR = 10**18;  
    
     
    uint256 public participants; 
    address public multiSigAddress;  

     
    mapping (address => uint256) public bids;  
    mapping (address => uint256) public bidTokens;  
    mapping (address => uint256) public totalTokens;  
    mapping (address => bool) public claimedStatus;  

     
    mapping (address => bool) public whitelist;

     
    uint256[11] public bonusPercent;  
    uint256[11] public bonusThresholdWei;  

     
    Stages public stage;

     
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        ClaimingStarted,
        ClaimingEnded
    }

     
    modifier atStage(Stages _stage) {
        require(stage == _stage, "not the expected stage");
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && block.number >= endBlock) {
            finalizeAuction();
            msg.sender.transfer(msg.value);
            return;
        }
        if (stage == Stages.AuctionEnded && block.number >= endBlock.add(waitingPeriod)) {
            stage = Stages.ClaimingStarted;
        }
        _;
    }

    modifier onlyWhitelisted(address _participant) {
        require(whitelist[_participant] == true, "account is not white listed");
        _;
    }

     
     
     
     
     
     
     


    constructor (
        GTXToken _gtxToken,
        GTXRecord _gtxRecord,
        GTXPresale _gtxPresale,
        uint256 _biddingPeriod,
        uint256 _waitingPeriod
    )
       public
    {
        require(_gtxToken != address(0), "Must provide a Token address");
        require(_gtxRecord != address(0), "Must provide a Record address");
        require(_gtxPresale != address(0), "Must provide a PreSale address");
        require(_biddingPeriod > 0, "The bidding period must be a minimum 1 block");
        require(_waitingPeriod > 0, "The waiting period must be a minimum 1 block");

        ERC20 = _gtxToken;
        gtxRecord = _gtxRecord;
        gtxPresale = _gtxPresale;
        waitingPeriod = _waitingPeriod;
        biddingPeriod = _biddingPeriod;

        uint256 gtxSwapTokens = gtxRecord.maxRecords();
        uint256 gtxPresaleTokens = gtxPresale.totalPresaleTokens();
        maxTotalClaim = maxTotalClaim.add(gtxSwapTokens).add(gtxPresaleTokens);

         
        stage = Stages.AuctionDeployed;
    }

     
    function () public payable {
        bid(msg.sender);
    }

     
    function recoverTokens(ERC20Interface _token) external onlyOwner {
        if(address(_token) == address(ERC20)) {
            require(uint(stage) >= 3, "auction bidding must be ended to recover");
            if(currentStage() == 3 || currentStage() == 4) {
                _token.transfer(owner(), _token.balanceOf(address(this)).sub(maxTotalClaim));
            } else {
                _token.transfer(owner(), _token.balanceOf(address(this)));
            }
        } else {
            _token.transfer(owner(), _token.balanceOf(address(this)));
        }
    }

     
     
    function addToWhitelist(address[] _bidder_addresses) external onlyOwner {
        for (uint32 i = 0; i < _bidder_addresses.length; i++) {
            if(_bidder_addresses[i] != address(0) && whitelist[_bidder_addresses[i]] == false){
                whitelist[_bidder_addresses[i]] = true;
            }
        }
    }

     
     
    function removeFromWhitelist(address[] _bidder_addresses) external onlyOwner {
        for (uint32 i = 0; i < _bidder_addresses.length; i++) {
            if(_bidder_addresses[i] != address(0) && whitelist[_bidder_addresses[i]] == true){
                whitelist[_bidder_addresses[i]] = false;
            }
        }
    }

     
     
     
     
     
     
     
     

    function setup(
        uint256 _maxTokens,
        uint256 _etherPrice,
        uint256 _hardCap,
        uint256 _ceiling,
        uint256 _floor,
        uint256[] _bonusThreshold,
        uint256[] _bonusPercent
    )
        external
        onlyOwner
        atStage(Stages.AuctionDeployed)
        returns (bool)
    {
        require(_maxTokens > 0,"Max Tokens should be > 0");
        require(_etherPrice > 0,"Ether price should be > 0");
        require(_hardCap > 0,"Hard Cap should be > 0");
        require(_floor < _ceiling,"Floor must be strictly less than the ceiling");
        require(_bonusPercent.length == 11 && _bonusThreshold.length == 11, "Length of bonus percent array and bonus threshold should be 11");

        maxTokens = _maxTokens;
        etherPrice = _etherPrice;

         
         
        ERC20.passAuctionAllocation(maxTokens);

         
        require(ERC20.balanceOf(address(this)) == ERC20.getAuctionAllocation(), "Incorrect balance assigned by auction allocation");

         
        ceiling = _ceiling.mul(WEI_FACTOR).div(_etherPrice);  
        floor = _floor.mul(WEI_FACTOR).div(_etherPrice);  
        hardCap = _hardCap.mul(WEI_FACTOR).div(_etherPrice);  
        for (uint32 i = 0; i<_bonusPercent.length; i++) {
            bonusPercent[i] = _bonusPercent[i];
            bonusThresholdWei[i] = _bonusThreshold[i].mul(WEI_FACTOR).div(_etherPrice);
        }
        remainingCap = hardCap.sub(remainingCap);
         
        priceConstant = (biddingPeriod**3).div((biddingPeriod.add(1).mul(ceiling).div(floor)).sub(biddingPeriod.add(1)));

         
        stage = Stages.AuctionSetUp;
        emit Setup(_etherPrice,_hardCap,_ceiling,_floor,_bonusThreshold,_bonusPercent);
    }

     
     
     
     
     
     
     

    function changeSettings(
        uint256 _etherPrice,
        uint256 _hardCap,
        uint256 _ceiling,
        uint256 _floor,
        uint256[] _bonusThreshold,
        uint256[] _bonusPercent
    )
        external
        onlyOwner
        atStage(Stages.AuctionSetUp)
    {
        require(_etherPrice > 0,"Ether price should be > 0");
        require(_hardCap > 0,"Hard Cap should be > 0");
        require(_floor < _ceiling,"floor must be strictly less than the ceiling");
        require(_bonusPercent.length == _bonusThreshold.length, "Length of bonus percent array and bonus threshold should be equal");
        etherPrice = _etherPrice;
        ceiling = _ceiling.mul(WEI_FACTOR).div(_etherPrice);  
        floor = _floor.mul(WEI_FACTOR).div(_etherPrice);  
        hardCap = _hardCap.mul(WEI_FACTOR).div(_etherPrice);  
        for (uint i = 0 ; i<_bonusPercent.length; i++) {
            bonusPercent[i] = _bonusPercent[i];
            bonusThresholdWei[i] = _bonusThreshold[i].mul(WEI_FACTOR).div(_etherPrice);
        }
        remainingCap = hardCap.sub(remainingCap);
         
        priceConstant = (biddingPeriod**3).div((biddingPeriod.add(1).mul(ceiling).div(floor)).sub(biddingPeriod.add(1)));
        emit Setup(_etherPrice,_hardCap,_ceiling,_floor,_bonusThreshold,_bonusPercent);
    }

     
    function startAuction()
        public
        onlyOwner
        atStage(Stages.AuctionSetUp)
    {
         
        stage = Stages.AuctionStarted;
        startBlock = block.number;
        endBlock = startBlock.add(biddingPeriod);
    }

     
    function endClaim()
        public
        onlyOwner
        atStage(Stages.ClaimingStarted)
    {
        require(block.number >= endBlock.add(biddingPeriod), "Owner can end claim only after 3 months");    
         
        stage = Stages.ClaimingEnded;
    }

     
     
     
    function setMultiSigAddress(address _multiSigAddress) external onlyOwner returns(bool){
        require(_multiSigAddress != address(0), "not a valid multisignature address");
        multiSigAddress = _multiSigAddress;
        emit SetMultiSigAddress(msg.sender,multiSigAddress);
        return true;
    }

     
    function collect() external onlyOwner returns (bool) {
        require(multiSigAddress != address(0), "multisignature address is not set");
        multiSigAddress.transfer(address(this).balance);
        emit Collected(msg.sender, multiSigAddress, address(this).balance);
        return true;
    }

     
     
    function bid(address _receiver)
        public
        payable
        timedTransitions
        atStage(Stages.AuctionStarted)
    {
        require(msg.value > 0, "bid must be larger than 0");
        require(block.number <= endBlock ,"Auction has ended");
        if (_receiver == 0x0) {
            _receiver = msg.sender;
        }
        assert(bids[_receiver].add(msg.value) >= msg.value);

        uint256 maxWei = hardCap.sub(totalReceived);  
        require(msg.value <= maxWei, "Hardcap limit will be exceeded");
        participants = participants.add(1);
        bids[_receiver] = bids[_receiver].add(msg.value);

        uint256 maxAcctClaim = bids[_receiver].mul(WEI_FACTOR).div(calcTokenPrice(endBlock));  
        maxAcctClaim = maxAcctClaim.add(bonusPercent[10].mul(maxAcctClaim).div(100));  
        maxTotalClaim = maxTotalClaim.add(maxAcctClaim);  

        totalReceived = totalReceived.add(msg.value);

        remainingCap = hardCap.sub(totalReceived);
        if(remainingCap == 0){
            finalizeAuction();  
        }
        assert(totalReceived >= msg.value);
        emit BidSubmission(_receiver, msg.value);
    }

     
    function claimTokens()
        public
        timedTransitions
        onlyWhitelisted(msg.sender)
        atStage(Stages.ClaimingStarted)
    {
        require(!claimedStatus[msg.sender], "User already claimed");
         
        require(gtxRecord.lockRecords(), "gtx records record updating must be locked");
         
        require(gtxPresale.lockRecords(), "presale record updating must be locked");

         
        fundsClaimed = fundsClaimed.add(bids[msg.sender]);

         
        uint256 accumulatedTokens = calculateTokens(msg.sender);

         
        bids[msg.sender] = 0;
        totalTokens[msg.sender] = 0;

        claimedStatus[msg.sender] = true;
        require(ERC20.transfer(msg.sender, accumulatedTokens), "transfer failed");

        emit ClaimedTokens(msg.sender, accumulatedTokens);
        assert(bids[msg.sender] == 0);
    }

     
     
    function calculateTokens(address _receiver) private returns(uint256){
         
        uint256 gtxRecordTokens = gtxRecord.claimableGTX(_receiver);

         
        uint256 gtxPresaleTokens = gtxPresale.claimableGTX(_receiver);

         
        bidTokens[_receiver] = bids[_receiver].mul(WEI_FACTOR).div(finalPrice);

         
        uint256 bonusTokens = calculateBonus(_receiver);

        uint256 auctionTokens = bidTokens[_receiver].add(bonusTokens);

        totalAuctionTokens = totalAuctionTokens.add(auctionTokens);

         
        totalTokens[msg.sender] = gtxRecordTokens.add(gtxPresaleTokens).add(auctionTokens);
        return totalTokens[msg.sender];
    }

     
     
    function finalizeAuction()
        private
    {
         
        require(remainingCap == 0 || block.number >= endBlock, "cap or block condition not met");

        stage = Stages.AuctionEnded;
        if (block.number < endBlock){
            finalPrice = calcTokenPrice(block.number);
            endBlock = block.number;
        } else {
            finalPrice = calcTokenPrice(endBlock);
        }
    }

     
     
     
    function calculateBonus(address _receiver) private view returns(uint256 bonusTokens){
        for (uint256 i=0; i < bonusThresholdWei.length; i++) {
            if(bids[_receiver] >= bonusThresholdWei[i]){
                bonusTokens = bonusPercent[i].mul(bidTokens[_receiver]).div(100);  
            }
        }
        return bonusTokens;
    }

     
     
     
     
    function calcTokenPrice(uint256 _bidBlock) public view returns(uint256){

        require(_bidBlock >= startBlock && _bidBlock <= endBlock, "pricing only given in the range of startBlock and endBlock");

        uint256 currentBlock = _bidBlock.sub(startBlock);
        uint256 decay = (currentBlock ** 3).div(priceConstant);
        return ceiling.mul(currentBlock.add(1)).div(currentBlock.add(decay).add(1));
    }

     
     
    function currentStage()
        public
        view
        returns (uint)
    {
        return uint(stage);
    }

}