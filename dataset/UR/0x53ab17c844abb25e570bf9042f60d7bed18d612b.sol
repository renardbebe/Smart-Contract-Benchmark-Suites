 

pragma solidity ^0.4.24;

 
contract Ownable {
  address public owner;
  address public newOwnerCandidate;

  event OwnerUpdate(address prevOwner, address newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier ownerOnly {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwnerCandidate) public ownerOnly {
    require(_newOwnerCandidate != address(0));
    require(_newOwnerCandidate != owner);
    newOwnerCandidate = _newOwnerCandidate;
  }

   
  function acceptOwnership() public {
    require(msg.sender == newOwnerCandidate);
    emit OwnerUpdate(owner, newOwnerCandidate);
    owner = newOwnerCandidate;
    newOwnerCandidate = address(0);
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

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) internal _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 internal _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

     
    require(value == 0 || _allowed[msg.sender][spender] == 0);

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }
}

 

contract MintableToken is ERC20, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event Burn(address indexed from, uint256 amount);

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address to, uint256 amount) public ownerOnly canMint returns (bool) {
    require(to != address(0));
    
    _totalSupply = _totalSupply.add(amount);
    _balances[to] = _balances[to].add(amount);
    emit Mint(to, amount);
    emit Transfer(address(0), to, amount);
    return true;
  }

     
  function burn(address from, uint256 amount) public ownerOnly canMint returns (bool) {
    require(from != address(0));

    _totalSupply = _totalSupply.sub(amount);
    _balances[from] = _balances[from].sub(amount);
    emit Burn(from, amount);
    emit Transfer(from, address(0), amount);
  }

   
  function finishMinting() public ownerOnly canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

contract FreezableToken is ERC20, Ownable {

  event TransfersEnabled();

  bool public allowTransfers = false;

   
  modifier canTransfer() {
    require(allowTransfers || msg.sender == owner);
    _;
  }

   
  function enableTransfers() public ownerOnly {
    allowTransfers = true;
    emit TransfersEnabled();
  }

   
  function transfer(address to, uint256 value) public canTransfer returns (bool) {
    return super.transfer(to, value);
  }

   
  function transferFrom(address from, address to, uint256 value) public canTransfer returns (bool) {
    return super.transferFrom(from, to, value);
  }
}

 
contract CappedToken is MintableToken {

  uint256 public constant cap = 1000000000000000000000000000;

   
  function mint(
    address to,
    uint256 amount
  )
    public
    returns (bool)
  {
    require(_totalSupply.add(amount) <= cap);

    return super.mint(to, amount);
  }

}

 
contract VeganCoin is CappedToken, FreezableToken {

  string public name = "VeganCoin"; 
  string public symbol = "VCN";
  uint8 public decimals = 18;
}

 
contract VestingTrustee is Ownable {
    using SafeMath for uint256;

     
    VeganCoin public veganCoin;

    struct Grant {
        uint256 value;
        uint256 start;
        uint256 cliff;
        uint256 end;
        uint256 transferred;
        bool revokable;
    }

     
    mapping (address => Grant) public grants;

     
    uint256 public totalVesting;

    event NewGrant(address indexed _from, address indexed _to, uint256 _value);
    event UnlockGrant(address indexed _holder, uint256 _value);
    event RevokeGrant(address indexed _holder, uint256 _refund);

     
     
    constructor(VeganCoin _veganCoin) public {
        require(_veganCoin != address(0));

        veganCoin = _veganCoin;
    }

     
     
     
     
     
     
     
    function grant(address _to, uint256 _value, uint256 _start, uint256 _cliff, uint256 _end, bool _revokable)
        public ownerOnly {
        require(_to != address(0));
        require(_value > 0);

         
        require(grants[_to].value == 0);

         
        require(_start <= _cliff && _cliff <= _end);

         
        require(totalVesting.add(_value) <= veganCoin.balanceOf(address(this)));

         
        grants[_to] = Grant({
            value: _value,
            start: _start,
            cliff: _cliff,
            end: _end,
            transferred: 0,
            revokable: _revokable
        });

         
        totalVesting = totalVesting.add(_value);

        emit NewGrant(msg.sender, _to, _value);
    }

     
     
    function revoke(address _holder) public ownerOnly {
        Grant storage grant = grants[_holder];

        require(grant.revokable);

         
        uint256 refund = grant.value.sub(grant.transferred);

         
        delete grants[_holder];

        totalVesting = totalVesting.sub(refund);

        emit RevokeGrant(_holder, refund);
    }

     
     
     
     
    function vestedTokens(address _holder, uint256 _time) public constant returns (uint256) {
        Grant storage grant = grants[_holder];
        if (grant.value == 0) {
            return 0;
        }

        return calculateVestedTokens(grant, _time);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function calculateVestedTokens(Grant _grant, uint256 _time) private pure returns (uint256) {
         
        if (_time < _grant.cliff) {
            return 0;
        }

         
        if (_time >= _grant.end) {
            return _grant.value;
        }

         
         return _grant.value.mul(_time.sub(_grant.start)).div(_grant.end.sub(_grant.start));
    }

     
     
    function unlockVestedTokens() public {
        Grant storage grant = grants[msg.sender];
        require(grant.value != 0);

         
        uint256 vested = calculateVestedTokens(grant, now);
        if (vested == 0) {
            return;
        }

         
        uint256 transferable = vested.sub(grant.transferred);
        if (transferable == 0) {
            return;
        }

        grant.transferred = grant.transferred.add(transferable);
        totalVesting = totalVesting.sub(transferable);
        veganCoin.transfer(msg.sender, transferable);

        emit UnlockGrant(msg.sender, transferable);
    }
}