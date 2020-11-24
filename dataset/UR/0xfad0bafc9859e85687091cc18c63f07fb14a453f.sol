 

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
contract Ownable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    _owner = msg.sender;
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
    emit OwnershipRenounced(_owner);
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
contract FINPointRecord is Ownable {
    using SafeMath for uint256;

     
     
     
    uint256 public claimRate;

     
     
    mapping (address => uint256) public claimableFIN;

    event FINRecordCreate(
        address indexed _recordAddress,
        uint256 _finPointAmount,
        uint256 _finERC20Amount
    );

    event FINRecordUpdate(
        address indexed _recordAddress,
        uint256 _finPointAmount,
        uint256 _finERC20Amount
    );

    event FINRecordMove(
        address indexed _oldAddress,
        address indexed _newAddress,
        uint256 _finERC20Amount
    );

    event ClaimRateSet(uint256 _claimRate);

     
    modifier canRecord() {
        require(claimRate > 0);
        _;
    }
     
    function setClaimRate(uint256 _claimRate) public onlyOwner{
        require(_claimRate <= 1000);  
        require(_claimRate >= 100);  
        claimRate = _claimRate;
        emit ClaimRateSet(claimRate);
    }

     
    function recordCreate(address _recordAddress, uint256 _finPointAmount, bool _applyClaimRate) public onlyOwner canRecord {
        require(_finPointAmount >= 100000);  

        uint256 finERC20Amount;

        if(_applyClaimRate == true) {
            finERC20Amount = _finPointAmount.mul(claimRate).div(100);
        } else {
            finERC20Amount = _finPointAmount;
        }

        claimableFIN[_recordAddress] = claimableFIN[_recordAddress].add(finERC20Amount);

        emit FINRecordCreate(_recordAddress, _finPointAmount, claimableFIN[_recordAddress]);
    }

     
    function recordUpdate(address _recordAddress, uint256 _finPointAmount, bool _applyClaimRate) public onlyOwner canRecord {
        require(_finPointAmount >= 100000);  

        uint256 finERC20Amount;

        if(_applyClaimRate == true) {
            finERC20Amount = _finPointAmount.mul(claimRate).div(100);
        } else {
            finERC20Amount = _finPointAmount;
        }

        claimableFIN[_recordAddress] = finERC20Amount;

        emit FINRecordUpdate(_recordAddress, _finPointAmount, claimableFIN[_recordAddress]);
    }

     
    function recordMove(address _oldAddress, address _newAddress) public onlyOwner canRecord {
        require(claimableFIN[_oldAddress] != 0);
        require(claimableFIN[_newAddress] == 0);

        claimableFIN[_newAddress] = claimableFIN[_oldAddress];
        claimableFIN[_oldAddress] = 0;

        emit FINRecordMove(_oldAddress, _newAddress, claimableFIN[_newAddress]);
    }

     
    function recordGet(address _recordAddress) public view returns (uint256) {
        return claimableFIN[_recordAddress];
    }

     
    function () public payable {
        revert (); 
    }  

}
contract Claimable is Ownable {
     
    FINPointRecord public finPointRecordContract;

     
    mapping (address => bool) public isMinted;

    event RecordSourceTransferred(
        address indexed previousRecordContract,
        address indexed newRecordContract
    );


     
    constructor(FINPointRecord _finPointRecordContract) public {
        finPointRecordContract = _finPointRecordContract;
    }


     
    function transferRecordSource(FINPointRecord _newRecordContract) public onlyOwner {
        _transferRecordSource(_newRecordContract);
    }

     
    function _transferRecordSource(FINPointRecord _newRecordContract) internal {
        require(_newRecordContract != address(0));
        emit RecordSourceTransferred(finPointRecordContract, _newRecordContract);
        finPointRecordContract = _newRecordContract;
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
    event Approval(address indexed owner,address indexed spender,uint256 value);

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
     
    TimeLock public timeLockContract;

     
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
contract TimeLock {
     
    MintableToken public ERC20Contract;
     
    struct accountData {
        uint256 balance;
        uint256 releaseTime;
    }

    event Lock(address indexed _tokenLockAccount, uint256 _lockBalance, uint256 _releaseTime);
    event UnLock(address indexed _tokenUnLockAccount, uint256 _unLockBalance, uint256 _unLockTime);

     
    mapping (address => accountData) public accounts;

     

    constructor(MintableToken _ERC20Contract) public {
        ERC20Contract = _ERC20Contract;
    }

    function timeLockTokens(uint256 _lockTimeS) public {

        uint256 lockAmount = ERC20Contract.allowance(msg.sender, this);  


        require(lockAmount != 0);  

        if (accounts[msg.sender].balance > 0) {  
            accounts[msg.sender].balance = SafeMath.add(accounts[msg.sender].balance, lockAmount);
      } else {  
            accounts[msg.sender].balance = lockAmount;
            accounts[msg.sender].releaseTime = SafeMath.add(block.timestamp, _lockTimeS);
        }

        emit Lock(msg.sender, lockAmount, accounts[msg.sender].releaseTime);

        ERC20Contract.transferFrom(msg.sender, this, lockAmount);

    }

    function tokenRelease() public {
         
        require (accounts[msg.sender].balance != 0 && accounts[msg.sender].releaseTime <= block.timestamp);
        uint256 transferUnlockedBalance = accounts[msg.sender].balance;
        accounts[msg.sender].balance = 0;
        accounts[msg.sender].releaseTime = 0;
        emit UnLock(msg.sender, transferUnlockedBalance, block.timestamp);
        ERC20Contract.transfer(msg.sender, transferUnlockedBalance);
    }

     
    function getERC20() public view returns (address) {
        return ERC20Contract;
    }
}
contract FINERC20Migrate is Ownable {
    using SafeMath for uint256;

     
     

    mapping (address => uint256) public migratableFIN;
    
    MintableToken public ERC20Contract;

    constructor(MintableToken _finErc20) public {
        ERC20Contract = _finErc20;
    }   

     
     
    event FINMigrateRecordUpdate(
        address indexed _account,
        uint256 _totalMigratableFIN
    ); 

     
    function initiateMigration(uint256 _balanceToMigrate) public {
        uint256 migratable = ERC20Contract.migrateTransfer(msg.sender, _balanceToMigrate);
        migratableFIN[msg.sender] = migratableFIN[msg.sender].add(migratable);
        emit FINMigrateRecordUpdate(msg.sender, migratableFIN[msg.sender]);
    }

     
    function getFINMigrationRecord(address _account) public view returns (uint256) {
        return migratableFIN[_account];
    }

     
    function getERC20() public view returns (address) {
        return ERC20Contract;
    }
}
contract MintableToken is StandardToken, Claimable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event SetMigrationAddress(address _finERC20MigrateAddress);
    event SetTimeLockAddress(address _timeLockAddress);
    event MigrationStarted();
    event Migrated(address indexed account, uint256 amount);

    bool public mintingFinished = false;

     
    FINERC20Migrate public finERC20MigrationContract;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    modifier onlyMigrate {
        require(msg.sender == address(finERC20MigrationContract));
        _;
    }

     
    constructor(FINPointRecord _finPointRecordContract, string _name, string _symbol, uint8 _decimals)

    public
    Claimable(_finPointRecordContract)
    StandardToken(_name, _symbol, _decimals) {

    }

    
    function () public payable {
        revert (); 
    }  

     
    function mintAllowance(address _ethAddress) public onlyOwner {
        require(finPointRecordContract.recordGet(_ethAddress) != 0);
        require(isMinted[_ethAddress] == false);
        isMinted[_ethAddress] = true;
        mint(msg.sender, finPointRecordContract.recordGet(_ethAddress));
        approve(_ethAddress, finPointRecordContract.recordGet(_ethAddress));
    }

     
    function mint(
        address _to,
        uint256 _amount
    )
        private
        canMint
        returns (bool)
    {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    
    function setMigrationAddress(FINERC20Migrate _finERC20MigrationContract) public onlyOwner returns (bool) {
         
        require(_finERC20MigrationContract.getERC20() == address(this));

        finERC20MigrationContract = _finERC20MigrationContract;
        emit SetMigrationAddress(_finERC20MigrationContract);
        return true;
    }

    
    function setTimeLockAddress(TimeLock _timeLockContract) public onlyOwner returns (bool) {
         
        require(_timeLockContract.getERC20() == address(this));

        timeLockContract = _timeLockContract;
        emit SetTimeLockAddress(_timeLockContract);
        return true;
    }

    
    function startMigration() onlyOwner public returns (bool) {
        require(migrationStart == false);
         
        require(finERC20MigrationContract != address(0));
         
        require(timeLockContract != address(0));

        migrationStart = true;
        emit MigrationStarted();

        return true;
    }

     
    function migrateTransfer(address _account, uint256 _amount) onlyMigrate public returns (uint256) {

        require(migrationStart == true);

        uint256 userBalance = balanceOf(_account);
        require(userBalance >= _amount);

        emit Migrated(_account, _amount);

        balances[_account] = balances[_account].sub(_amount);

        return _amount;
    }

}