 

 
 
pragma solidity ^0.4.18;

 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 
contract SchedulableToken is StandardToken, BurnableToken {
  using SafeMath for uint256;

  event Released(uint256 amount);

  address public beneficiary;
  uint256 public maxSupply;
  uint256 public start;
  uint256 public duration;

   
  function SchedulableToken(address _beneficiary, uint256 _maxSupply, uint256 _duration) public {
    require(_beneficiary != address(0));
    require(_maxSupply > 0);
    require(_duration > 0);

    beneficiary = _beneficiary;
    maxSupply = _maxSupply;
    duration = _duration;
    start = now;
  }

   
  function release() public {
    uint256 amount = calculateAmountToRelease();
    require(amount > 0);

    balances[beneficiary] = balances[beneficiary].add(amount);
    totalSupply = totalSupply.add(amount);

    Released(amount);
  }

   
  function calculateAmountToRelease() public view returns (uint256) {
    if (now < start.add(duration)) {
      return maxSupply.mul(now.sub(start)).div(duration).sub(totalSupply);
    } else {
      return schedulableAmount();
    }
  }

   
  function schedulableAmount() public view returns (uint256) {
    return maxSupply.sub(totalSupply);
  }

   
  function burn(uint256 _value) public {
    super.burn(_value);
    maxSupply = maxSupply.sub(_value);
  }
}

 
 contract LetsfairToken is SchedulableToken {

  string public constant name = "Letsfair";
  string public constant symbol = "LTF";
  uint8 public constant decimals = 18;

  address _beneficiary = 0xe0F158B382F30A1eccecb5B67B1cf7EB92B5f1E4;
  uint256 _maxSupply = 10 ** 27;  
  uint256 _duration = 157788000;  

  function LetsfairToken() SchedulableToken(_beneficiary, _maxSupply, _duration) public {}
}