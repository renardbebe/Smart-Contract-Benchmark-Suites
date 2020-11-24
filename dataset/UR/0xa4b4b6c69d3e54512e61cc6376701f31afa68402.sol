 

pragma solidity 0.4.25;

 
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
	function balanceOf(address owner) external view returns (uint256 balance);
	function transfer(address to, uint256 value) external returns (bool success);
	function transferFrom(address from, address to, uint256 value) external returns (bool success);
	function approve(address spender, uint256 value) external returns (bool success);
	function allowance(address owner, address spender) external view returns (uint256 remaining);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Issuance(address indexed to, uint256 value);
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
    _transfer(msg.sender, to, value);
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
    require(value <= _allowed[from][msg.sender]);

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
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

contract ERC20Burnable is ERC20 {

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

contract Owned {

	address public owner = msg.sender;
	address public potentialOwner;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	modifier onlyPotentialOwner {
		require(msg.sender == potentialOwner);
		_;
	}

	event NewOwner(address old, address current);
	event NewPotentialOwner(address old, address potential);

	function setOwner(address _new)
		public
		onlyOwner
	{
		emit NewPotentialOwner(owner, _new);
		potentialOwner = _new;
	}

	function confirmOwnership()
		public
		onlyPotentialOwner
	{
		emit NewOwner(owner, potentialOwner);
		owner = potentialOwner;
		potentialOwner = address(0);
	}
}

contract Token is ERC20Burnable, Owned {

	 
	uint256 public creationTime;

	constructor() public {
		 
		creationTime = now;
	}

	 
	function transferERC20Token(IERC20 _token, address _to, uint256 _value)
		public
		onlyOwner
		returns (bool success)
	{
		require(_token.balanceOf(address(this)) >= _value);
		uint256 receiverBalance = _token.balanceOf(_to);
		require(_token.transfer(_to, _value));

		uint256 receiverNewBalance = _token.balanceOf(_to);
		assert(receiverNewBalance == receiverBalance + _value);

		return true;
	}
}

contract FluenceToken is Token {

    string constant public name = 'Fluence Presale Token Test';
    string constant public symbol = 'FPT-Test';
    uint8  constant public decimals = 18;

    uint256 constant public presale_tokens = 6000000e18;

    bool public is_vesting_enabled = true;
    mapping (address => uint256) public vested_tokens;

     
    uint256 checkpoint;

    address crowdsale_manager;
    address migration_manager;

    modifier onlyCrowdsaleManager {
        require(msg.sender == crowdsale_manager);
        _;
    }

    modifier onlyDuringVestingPeriod {
        require(is_vesting_enabled);
        _;
    }

    function vest(uint256 amount) public onlyDuringVestingPeriod {
        _transfer(msg.sender, address(this), amount);
        vested_tokens[msg.sender] += amount;
    }

    function unvest(uint256 amount) public {
        require(on_vesting(msg.sender) >= amount);
        
        uint256 tokens_to_unvest = (amount * 100) / (100 + _get_bonus());
        _transfer(address(this), msg.sender, tokens_to_unvest);
        vested_tokens[msg.sender] -= tokens_to_unvest;
        _mint(msg.sender, amount - tokens_to_unvest);
    }

    function disableVesting() public onlyCrowdsaleManager {
        is_vesting_enabled = false;
    }

    function payoutFirstBonus() public onlyCrowdsaleManager {
        require(checkpoint == 0);
        checkpoint = now;
    }

    function setCrowdsaleManager(address manager) public onlyOwner {
        crowdsale_manager = manager;
    }

    function setMigrationManager(address manager) public onlyOwner {
        require(migration_manager == 0);
        migration_manager = manager;
        _mint(migration_manager, presale_tokens);
    }

    function on_vesting(address account) public view returns (uint256) {
        return vested_tokens[account] * (100 + _get_bonus()) / 100;
    }

    function _get_bonus() internal view returns (uint256) {
        if (checkpoint == 0) {
            return 0;
        }
        uint256 initial_bonus = 5;
        uint256 months_passed = (now - checkpoint) / (30 days);
        uint256 additional_bonus = (months_passed > 4 ? 4: months_passed) * 5;  
        return initial_bonus + additional_bonus;
    }
}