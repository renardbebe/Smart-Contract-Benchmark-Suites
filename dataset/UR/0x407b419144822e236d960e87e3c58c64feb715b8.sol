 

pragma solidity ^0.4.25;  

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(
    address _from,
    uint256 _value,
    bytes _data
  )
    external
    pure
  {
    _from;
    _value;
    _data;
    revert();
  }

}

 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address _contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(_contractAddr);
    contractInst.transferOwnership(owner);
  }
}

 
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

 
contract Pausable is Ownable {
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

 
contract Authorizable is Ownable {

     
    mapping (address => bool) public authorized;

     
    event Authorize(address indexed who);

     
    event UnAuthorize(address indexed who);

     
    modifier onlyAuthorized() {
        require(msg.sender == owner || authorized[msg.sender], "Not Authorized.");
        _;
    }

     
    function authorize(address _who) public onlyOwner {
        require(_who != address(0), "Address can't be zero.");
        require(!authorized[_who], "Already authorized");

        authorized[_who] = true;
        emit Authorize(_who);
    }

     
    function unAuthorize(address _who) public onlyOwner {
        require(_who != address(0), "Address can't be zero.");
        require(authorized[_who], "Address is not authorized");

        authorized[_who] = false;
        emit UnAuthorize(_who);
    }
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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract HoldersToken is StandardToken {
    using SafeMath for uint256;    

     
    address[] public holders;

     
    mapping (address => uint256) public holderNumber;

     
    function holdersCount() public view returns (uint256) {
        return holders.length;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        _preserveHolders(msg.sender, _to, _value);
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _preserveHolders(_from, _to, _value);
        return super.transferFrom(_from, _to, _value);
    }

     
    function _removeHolder(address _holder) internal {
        uint256 _number = holderNumber[_holder];

        if (_number == 0 || holders.length == 0 || _number > holders.length)
            return;

        uint256 _index = _number.sub(1);
        uint256 _lastIndex = holders.length.sub(1);
        address _lastHolder = holders[_lastIndex];

        if (_index != _lastIndex) {
            holders[_index] = _lastHolder;
            holderNumber[_lastHolder] = _number;
        }

        holderNumber[_holder] = 0;
        holders.length = _lastIndex;
    } 

     
    function _addHolder(address _holder) internal {
        if (holderNumber[_holder] == 0) {
            holders.push(_holder);
            holderNumber[_holder] = holders.length;
        }
    }

     
    function _preserveHolders(address _from, address _to, uint256 _value) internal {
        _addHolder(_to);   
        if (balanceOf(_from).sub(_value) == 0) 
            _removeHolder(_from);
    }
}

 
contract PlatinTGE {
    using SafeMath for uint256;
    
     
    uint8 public constant decimals = 18;  

     
    uint256 public constant TOTAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));  

     
     
    uint256 public constant SALES_SUPPLY = 300000000 * (10 ** uint256(decimals));  
    uint256 public constant MINING_POOL_SUPPLY = 200000000 * (10 ** uint256(decimals));  
    uint256 public constant FOUNDERS_AND_EMPLOYEES_SUPPLY = 200000000 * (10 ** uint256(decimals));  
    uint256 public constant AIRDROPS_POOL_SUPPLY = 100000000 * (10 ** uint256(decimals));  
    uint256 public constant RESERVES_POOL_SUPPLY = 100000000 * (10 ** uint256(decimals));  
    uint256 public constant ADVISORS_POOL_SUPPLY = 70000000 * (10 ** uint256(decimals));  
    uint256 public constant ECOSYSTEM_POOL_SUPPLY = 30000000 * (10 ** uint256(decimals));  

     
    address public PRE_ICO_POOL;  
    address public LIQUID_POOL;  
    address public ICO;  
    address public MINING_POOL;  
    address public FOUNDERS_POOL;  
    address public EMPLOYEES_POOL;  
    address public AIRDROPS_POOL;  
    address public RESERVES_POOL;  
    address public ADVISORS_POOL;  
    address public ECOSYSTEM_POOL;  

     
     
    uint256 public constant PRE_ICO_POOL_AMOUNT = 20000000 * (10 ** uint256(decimals));  
    uint256 public constant LIQUID_POOL_AMOUNT = 100000000 * (10 ** uint256(decimals));  
    uint256 public constant ICO_AMOUNT = 180000000 * (10 ** uint256(decimals));  
     
    uint256 public constant FOUNDERS_POOL_AMOUNT = 190000000 * (10 ** uint256(decimals));  
    uint256 public constant EMPLOYEES_POOL_AMOUNT = 10000000 * (10 ** uint256(decimals));  

     
    address public UNSOLD_RESERVE;  

     
    uint256 public constant ICO_LOCKUP_PERIOD = 182 days;
    
     
    uint256 public constant TOKEN_RATE = 1000; 

     
    uint256 public constant TOKEN_RATE_LOCKUP = 1200;

     
    uint256 public constant MIN_PURCHASE_AMOUNT = 1 ether;

     
    PlatinToken public token;

     
    uint256 public tgeTime;


       
    constructor(
        uint256 _tgeTime,
        PlatinToken _token, 
        address _preIcoPool,
        address _liquidPool,
        address _ico,
        address _miningPool,
        address _foundersPool,
        address _employeesPool,
        address _airdropsPool,
        address _reservesPool,
        address _advisorsPool,
        address _ecosystemPool,
        address _unsoldReserve
    ) public {
        require(_tgeTime >= block.timestamp, "TGE time should be >= current time.");  
        require(_token != address(0), "Token address can't be zero.");
        require(_preIcoPool != address(0), "PreICO Pool address can't be zero.");
        require(_liquidPool != address(0), "Liquid Pool address can't be zero.");
        require(_ico != address(0), "ICO address can't be zero.");
        require(_miningPool != address(0), "Mining Pool address can't be zero.");
        require(_foundersPool != address(0), "Founders Pool address can't be zero.");
        require(_employeesPool != address(0), "Employees Pool address can't be zero.");
        require(_airdropsPool != address(0), "Airdrops Pool address can't be zero.");
        require(_reservesPool != address(0), "Reserves Pool address can't be zero.");
        require(_advisorsPool != address(0), "Advisors Pool address can't be zero.");
        require(_ecosystemPool != address(0), "Ecosystem Pool address can't be zero.");
        require(_unsoldReserve != address(0), "Unsold reserve address can't be zero.");

         
        tgeTime = _tgeTime;

         
        token = _token;

         
        PRE_ICO_POOL = _preIcoPool;
        LIQUID_POOL = _liquidPool;
        ICO = _ico;
        MINING_POOL = _miningPool;
        FOUNDERS_POOL = _foundersPool;
        EMPLOYEES_POOL = _employeesPool;
        AIRDROPS_POOL = _airdropsPool;
        RESERVES_POOL = _reservesPool;
        ADVISORS_POOL = _advisorsPool;
        ECOSYSTEM_POOL = _ecosystemPool;

         
        UNSOLD_RESERVE = _unsoldReserve; 
    }

     
    function allocate() public {

         
        require(block.timestamp >= tgeTime, "Should be called just after tge time.");  

         
        require(token.totalSupply() == 0, "Allocation is already done.");

         
        token.allocate(PRE_ICO_POOL, PRE_ICO_POOL_AMOUNT);
        token.allocate(LIQUID_POOL, LIQUID_POOL_AMOUNT);
        token.allocate(ICO, ICO_AMOUNT);
      
         
        token.allocate(MINING_POOL, MINING_POOL_SUPPLY);

         
        token.allocate(FOUNDERS_POOL, FOUNDERS_POOL_AMOUNT);
        token.allocate(EMPLOYEES_POOL, EMPLOYEES_POOL_AMOUNT);

         
        token.allocate(AIRDROPS_POOL, AIRDROPS_POOL_SUPPLY);

         
        token.allocate(RESERVES_POOL, RESERVES_POOL_SUPPLY);

         
        token.allocate(ADVISORS_POOL, ADVISORS_POOL_SUPPLY);

         
        token.allocate(ECOSYSTEM_POOL, ECOSYSTEM_POOL_SUPPLY);

         
        require(token.totalSupply() == TOTAL_SUPPLY, "Total supply check error.");   
    }
}

 
contract PlatinToken is HoldersToken, NoOwner, Authorizable, Pausable {
    using SafeMath for uint256;

    string public constant name = "Platin Token";  
    string public constant symbol = "PTNX";  
    uint8 public constant decimals = 18;  
 
     
    struct Lockup {
        uint256 release;  
        uint256 amount;  
    }

     
    mapping (address => Lockup[]) public lockups;

     
    mapping (address => mapping (address => Lockup[])) public refundable;

     
    mapping (address => mapping (address => mapping (uint256 => uint256))) public indexes;    

     
    PlatinTGE public tge;

     
    event Allocate(address indexed to, uint256 amount);

     
    event SetLockups(address indexed to, uint256 amount, uint256 fromIdx, uint256 toIdx);

     
    event Refund(address indexed from, address indexed to, uint256 amount);

     
    modifier spotTransfer(address _from, uint256 _value) {
        require(_value <= balanceSpot(_from), "Attempt to transfer more than balance spot.");
        _;
    }

     
    modifier onlyTGE() {
        require(msg.sender == address(tge), "Only TGE method.");
        _;
    }

     
    function setTGE(PlatinTGE _tge) external onlyOwner {
        require(tge == address(0), "TGE is already set.");
        require(_tge != address(0), "TGE address can't be zero.");
        tge = _tge;
        authorize(_tge);
    }        

      
    function allocate(address _to, uint256 _amount) external onlyTGE {
        require(_to != address(0), "Allocate To address can't be zero");
        require(_amount > 0, "Allocate amount should be > 0.");
       
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        _addHolder(_to);

        require(totalSupply_ <= tge.TOTAL_SUPPLY(), "Can't allocate more than TOTAL SUPPLY.");

        emit Allocate(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }  

     
    function transfer(address _to, uint256 _value) public whenNotPaused spotTransfer(msg.sender, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused spotTransfer(_from, _value) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function transferWithLockup(
        address _to, 
        uint256 _value, 
        uint256[] _lockupReleases,
        uint256[] _lockupAmounts,
        bool _refundable
    ) 
    public onlyAuthorized returns (bool)
    {        
        transfer(_to, _value);
        _lockup(_to, _value, _lockupReleases, _lockupAmounts, _refundable);  
    }       

     
    function transferFromWithLockup(
        address _from, 
        address _to, 
        uint256 _value, 
        uint256[] _lockupReleases,
        uint256[] _lockupAmounts,
        bool _refundable
    ) 
    public onlyAuthorized returns (bool)
    {
        transferFrom(_from, _to, _value);
        _lockup(_to, _value, _lockupReleases, _lockupAmounts, _refundable);  
    }     

     
    function refundLockedUp(
        address _from
    )
    public onlyAuthorized returns (uint256)
    {
        address _sender = msg.sender;
        uint256 _balanceRefundable = 0;
        uint256 _refundableLength = refundable[_from][_sender].length;
        if (_refundableLength > 0) {
            uint256 _lockupIdx;
            for (uint256 i = 0; i < _refundableLength; i++) {
                if (refundable[_from][_sender][i].release > block.timestamp) {  
                    _balanceRefundable = _balanceRefundable.add(refundable[_from][_sender][i].amount);
                    refundable[_from][_sender][i].release = 0;
                    refundable[_from][_sender][i].amount = 0;
                    _lockupIdx = indexes[_from][_sender][i];
                    lockups[_from][_lockupIdx].release = 0;
                    lockups[_from][_lockupIdx].amount = 0;       
                }    
            }

            if (_balanceRefundable > 0) {
                _preserveHolders(_from, _sender, _balanceRefundable);
                balances[_from] = balances[_from].sub(_balanceRefundable);
                balances[_sender] = balances[_sender].add(_balanceRefundable);
                emit Refund(_from, _sender, _balanceRefundable);
                emit Transfer(_from, _sender, _balanceRefundable);
            }
        }
        return _balanceRefundable;
    }

     
    function lockupsCount(address _who) public view returns (uint256) {
        return lockups[_who].length;
    }

     
    function hasLockups(address _who) public view returns (bool) {
        return lockups[_who].length > 0;
    }

     
    function balanceLockedUp(address _who) public view returns (uint256) {
        uint256 _balanceLokedUp = 0;
        uint256 _lockupsLength = lockups[_who].length;
        for (uint256 i = 0; i < _lockupsLength; i++) {
            if (lockups[_who][i].release > block.timestamp)  
                _balanceLokedUp = _balanceLokedUp.add(lockups[_who][i].amount);
        }
        return _balanceLokedUp;
    }

     
    function balanceRefundable(address _who, address _sender) public view returns (uint256) {
        uint256 _balanceRefundable = 0;
        uint256 _refundableLength = refundable[_who][_sender].length;
        if (_refundableLength > 0) {
            for (uint256 i = 0; i < _refundableLength; i++) {
                if (refundable[_who][_sender][i].release > block.timestamp)  
                    _balanceRefundable = _balanceRefundable.add(refundable[_who][_sender][i].amount);
            }
        }
        return _balanceRefundable;
    }

     
    function balanceSpot(address _who) public view returns (uint256) {
        uint256 _balanceSpot = balanceOf(_who);
        _balanceSpot = _balanceSpot.sub(balanceLockedUp(_who));
        return _balanceSpot;
    }

          
    function _lockup(
        address _who, 
        uint256 _amount, 
        uint256[] _lockupReleases,
        uint256[] _lockupAmounts,
        bool _refundable) 
    internal 
    {
        require(_lockupReleases.length == _lockupAmounts.length, "Length of lockup releases and amounts lists should be equal.");
        require(_lockupReleases.length.add(lockups[_who].length) <= 1000, "Can't be more than 1000 lockups per address.");
        if (_lockupReleases.length > 0) {
            uint256 _balanceLokedUp = 0;
            address _sender = msg.sender;
            uint256 _fromIdx = lockups[_who].length;
            uint256 _toIdx = _fromIdx + _lockupReleases.length - 1;
            uint256 _lockupIdx;
            uint256 _refundIdx;
            for (uint256 i = 0; i < _lockupReleases.length; i++) {
                if (_lockupReleases[i] > block.timestamp) {  
                    lockups[_who].push(Lockup(_lockupReleases[i], _lockupAmounts[i]));
                    _balanceLokedUp = _balanceLokedUp.add(_lockupAmounts[i]);
                    if (_refundable) {
                        refundable[_who][_sender].push(Lockup(_lockupReleases[i], _lockupAmounts[i]));
                        _lockupIdx = lockups[_who].length - 1;
                        _refundIdx = refundable[_who][_sender].length - 1;
                        indexes[_who][_sender][_refundIdx] = _lockupIdx;
                    }
                }
            }

            require(_balanceLokedUp <= _amount, "Can't lockup more than transferred amount.");
            emit SetLockups(_who, _amount, _fromIdx, _toIdx);  
        }            
    }      
}