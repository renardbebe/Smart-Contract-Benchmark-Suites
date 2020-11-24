 

pragma solidity ^0.5.0;

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
    require(account != address(0), 'account is null');
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != address(0));
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

contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

   
  function name() public view returns(string memory) {
    return _name;
  }

   
  function symbol() public view returns(string memory) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract CraftBeerCoin is ERC20, ERC20Detailed {

    mapping (address => mapping (address => uint256)) public _confirmations;
    mapping (address => bool) public _isOwner;
    address[] public _owners;
    uint public _required;
    uint256 multiplier;

    modifier notConfirmed(address owner, address to) {
        require(_confirmations[to][owner] == 0);
        _;
    }

    modifier ownerExists(address owner) {
        require(_isOwner[owner]);
        _;
    }

    event Confirmation(address indexed sender, address indexed to, uint256 value);
    event Minted(address indexed to, uint256 value);
    event ConfirmationRevoked(address indexed sender, address indexed to);

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    )

    ERC20Detailed(name, symbol, decimals)
    ERC20() public {

        _owners = [0x460f0cc4e0fE5576b03abC1C1632EeFb5ed77fc2,
        0x5E9a0E1acd44fbC49A14bBEae88f74593e0C0f56,
        0x4B7C1eA71A85eCe00b231F6C1C31fb1Fa6910297,
        0xf03523Fe4cEebA6E28Aea8F0a5ca293FC3E787c9];

        _required = 2;

        for (uint i=0; i<_owners.length; i++) {
            _isOwner[_owners[i]] = true;
        }

        multiplier = 10 ** uint256(decimals);
    }


    function confirmMint(address to, uint256 value)
    public
    notConfirmed(msg.sender, to)
    ownerExists(msg.sender)
    {
        uint256 _value = value*multiplier;
        _confirmations[to][msg.sender] = _value;
        emit Confirmation(msg.sender, to, _value);
        executeMint(to, _value);
    }


    function executeMint(address to, uint256 value)
    internal
    returns (bool) {

        if (isConfirmed(to, value)) {

            if (resetConfirmations(to)) {

                _mint(to, value);
                emit Minted(to, value);
                return true;
            }

        }
    }


    function resetConfirmations(address to)
    internal
    returns (bool) {

        for (uint i=0; i<_owners.length; i++) {

            if (_confirmations[to][_owners[i]] != 0)
                _confirmations[to][_owners[i]] = 0;

        }

        return true;
    }


    function revokeConfirmations(address to)
    public
    ownerExists(msg.sender)
    returns (bool) {

        _confirmations[to][msg.sender] = 0;
        emit ConfirmationRevoked(msg.sender, to);
        return true;
    }

    function getConfirmation(address to)
    public
    view
    returns (uint256)
    {

        return _confirmations[to][msg.sender];
    }


    function isConfirmed(address to, uint256 value)
    internal view
    returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<_owners.length; i++) {
            if (_confirmations[to][_owners[i]] == value)
                count += 1;
            if (count == _required)
                return true;
        }
    }

    function() external payable {
        revert();
    }
}