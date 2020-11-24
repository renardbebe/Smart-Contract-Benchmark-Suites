 

pragma solidity ^0.5.3;

 
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


 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
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
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

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
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
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

   
  function _mint(address account, uint256 amount) internal {
    require(account != 0x0000000000000000000000000000000000000000);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

   
  function _burn(address account, uint256 amount) internal {
    require(account != 0x0000000000000000000000000000000000000000);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

   
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
  }
}


 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}



 
contract SlotToken is ERC20, ERC20Detailed {
    using SafeMath for uint256;
    
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(DECIMALS));
    
    mapping (address => address) private _vote_target_one;
    mapping (address => address) private _vote_target_two;
    mapping (address => uint256) private _vote_target_three;
    event VoteOne(address indexed from, address indexed to);
    event VoteTwo(address indexed from, address indexed to);
    event VoteThree(address indexed from, uint256 value);

     
    function getTypeOneHolderVote(address holder) public view returns (address) {
        return _vote_target_one[holder];
    }

     
    function setTypeOneHolderVote(address target) public returns (bool) {
        _vote_target_one[msg.sender] = target;
        
        emit VoteOne(msg.sender, target);
        return true;
    }

     
    function getTypeTwoHolderVote(address holder) public view returns (address) {
        return _vote_target_two[holder];
    }

     
    function setTypeTwoHolderVote(address target) public returns (bool) {
        _vote_target_two[msg.sender] = target;
        
        emit VoteTwo(msg.sender, target);
        return true;
    }

     
    function getTypeThreeHolderVote(address holder) public view returns (uint256) {
        return _vote_target_three[holder];
    }

     
    function setTypeThreeHolderVote(uint256 value) public returns (bool) {
        _vote_target_three[msg.sender] = value;
        
        emit VoteThree(msg.sender, value);
        return true;
    }

     
    constructor (address communityGovAddress, address econSupportAddress, uint256 econSupportAmount) public ERC20Detailed("Alphaslot", "SLOT", DECIMALS) {
        require(econSupportAmount > 0);
        require(communityGovAddress != address(0));
        require(econSupportAddress != address(0));
        require(econSupportAmount<INITIAL_SUPPLY && INITIAL_SUPPLY-econSupportAmount>0);
        uint256 communityGovAmount = INITIAL_SUPPLY - econSupportAmount;
        require(communityGovAmount<INITIAL_SUPPLY && econSupportAmount+communityGovAmount == INITIAL_SUPPLY);
        
        _mint(communityGovAddress, communityGovAmount);
        _mint(econSupportAddress, econSupportAmount);
    }
}