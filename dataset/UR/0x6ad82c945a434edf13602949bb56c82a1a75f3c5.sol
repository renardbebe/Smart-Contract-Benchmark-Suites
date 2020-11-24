 

pragma solidity ^0.4.24;

 
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

  event TransferWithData(address indexed from, address indexed to, uint value, bytes data);

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


   

  function transfer(address _to, uint _value, bytes _data) external returns (bool) {
     
     
    uint codeLength;

    require(_value / 1000000000000000000 >= 1);

    assembly {
     
      codeLength := extcodesize(_to)
    }

    _balances[msg.sender] = _balances[msg.sender].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    if (codeLength > 0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);

      receiver.tokenFallback(msg.sender, _value, _to);
    }
    emit TransferWithData(msg.sender, _to, _value, _data);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transfer(address _to, uint _value) external returns (bool) {
    uint codeLength;
    bytes memory empty;

    require(_value / 1000000000000000000 >= 1);

    assembly {
     
      codeLength := extcodesize(_to)
    }

    _balances[msg.sender] = _balances[msg.sender].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    if (codeLength > 0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
      receiver.tokenFallback(msg.sender, _value, address(this));
    }

    emit Transfer(msg.sender, _to, _value);
    emit TransferWithData(msg.sender, _to, _value, empty);
    return true;
  }


   
  function transferByCrowdSale(address _to, uint _value) external returns (bool) {
    bytes memory empty;

    require(_value / 1000000000000000000 >= 1);

    _balances[msg.sender] = _balances[msg.sender].sub(_value);
    _balances[_to] = _balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
    emit TransferWithData(msg.sender, _to, _value, empty);
    return true;
  }

  function _transferGasByOwner(address _from, address _to, uint256 _value) internal {
    _balances[_from] = _balances[_from].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
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
    emit TransferWithData(from, to, value, '');
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit TransferWithData(address(0), account, value, '');
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit TransferWithData(account, address(0), value, '');
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}


 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
  internal
  view
  returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}


contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() public {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}


 
contract ERC20Mintable is ERC20, MinterRole {
   
  function mint(
    address to,
    uint256 value
  )
  public
  onlyMinter
  returns (bool)
  {
    _mint(to, value);
    return true;
  }

  function transferGasByOwner(address _from, address _to, uint256 _value) public onlyMinter returns (bool) {
    super._transferGasByOwner(_from, _to, _value);
    return true;
  }
}


 
contract CryptoMusEstate is ERC20Mintable {

  string public constant name = "Mus#1";
  string public constant symbol = "MUS#1";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 1000 * (10 ** uint256(decimals));

   
  constructor() public {
    mint(msg.sender, INITIAL_SUPPLY);
  }

}


 
contract CryptoMusKRW is ERC20Mintable {

  string public constant name = "CryptoMus KRW Stable Token";
  string public constant symbol = "KRWMus";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(decimals));

   
  constructor() public {
    mint(msg.sender, INITIAL_SUPPLY);
  }

}



 
contract Ownable {
  address private _owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    _owner = msg.sender;
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
    emit OwnershipRenounced(_owner);
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

 
contract ERC223ReceivingContract is Ownable {
  using SafeMath for uint256;

   
  CryptoMusEstate private _token;
   
  CryptoMusKRW private _krwToken;

   
  address private _wallet;
  address private _krwTokenAddress;

   
   
   
   
  uint256 private _rate;

   
  uint256 private _weiRaised;

   
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 rate, CryptoMusEstate token, CryptoMusKRW krwToken) public {
    require(rate > 0);

    require(token != address(0));

    _rate = rate;
    _wallet = msg.sender;
    _token = token;
    _krwToken = krwToken;
    _krwTokenAddress = krwToken;
  }

   
   
   


  function tokenFallback(address _from, uint _value, address _to) public {

    if(_krwTokenAddress != _to) {
    } else {
      buyTokens(_from, _value);
    }
  }

   
  function token() public view returns (CryptoMusEstate) {
    return _token;
  }

   
  function wallet() public view returns (address) {
    return _wallet;
  }

   
  function rate() public view returns (uint256) {
    return _rate;
  }

  function setRate(uint256 setRate) public onlyOwner returns (uint256)
  {
    _rate = setRate;
    return _rate;
  }

   
  function weiRaised() public view returns (uint256) {
    return _weiRaised;
  }

   
  function buyTokens(address beneficiary, uint _value) public {

    uint256 weiAmount = _value;
    _preValidatePurchase(beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    _weiRaised = _weiRaised.add(weiAmount);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(beneficiary, weiAmount);

    _forwardFunds(_value);
    _postValidatePurchase(beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
  internal
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
  internal
  {
     
  }

   
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  )
  internal
  {
    _token.transferByCrowdSale(beneficiary, tokenAmount);
  }

   
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
  internal
  {
    _deliverTokens(beneficiary, tokenAmount);
  }

   
  function _updatePurchasingState(
    address beneficiary,
    uint256 weiAmount
  )
  internal
  {
     
  }

   
  function _getTokenAmount(uint256 weiAmount)
  internal view returns (uint256)
  {
    return weiAmount.mul(_rate);
  }

   
  function _forwardFunds(uint _value) internal {

    _krwToken.transferByCrowdSale(_wallet, _value);
  }
}