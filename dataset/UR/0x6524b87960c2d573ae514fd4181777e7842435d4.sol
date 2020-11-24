 

 

pragma solidity ^0.4.21;

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public payable returns (bool);
}

library Math {
  function max64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a >= _b ? _a : _b;
  }

  function min64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a < _b ? _a : _b;
  }

  function max256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a >= _b ? _a : _b;
  }

  function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }
}

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

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
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

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
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

contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
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


contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic _token) public {
    uint256 unreleased = releasableAmount(_token);

    require(unreleased > 0);

    released[_token] = released[_token].add(unreleased);

    _token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

   
  function revoke(ERC20Basic _token) public onlyOwner {
    require(revocable);
    require(!revoked[_token]);

    uint256 balance = _token.balanceOf(address(this));

    uint256 unreleased = releasableAmount(_token);
    uint256 refund = balance.sub(unreleased);

    revoked[_token] = true;

    _token.safeTransfer(owner, refund);

    emit Revoked();
  }

   
  function releasableAmount(ERC20Basic _token) public view returns (uint256) {
    return vestedAmount(_token).sub(released[_token]);
  }

   
  function vestedAmount(ERC20Basic _token) public view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(released[_token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[_token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}


contract TokenPool {
    ERC20Basic public token;

    modifier poolReady {
        require(token != address(0));
        _;
    }

    function setToken(ERC20Basic newToken) public {
        require(token == address(0));

        token = newToken;
    }

    function balance() view public returns (uint256) {
        return token.balanceOf(this);
    }

    function transferTo(address dst, uint256 amount) internal returns (bool) {
        return token.transfer(dst, amount);
    }

    function getFrom() view public returns (address) {
        return this;
    }
}

contract AdvisorPool is TokenPool, Ownable {

    function addVestor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 totalTokens
    ) public onlyOwner poolReady returns (TokenVesting) {
        TokenVesting vesting = new TokenVesting(_beneficiary, _start, _cliff, _duration, false);

        transferTo(vesting, totalTokens);

        return vesting;
    }

    function transfer(address _beneficiary, uint256 amount) public onlyOwner poolReady returns (bool) {
        return transferTo(_beneficiary, amount);
    }
}

contract TeamPool is TokenPool, Ownable {

    mapping(address => TokenVesting[]) cache;

    function addVestor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 totalTokens,
        bool revokable
    ) public onlyOwner poolReady returns (TokenVesting) {
        cache[_beneficiary].push(new TokenVesting(_beneficiary, _start, _cliff, _duration, revokable));

        uint newIndex = cache[_beneficiary].length - 1;

        transferTo(cache[_beneficiary][newIndex], totalTokens);

        return cache[_beneficiary][newIndex];
    }

    function vestingCount(address _beneficiary) public view poolReady returns (uint) {
        return cache[_beneficiary].length;
    }

    function revoke(address _beneficiary, uint index) public onlyOwner poolReady {
        require(index < vestingCount(_beneficiary));
        require(cache[_beneficiary][index] != address(0));

        cache[_beneficiary][index].revoke(token);
    }
}

contract StandbyGamePool is TokenPool, Ownable {
    TokenPool public currentVersion;
    bool public ready = false;

    function update(TokenPool newAddress) onlyOwner public {
        require(!ready);
        ready = true;
        currentVersion = newAddress;
        transferTo(newAddress, balance());
    }

    function() public payable {
        require(ready);
        if(!currentVersion.delegatecall(msg.data)) revert();
    }
}

contract TokenUpdate is StandardBurnableToken, DetailedERC20 {
    event Mint(address indexed to, uint256 amount);
    
    mapping(address => bool) internal _legacyTokens;
    
    address internal defaultLegacyToken;
    
    function _mint(address _to, uint256 _amount) internal returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
                
     
   function migrate(address token, address account, uint256 amount) public {
       require(_legacyTokens[token]);
       
       StandardBurnableToken legacyToken = StandardBurnableToken(token);
       
       legacyToken.burnFrom(account, amount);
       _mint(account, amount); 
   }

   
  function migrateAll(address token, address account) public {
      require(_legacyTokens[token]);
       
      StandardBurnableToken legacyToken = StandardBurnableToken(token);
       
      uint256 balance = legacyToken.balanceOf(account);
      uint256 allowance = legacyToken.allowance(account, this);
      uint256 amount = Math.min256(balance, allowance);
      migrate(token, account, amount);
  }
  
  function migrateAll(address account) public {
      migrateAll(defaultLegacyToken, account);
  }
}


contract BenzeneToken is TokenUpdate, ApproveAndCallFallBack {
    using SafeMath for uint256;

    string public constant name = "Benzene";
    string public constant symbol = "BZN";
    uint8 public constant decimals = 18;

    address public GamePoolAddress;
    address public TeamPoolAddress;
    address public AdvisorPoolAddress;

    constructor(address gamePool,
                address teamPool,  
                address advisorPool,
                address oldTeamPool,
                address oldAdvisorPool,
                address[] oldBzn) public DetailedERC20(name, symbol, decimals) {
        
        require(oldBzn.length > 0);
        
        DetailedERC20 _legacyToken;  
        for (uint i = 0; i < oldBzn.length; i++) {
             
            _legacyToken = DetailedERC20(oldBzn[i]);
            
             
            _legacyTokens[oldBzn[i]] = true;
        }
        
        defaultLegacyToken = _legacyToken;
        
        GamePoolAddress = gamePool;
        
        uint256 teampool_balance =  _legacyToken.balanceOf(oldTeamPool);
        require(teampool_balance > 0);  
        balances[teamPool] = teampool_balance;
        totalSupply_ = totalSupply_.add(teampool_balance);
        TeamPoolAddress = teamPool;

        
        uint256 advisor_balance =  _legacyToken.balanceOf(oldAdvisorPool);
        require(advisor_balance > 0);  
        balances[advisorPool] = advisor_balance;
        totalSupply_ = totalSupply_.add(advisor_balance);
        AdvisorPoolAddress = advisorPool;
                    
        TeamPool(teamPool).setToken(this);
        AdvisorPool(advisorPool).setToken(this);
    }
  
  function approveAndCall(address spender, uint tokens, bytes memory data) public payable returns (bool success) {
      super.approve(spender, tokens);
      
      ApproveAndCallFallBack toCall = ApproveAndCallFallBack(spender);
      
      require(toCall.receiveApproval.value(msg.value)(msg.sender, tokens, address(this), data));
      
      return true;
  }
  
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public payable returns (bool) {
      super.migrate(token, from, tokens);
      
      return true;
  }
}