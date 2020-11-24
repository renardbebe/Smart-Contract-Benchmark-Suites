 

pragma solidity ^0.4.9;

 
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
    require(_value <= balances[msg.sender]);

     
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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

 
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    assert(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    assert(!halted);
    _;
  }

  modifier onlyInEmergency {
    assert(halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}


contract YobiToken is StandardToken, Haltable {

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;


     
    function name() constant returns (string _name) {
        return name;
    }
     
    function symbol() constant returns (string _symbol) {
        return symbol;
    }
     
    function decimals() constant returns (uint8 _decimals) {
        return decimals;
    }
     
    function totalSupply() constant returns (uint256 _totalSupply) {
        return totalSupply;
    }

    address public beneficiary1;
    address public beneficiary2;
    event Buy(address indexed participant, uint tokens, uint eth);
    event GoalReached(uint amountRaised);

    uint public softCap = 50000000000000;
    uint public hardCap = 100000000000000;
    bool public softCapReached = false;
    bool public hardCapReached = false;

    uint public price;
    uint public collectedTokens;
    uint public collectedEthers;

    uint public tokensSold = 0;
    uint public weiRaised = 0;
    uint public investorCount = 0;

    uint public startTime;
    uint public endTime;

   
    function YobiToken() {

        name = "yobi";
        symbol = "YOB";
        decimals = 8;
        totalSupply = 10000000000000000;

        beneficiary1 = 0x2cC988E5A0D8d0163a241F68Fe35Bc97E0923e72;
        beneficiary2 = 0xF5A4DEb2a685F5D3f859Df6A771CC4CC4f3c3435;

        balances[beneficiary1] = totalSupply;

        price = 600;
        startTime = 1509426000;
        endTime = startTime + 3 weeks;

    }

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) onlyOwner public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

    modifier onlyAfter(uint time) {
        assert(now >= time);
        _;
    }

    modifier onlyBefore(uint time) {
        assert(now <= time);
        _;
    }

    function () payable stopInEmergency {
        doPurchase();
    }

    function doPurchase() private onlyAfter(startTime) onlyBefore(endTime) {

        assert(!hardCapReached);

        uint tokens = msg.value * price / 10000000000;

        if (balanceOf(msg.sender) == 0) investorCount++;

        balances[beneficiary1] = balances[beneficiary1].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);

        collectedTokens = collectedTokens.add(tokens);
        collectedEthers = collectedEthers.add(msg.value);

        if (collectedTokens >= softCap) {
            softCapReached = true;
        }

        if (collectedTokens >= hardCap) {
            hardCapReached = true;
        }

        weiRaised = weiRaised.add(msg.value);
        tokensSold = tokensSold.add(tokens);

        Transfer(beneficiary1, msg.sender, tokens);

        Buy(msg.sender, tokens, msg.value);

    }

    function withdraw() returns (bool) {
        assert((now >= endTime) || softCapReached);
        assert((msg.sender == beneficiary1) || (msg.sender == beneficiary2));
        if (!beneficiary1.send(collectedEthers * 99 / 100)) {
            return false;
        }
        if (!beneficiary2.send(collectedEthers / 100)) {
            return false;
        }
        return true;
    }


}