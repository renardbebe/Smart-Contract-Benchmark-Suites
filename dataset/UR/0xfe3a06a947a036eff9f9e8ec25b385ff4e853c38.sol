 

pragma solidity ^0.4.25;

 
library SafeMath {
   
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
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
}

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 
contract Pausable is Claimable {
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }
}

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 
contract JZMLock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
     
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
     
    require(block.timestamp >= releaseTime);
    uint256 amount = token.balanceOf(address(this));
    require(amount > 0);
    token.safeTransfer(beneficiary, amount);
  }
  
  function canRelease() public view returns (bool){
    return block.timestamp >= releaseTime;
  }
}

 
contract JZMToken is PausableToken {

    event TransferWithLock(address indexed from, address indexed to, address indexed locked, uint256 amount, uint256 releaseTime);
    
    mapping (address => address[] ) public balancesLocked;

    function transferWithLock(address _to, uint256 _amount, uint256 _releaseTime) public returns (bool) {
        JZMLock lock = new JZMLock(this, _to, _releaseTime);
        transfer(address(lock), _amount);
        balancesLocked[_to].push(lock);
        emit TransferWithLock(msg.sender, _to, address(lock), _amount, _releaseTime);
        return true;
    }

     
    function balanceOfLocked(address _owner) public view returns (uint256) {
        address[] memory lockTokenAddrs = balancesLocked[_owner];

        uint256 totalLockedBalance = 0;
        for (uint i = 0; i < lockTokenAddrs.length; i++) {
            totalLockedBalance = totalLockedBalance.add(balances[lockTokenAddrs[i]]);
        }
        
        return totalLockedBalance;
    }

    function releaseToken(address _owner) public returns (bool) {
        address[] memory lockTokenAddrs = balancesLocked[_owner];
        for (uint i = 0; i < lockTokenAddrs.length; i++) {
            JZMLock lock = JZMLock(lockTokenAddrs[i]);
            if (lock.canRelease() && balanceOf(lock)>0) {
                lock.release();
            }
        }
        return true;
    }
}

 
contract TUToken is JZMToken {
    using SafeMath for uint256;

    string public constant name = "Trust Union";
    string public constant symbol = "TUT";
    uint8 public constant decimals = 18;

    uint256 private constant TOKEN_UNIT = 10 ** uint256(decimals);
    uint256 private constant INITIAL_SUPPLY = (10 ** 9) * TOKEN_UNIT;

     
    address private constant ADDR_MARKET          = 0xEd3998AA7F255Ade06236776f9FD429eECc91357;
    address private constant ADDR_FOUNDTEAM       = 0x1867812567f42e2Da3C572bE597996B1309593A7;
    address private constant ADDR_ECO             = 0xF7549be7449aA2b7D708d39481fCBB618C9Fb903;
    address private constant ADDR_PRIVATE_SALE    = 0x252c4f77f1cdCCEBaEBbce393804F4c8f3D5703D;
    address private constant ADDR_SEED_INVESTOR   = 0x03a59D08980A5327a958860e346d020ec8bb33dC;
    address private constant ADDR_FOUNDATION      = 0xC138d62b3E34391964852Cf712454492DC7eFF68;

     
    uint256 private constant S_MARKET_TOTAL = INITIAL_SUPPLY * 5 / 100;
    uint256 private constant S_MARKET_20181030 = 5000000  * TOKEN_UNIT;
    uint256 private constant S_MARKET_20190130 = 10000000 * TOKEN_UNIT;
    uint256 private constant S_MARKET_20190430 = 15000000 * TOKEN_UNIT;
    uint256 private constant S_MARKET_20190730 = 20000000 * TOKEN_UNIT;

     
    uint256 private constant S_FOUNDTEAM_TOTAL = INITIAL_SUPPLY * 15 / 100;
    uint256 private constant S_FOUNDTEAM_20191030 = INITIAL_SUPPLY * 5 / 100;
    uint256 private constant S_FOUNDTEAM_20200430 = INITIAL_SUPPLY * 5 / 100;
    uint256 private constant S_FOUNDTEAM_20201030 = INITIAL_SUPPLY * 5 / 100;

     
    uint256 private constant S_ECO_TOTAL = INITIAL_SUPPLY * 40 / 100;
    uint256 private constant S_ECO_20190401 = 45000000 * TOKEN_UNIT;
    uint256 private constant S_ECO_20191001 = 45000000 * TOKEN_UNIT;
    uint256 private constant S_ECO_20200401 = 40000000 * TOKEN_UNIT;
    uint256 private constant S_ECO_20201001 = 40000000 * TOKEN_UNIT;
    uint256 private constant S_ECO_20210401 = 35000000 * TOKEN_UNIT;
    uint256 private constant S_ECO_20211001 = 35000000 * TOKEN_UNIT;
    uint256 private constant S_ECO_20220401 = 30000000 * TOKEN_UNIT;
    uint256 private constant S_ECO_20221001 = 30000000 * TOKEN_UNIT;
    uint256 private constant S_ECO_20230401 = 25000000 * TOKEN_UNIT;
    uint256 private constant S_ECO_20231001 = 25000000 * TOKEN_UNIT;
    uint256 private constant S_ECO_20240401 = 25000000 * TOKEN_UNIT;
    uint256 private constant S_ECO_20241001 = 25000000 * TOKEN_UNIT;

     
    uint256 private constant S_PRIVATE_SALE = INITIAL_SUPPLY * 10 / 100;

     
    uint256 private constant S_SEED_INVESTOR = INITIAL_SUPPLY * 10 / 100;

     
    uint256 private constant S_FOUNDATION = INITIAL_SUPPLY * 20 / 100;
    
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[owner] = totalSupply_;

        _initWallet();
        _invokeLockLogic();
    }

     
    function _initWallet() internal onlyOwner {
        transfer(ADDR_PRIVATE_SALE, S_PRIVATE_SALE);
        transfer(ADDR_SEED_INVESTOR, S_SEED_INVESTOR);
        transfer(ADDR_FOUNDATION, S_FOUNDATION);
    }

     
    function _invokeLockLogic() internal onlyOwner {
         
         
        transferWithLock(ADDR_MARKET, S_MARKET_20181030, 1540828800);
         
        transferWithLock(ADDR_MARKET, S_MARKET_20190130, 1548777600); 
         
        transferWithLock(ADDR_MARKET, S_MARKET_20190430, 1556553600);
         
        transferWithLock(ADDR_MARKET, S_MARKET_20190730, 1564416000);
        
         
         
        transferWithLock(ADDR_FOUNDTEAM, S_FOUNDTEAM_20191030, 1572364800);
         
        transferWithLock(ADDR_FOUNDTEAM, S_FOUNDTEAM_20200430, 1588176000);
         
        transferWithLock(ADDR_FOUNDTEAM, S_FOUNDTEAM_20201030, 1603987200);
        
         
         
        transferWithLock(ADDR_ECO, S_ECO_20190401, 1554048000);
         
        transferWithLock(ADDR_ECO, S_ECO_20191001, 1569859200);
         
        transferWithLock(ADDR_ECO, S_ECO_20200401, 1585670400);
         
        transferWithLock(ADDR_ECO, S_ECO_20201001, 1601481600);
         
        transferWithLock(ADDR_ECO, S_ECO_20210401, 1617206400);
         
        transferWithLock(ADDR_ECO, S_ECO_20211001, 1633017600);
         
        transferWithLock(ADDR_ECO, S_ECO_20220401, 1648742400);
         
        transferWithLock(ADDR_ECO, S_ECO_20221001, 1664553600);
         
        transferWithLock(ADDR_ECO, S_ECO_20230401, 1680278400);
         
        transferWithLock(ADDR_ECO, S_ECO_20231001, 1696089600);
         
        transferWithLock(ADDR_ECO, S_ECO_20240401, 1711900800);
         
        transferWithLock(ADDR_ECO, S_ECO_20241001, 1727712000);
    }
}