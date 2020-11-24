 

pragma solidity 0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
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

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
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
    uint _addedValue
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
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

contract ShopinToken is StandardToken, Ownable, Pausable {
    using SafeMath for uint256;

    string public constant name = "Shopin Token";  
    string public constant symbol = "SHOPIN";  
    uint8 public constant decimals = 18;  

    mapping (address => bool) whitelist;
    mapping (address => bool) blacklist;

    uint private unlockTime;

    event AddedToWhitelist(address indexed _addr);
    event RemovedFromWhitelist(address indexed _addr);
    event AddedToBlacklist(address indexed _addr);
    event RemovedFromBlacklist(address indexed _addr);
    event SetNewUnlockTime(uint newUnlockTime);

    constructor(
        uint256 _totalSupply,
        uint256 _unlockTime
    )
        Ownable()
        public
    {
        require(_totalSupply > 0);
        require(_unlockTime > 0 && _unlockTime > now);

        totalSupply_ = _totalSupply;
        unlockTime = _unlockTime;
        balances[msg.sender] = totalSupply_;
        emit Transfer(0x0, msg.sender, totalSupply_);
    }

    modifier whenNotPausedOrInWhitelist() {
        require(
            !paused || isWhitelisted(msg.sender) || msg.sender == owner,
            "contract paused and sender is not in whitelist"
        );
        _;
    }

     
    function transfer(
        address _to,
        uint _value
    )
        public
        whenNotPausedOrInWhitelist()
        returns (bool)
    {
        require(_to != address(0));
        require(msg.sender != address(0));

        require(!isBlacklisted(msg.sender));
        require(isUnlocked() ||
                isWhitelisted(msg.sender) ||
                msg.sender == owner);

        return super.transfer(_to, _value);

    }

     
    function addToBlacklist(
        address _addr
    ) onlyOwner public returns (bool) {
        require(_addr != address(0));
        require(!isBlacklisted(_addr));

        blacklist[_addr] = true;
        emit AddedToBlacklist(_addr);
        return true;
    }

     
    function removeFromBlacklist(
        address _addr
    ) onlyOwner public returns (bool) {
        require(_addr != address(0));
        require(isBlacklisted(_addr));

        blacklist[_addr] = false;
        emit RemovedFromBlacklist(_addr);
        return true;
    }

     
    function addToWhitelist(
        address _addr
    ) onlyOwner public returns (bool) {
        require(_addr != address(0));
        require(!isWhitelisted(_addr));

        whitelist[_addr] = true;
        emit AddedToWhitelist(_addr);
        return true;
    }

     
    function removeFromWhitelist(
        address _addr
    ) onlyOwner public returns (bool) {
        require(_addr != address(0));
        require(isWhitelisted(_addr));

        whitelist[_addr] = false;
        emit RemovedFromWhitelist(_addr);
        return true;
    }

    function isBlacklisted(address _addr)
        internal
        view
        returns (bool)
    {
        require(_addr != address(0));
        return blacklist[_addr];
    }

     
    function isWhitelisted(address _addr)
        internal
        view
        returns (bool)
    {
        require(_addr != address(0));
        return whitelist[_addr];
    }

     
    function getUnlockTime() public view returns (uint) {
        return unlockTime;
    }

     
    function setUnlockTime(uint newUnlockTime) onlyOwner public returns (bool)
    {
        unlockTime = newUnlockTime;
        emit SetNewUnlockTime(unlockTime);
    }

     
    function isUnlocked() public view returns (bool) {
        return (getUnlockTime() >= now);
    }
}