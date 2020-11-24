 

pragma solidity  ^0.4.18;

 
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

pragma solidity  ^0.4.18;

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner returns (bool) {
    require(newOwner != address(0));
    owner = newOwner;
    OwnershipTransferred(owner, newOwner);
    return true;
  }

}

pragma solidity  ^0.4.18;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity  ^0.4.18;

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  
   
  mapping(address => uint256) balances;

  uint256 public totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply;
  } 

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

pragma solidity  ^0.4.18;

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity  ^0.4.18;

 
contract CustomToken is ERC20, BasicToken, Ownable {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  bool public enableTransfer = true;

   
  modifier whenTransferEnabled() {
    require(enableTransfer);
    _;
  }

  event Burn(address indexed burner, uint256 value);
  event EnableTransfer(address indexed owner, uint256 timestamp);
  event DisableTransfer(address indexed owner, uint256 timestamp);

  
   
  function transfer(address _to, uint256 _value) whenTransferEnabled public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) whenTransferEnabled public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);


    if (msg.sender!=owner) {
      require(_value <= allowed[_from][msg.sender]);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
    }  else {
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
    }

    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) whenTransferEnabled public returns (bool) {
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function approveAndCallAsContract(address _spender, uint256 _value, bytes _extraData) onlyOwner public returns (bool success) {
     
     
     

    allowed[this][_spender] = _value;
    Approval(this, _spender, _value);

     
     
     
    require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), this, _value, this, _extraData));
    return true;
  }

   
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) whenTransferEnabled public returns (bool success) {
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);

     
     
     
    require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) whenTransferEnabled public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) whenTransferEnabled public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


   
  function burn(address _burner, uint256 _value) onlyOwner public returns (bool) {
    require(_value <= balances[_burner]);
     
     

    balances[_burner] = balances[_burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(_burner, _value);
    return true;
  }
    
  function enableTransfer() onlyOwner public returns (bool) {
    enableTransfer = true;
    EnableTransfer(owner, now);
    return true;
  }

   
  function disableTransfer() onlyOwner whenTransferEnabled public returns (bool) {
    enableTransfer = false;
    DisableTransfer(owner, now);
    return true;
  }
}


pragma solidity  ^0.4.18;
 
 
contract Identify is CustomToken {

  string public constant name = "IDENTIFY";
  string public constant symbol = "IDF"; 
  uint8 public constant decimals = 6;

  uint256 public constant INITIAL_SUPPLY = 49253333333 * (10 ** uint256(decimals));

   
  function Identify() public {
    totalSupply = INITIAL_SUPPLY;
    balances[this] = INITIAL_SUPPLY;
    Transfer(0x0, this, INITIAL_SUPPLY);
  }

}