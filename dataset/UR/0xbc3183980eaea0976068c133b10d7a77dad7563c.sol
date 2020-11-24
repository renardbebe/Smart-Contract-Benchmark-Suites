 

pragma solidity ^0.4.17;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}



 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
contract PresaleMidexToken is StandardToken, Ownable {

  string public constant name = "PresaleMidex";
  string public constant symbol = "PMDX";
  uint8 public constant decimals = 18;

  address public exchangeRegulatorWallet;
  address public wallet;

  uint256 public initialSupply = 10000000 * (10 ** uint256(decimals));
  uint256 public amountToken = 1 * (10 ** uint256(decimals));

  uint public startTime;
  uint public endTime;

   
  function PresaleMidexToken() {
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply;
    wallet = owner;
    exchangeRegulatorWallet = owner;
    startTime = now;
    endTime = startTime + 30 days;
  }

  function setAmountToken(uint256 _value) onlyOwnerOrRegulatorExchange {
    amountToken = _value;
  }

  function setExchangeRegulatorWallet(address _value) onlyOwner {
    exchangeRegulatorWallet = _value;
  }

  modifier onlyOwnerOrRegulatorExchange() {
    require(msg.sender == owner || msg.sender == exchangeRegulatorWallet);
    _;
  }

  function setEndTime(uint256 _value) onlyOwner {
    endTime = _value;
  }

  function setWallet(address _value) onlyOwner {
    wallet = _value;
  }

  modifier saleIsOn() {
    require(now > startTime && now < endTime);
    _;
  }

  modifier tokenAvaiable() {
    require(balances[owner] > 0);
    _;
  }

  function () payable saleIsOn tokenAvaiable {
    uint256 recieveAmount = msg.value;
    uint256 tokens = recieveAmount.div(amountToken).mul(10 ** uint256(decimals));

    assert(balances[msg.sender] + tokens >= balances[msg.sender]);

    if (balances[owner] < tokens) {
      tokens = balances[owner];
      recieveAmount = tokens.div(10 ** uint256(decimals)).mul(amountToken);
    }
    balances[msg.sender] += tokens;
    balances[owner] -= tokens;
    Transfer(owner, msg.sender, tokens);
    wallet.transfer(recieveAmount);
  }

  function burn() onlyOwner {
    address burner = msg.sender;
    uint256 quantity = balances[burner];
    totalSupply = totalSupply.sub(quantity);
    balances[burner] = 0;
    Burn(burner, quantity);
  }

  event Burn(address indexed burner, uint indexed value);

}