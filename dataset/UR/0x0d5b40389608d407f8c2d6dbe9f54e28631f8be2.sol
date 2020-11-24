 

pragma solidity ^0.4.24;

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns (address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

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

 
contract ERC20 is IERC20, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => bool) private _frozen;

  mapping(address => mapping(address => uint256)) private _allowed;

  uint256 private _totalSupply = 10000000000000000000000000000;

  constructor() public {
    _balances[address(this)] = _totalSupply;
    emit Transfer(address(0x0), address(this), _totalSupply);
  }

   
  function freeze(address _address, bool _boolean) external onlyOwner {
    _frozen[_address] = _boolean;
  }

   
  function isFrozen(address owner) public view returns (bool) {
    return _frozen[owner];
  }

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(address owner, address spender) public view returns (uint256){
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    require(!isFrozen(msg.sender));
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(address from, address to, uint256 value) public returns (bool){
    require(value <= _allowed[from][msg.sender]);
    require(!isFrozen(from));

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool){
    require(spender != address(0));

    _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool){
    require(spender != address(0));

    _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
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

   
  function transferTokens(address to, uint256 value) external onlyOwner {
    require(value <= _balances[address(this)]);
    require(to != address(0));

    _balances[address(this)] = _balances[address(this)].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(address(this), to, value);
  }

   
  function airdrop(address[] to, uint256[] value) external onlyOwner {
    require(to.length == value.length);
    for (uint i = 0; i < to.length; i++) {
      _transfer(address(this), to[i], value[i]);
    }
  }

  event Mint(address indexed receiver, uint256 value);

   
  function mint(address toAddress, uint256 value) external onlyOwner returns (bool){
    _balances[toAddress] = _balances[toAddress].add(value);
    _totalSupply = _totalSupply.add(value);
    emit Mint(toAddress, value);
    return true;
  }

  event Burn(address indexed burner, uint256 value);

   
  function burnFrom(address fromAddress, uint256 value) external onlyOwner returns (bool) {
    _balances[fromAddress] = _balances[fromAddress].sub(value);
    _totalSupply = _totalSupply.sub(value);
    emit Burn(fromAddress, value);
    return true;
  }
}

contract UbaiCoin is ERC20 {
  string constant public name = "UBAI COIN";
  string constant public symbol = "UBAICOIN";
  uint256 constant public decimals = 18;
}