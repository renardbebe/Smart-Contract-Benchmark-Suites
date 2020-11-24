 

pragma solidity 0.4.24;

 
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address who) public view returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  function allowance(address owner, address spender) public view returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract HetaToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  string private constant _name = "HetaToken";  
  string private constant _symbol = "HETA";  
  uint8 private constant _decimals = 18;  
  uint256 private _totalSupply;

  address private _owner;
  bool private _paused;

  event Paused();
  event Unpaused();

  event Burn(address indexed burner, uint256 value);

  constructor() public {
    _paused = false;
    _owner = msg.sender;
    _totalSupply = 60000000000 * (10 ** uint256(_decimals));
    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

   
  function name() public pure returns(string) {
    return _name;
  }

   
  function symbol() public pure returns(string) {
    return _symbol;
  }

   
  function decimals() public pure returns(uint8) {
    return _decimals;
  }

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

   
  function ownerTransfer(address to, uint256 value) public onlyOwner returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function batchTransfer(address[] tos, uint256[] values) public whenNotPaused returns (bool) {
      require(tos.length == values.length);

      uint256 arrayLength = tos.length;
      for(uint256 i = 0; i < arrayLength; i++) {
        require(transfer(tos[i], values[i]));
      }

      return true;
  }

   
  function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
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

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Burn(account, value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
    _burn(account, value);
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  function pause() public onlyOwner whenNotPaused {
    _paused = true;
    emit Paused();
  }

   
  function unpause() public onlyOwner whenPaused {
    _paused = false;
    emit Unpaused();
  }

}