 

pragma solidity ^0.4.18;

 
contract Ownable {
  address public owner;

   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}
 
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  event PrivateFundEnabled();
  event PrivateFundDisabled();

  bool public paused = false;
  bool public privateFundEnabled = true;

   
  modifier whenPrivateFundDisabled() {
    require(!privateFundEnabled);
    _;
  }
  
   
  modifier whenPrivateFundEnabled() {
    require(privateFundEnabled);
    _;
  }

   
  function disablePrivateFund() onlyOwner whenPrivateFundEnabled public {
    privateFundEnabled = false;
    emit PrivateFundDisabled();
  }

   
  function enablePrivateFund() onlyOwner whenPrivateFundDisabled public {
    privateFundEnabled = true;
    emit PrivateFundEnabled();
  }

   
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

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GlobalSharingEconomyCoin is Pausable, ERC20 {
  using SafeMath for uint256;
  event BatchTransfer(address indexed owner, bool value);

  string public name;
  string public symbol;
  uint8 public decimals;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  mapping (address => bool) allowedBatchTransfers;

  constructor() public {
    name = "GlobalSharingEconomyCoin";
    symbol = "GSE";
    decimals = 8;
    totalSupply = 10000000000 * 10 ** uint256(decimals);
    balances[msg.sender] = totalSupply;
    allowedBatchTransfers[msg.sender] = true;
  }

  function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function setBatchTransfer(address _address, bool _value) public onlyOwner returns (bool) {
    allowedBatchTransfers[_address] = _value;
    emit BatchTransfer(_address, _value);
    return true;
  }

  function getBatchTransfer(address _address) public onlyOwner view returns (bool) {
    return allowedBatchTransfers[_address];
  }

   
  function airdrop(address[] _funds, uint256 _amount) public whenNotPaused whenPrivateFundEnabled returns (bool) {
    require(allowedBatchTransfers[msg.sender]);
    uint256 fundslen = _funds.length;
     
    require(fundslen > 0 && fundslen < 300);
    
    uint256 totalAmount = 0;
    for (uint i = 0; i < fundslen; ++i){
      balances[_funds[i]] = balances[_funds[i]].add(_amount);
      totalAmount = totalAmount.add(_amount);
      emit Transfer(msg.sender, _funds[i], _amount);
    }

     
    require(balances[msg.sender] >= totalAmount);
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    return true;
  }

   
  function batchTransfer(address[] _funds, uint256[] _amounts) public whenNotPaused whenPrivateFundEnabled returns (bool) {
    require(allowedBatchTransfers[msg.sender]);
    uint256 fundslen = _funds.length;
    uint256 amountslen = _amounts.length;
    require(fundslen == amountslen && fundslen > 0 && fundslen < 300);

    uint256 totalAmount = 0;
    for (uint i = 0; i < amountslen; ++i){
      totalAmount = totalAmount.add(_amounts[i]);
    }

    require(balances[msg.sender] >= totalAmount);
    for (uint j = 0; j < amountslen; ++j) {
      balances[_funds[j]] = balances[_funds[j]].add(_amounts[j]);
      emit Transfer(msg.sender, _funds[j], _amounts[j]);
    }
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}