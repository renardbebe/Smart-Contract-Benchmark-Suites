 

pragma solidity 0.4.25;

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

interface IOldManager {
    function released(address investor) external view returns (uint256);
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

contract Manager is Owned {
    using SafeMath for uint256;

    event InvestorVerified(address investor);
    event VerificationRevoked(address investor);

    mapping (address => bool) public verified_investors;
    mapping (address => uint256) public released;

    IOldManager public old_manager;
    ERC20Burnable public old_token;
    IERC20 public presale_token;
    IERC20 public new_token;

    modifier onlyVerifiedInvestor {
        require(verified_investors[msg.sender]);
        _;
    }

    constructor(IOldManager _old_manager, ERC20Burnable _old_token, IERC20 _presale_token, IERC20 _new_token) public {
        old_manager = _old_manager;
        old_token = _old_token;
        presale_token = _presale_token;
        new_token = _new_token;
    }

    function updateVerificationStatus(address investor, bool is_verified) public onlyOwner {
        require(verified_investors[investor] != is_verified);

        verified_investors[investor] = is_verified;
        if (is_verified) emit InvestorVerified(investor);
        if (!is_verified) emit VerificationRevoked(investor);
    }

    function migrate() public onlyVerifiedInvestor {
        uint256 tokens_to_transfer = old_token.allowance(msg.sender, address(this));
        require(tokens_to_transfer > 0);
        require(old_token.transferFrom(msg.sender, address(this), tokens_to_transfer));
        old_token.burn(tokens_to_transfer);
        _transferTokens(msg.sender, tokens_to_transfer);
    }

    function release() public onlyVerifiedInvestor {
        uint256 presale_tokens = presale_token.balanceOf(msg.sender);
        uint256 tokens_to_release = presale_tokens - totalReleased(msg.sender);
        require(tokens_to_release > 0);
        _transferTokens(msg.sender, tokens_to_release);
        released[msg.sender] = tokens_to_release;
    }

    function totalReleased(address investor) public view returns (uint256) {
        return released[investor] + old_manager.released(investor);
    }

    function _transferTokens(address recipient, uint256 amount) internal {
        uint256 initial_balance = new_token.balanceOf(recipient);
        require(new_token.transfer(recipient, amount));
        assert(new_token.balanceOf(recipient) == initial_balance + amount);
    }
}