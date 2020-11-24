 

pragma solidity ^0.4.25;

 
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint pointMultiplier = 1e18;
  mapping (address => uint) lastDivPoints;
  uint totalDivPoints = 0;

  string[] public divMessages;

  event DividendsTransferred(address account, uint amount);
  event DividendsAdded(uint amount, string message);

  function divsOwing(address _addr) public view returns (uint) {
    uint newDivPoints = totalDivPoints.sub(lastDivPoints[_addr]);
    return balances[_addr].mul(newDivPoints).div(pointMultiplier);
  }

  function updateAccount(address account) internal {
    uint owing = divsOwing(account);
    if (owing > 0) {
      account.transfer(owing);
      emit DividendsTransferred(account, owing);
    }
    lastDivPoints[account] = totalDivPoints;
  }

  function payDividends(string message) payable public onlyOwner {
    uint weiAmount = msg.value;
    require(weiAmount>0);

    divMessages.push(message);

    totalDivPoints = totalDivPoints.add(weiAmount.mul(pointMultiplier).div(totalSupply));
    emit DividendsAdded(weiAmount, message);
  }

  function getLastDivMessage() public view returns (string, uint) {
    return (divMessages[divMessages.length - 1], divMessages.length);
  }

  function claimDividends() public {
    updateAccount(msg.sender);
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    
    updateAccount(msg.sender);
    updateAccount(_to);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    updateAccount(_from);
    updateAccount(_to);

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}


 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public onlyOwner {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        updateAccount(msg.sender);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
}

contract NetCurrencyIndexToken is BurnableToken {

    string public constant name = "NetCurrencyIndex";
    string public constant symbol = "NCI500";
    uint public constant decimals = 18;
     
    uint256 public constant initialSupply = 50000000 * (10 ** uint256(decimals));

     
    constructor () public {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;  
        emit Transfer(0x0,msg.sender,initialSupply);
    }

    struct Rate {
      uint256 current_rate;
      string remark;
      uint256 time;
    }

    Rate[] public rates;

     
    function update_current_rate(uint256 current_rate, string remark) public onlyOwner{
      Rate memory rate = Rate({current_rate: current_rate, remark: remark, time: now});
      rates.push(rate);
    }

    function getLastRate() public view returns (uint, string, uint, uint) {
    Rate memory rate = rates[rates.length - 1];
      return (rate.current_rate, rate.remark, rate.time, rates.length);
    }
}