 

pragma solidity ^0.4.21;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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


 
contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


 
contract TokenERC20 {
  using SafeMath for uint256;

  uint256 public totalSupply;
  bool public transferable;

   
  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256)) public allowed;

   
  event Burn(address indexed from, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function balanceOf(address _owner) view public returns(uint256) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) view public returns(uint256) {
    return allowed[_owner][_spender];
  }

   
  function _transfer(address _from, address _to, uint _value) internal {
  	require(transferable);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer( _from, _to, _value);
  }

   
  function transfer(address _to, uint256 _value) public returns(bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns(bool) {
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool) {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
    return false;
  }

   
  function burn(uint256 _value) public returns(bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    return true;
  }

   
  function burnFrom(address _from, uint256 _value) public returns(bool) {
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    balances[_from] = balances[_from].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(_from, _value);
    return true;
  }
}


 
contract AIgathaToken is TokenERC20, Ownable {
  using SafeMath for uint256;

   
  string public constant name = "AIgatha Token";
  string public constant symbol = "ATH";
  uint8 public constant decimals = 18;

   
  uint256 public startDate;
  uint256 public endDate;

   
  uint256 public saleCap;

   
  address public wallet;

   
  uint256 public weiRaised;

   
  uint256 public threshold;

   
  bool public extended;

   
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
  event PreICOTokenPushed(address indexed buyer, uint256 amount);
  event UserIDChanged(address owner, bytes32 user_id);

   
  function AIgathaToken(address _wallet, uint256 _saleCap, uint256 _totalSupply, uint256 _threshold, uint256 _start, uint256 _end) public {
    wallet = _wallet;
    saleCap = _saleCap * (10 ** uint256(decimals));
    totalSupply = _totalSupply * (10 ** uint256(decimals));
    startDate = _start;
    endDate = _end;

    threshold = _threshold * totalSupply / 2 / 100;
    balances[0xbeef] = saleCap;
    balances[wallet] = totalSupply.sub(saleCap);
  }

  function supply() internal view returns (uint256) {
    return balances[0xbeef];
  }

  function saleActive() public view returns (bool) {
    return (now >= startDate &&
            now <= endDate && supply() > 0);
  }

  function extendSaleTime() onlyOwner public {
    require(!saleActive());
    require(!extended);
    require((saleCap-supply()) < threshold);  
    extended = true;
    endDate += 60 days;
  }

   
  function getRateAt(uint256 at) public view returns (uint256) {
    if (at < startDate) {
      return 0;
    }
    else if (at < (startDate + 15 days)) {  
      return 10500;
    }
    else {
      return 10000;
    }
  }

   
  function () payable public{
    buyTokens(msg.sender, msg.value);
  }

   
  function push(address buyer, uint256 amount) onlyOwner public {
    require(balances[wallet] >= amount);
    balances[wallet] = balances[wallet].sub(amount);
    balances[buyer] = balances[buyer].add(amount);
    emit PreICOTokenPushed(buyer, amount);
  }

   
  function buyTokens(address sender, uint256 value) internal {
    require(saleActive());

    uint256 weiAmount = value;
    uint256 updatedWeiRaised = weiRaised.add(weiAmount);

     
    uint256 actualRate = getRateAt(now);
    uint256 amount = weiAmount.mul(actualRate);

     
    require(supply() >= amount);

     
    balances[0xbeef] = balances[0xbeef].sub(amount);
    balances[sender] = balances[sender].add(amount);
    emit TokenPurchase(sender, weiAmount, amount);

     
    weiRaised = updatedWeiRaised;
  }

   
  function withdraw() onlyOwner public {
    wallet.transfer(address(this).balance);
  }

   
  function finalize() onlyOwner public {
    require(!saleActive());
    balances[wallet] = balances[wallet].add(balances[0xbeef]);
    balances[0xbeef] = 0;
    transferable = true;
  }
}