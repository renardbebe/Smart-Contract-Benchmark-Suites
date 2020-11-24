 

pragma solidity ^0.4.18;

contract TokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract ApproveAndCallToken is StandardToken {
  function approveAndCall(address _spender, uint _value, bytes _data) public returns (bool) {
    TokenRecipient spender = TokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _data);
      return true;
    }
    return false;
  }

   
  function transfer(address _to, uint _value) public returns (bool success) { 
     
     
    bytes memory empty;
    if (isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return super.transfer(_to, _value);
    }
  }

   
  function isContract(address _addr) private view returns (bool) {
    uint length;
    assembly {
       
      length := extcodesize(_addr)
    }
    return (length>0);
  }

   
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    return approveAndCall(_to, _value, _data);
  }
}

contract UserRegistryInterface {
  event AddAddress(address indexed who);
  event AddIdentity(address indexed who);

  function knownAddress(address _who) public constant returns(bool);
  function hasIdentity(address _who) public constant returns(bool);
  function systemAddresses(address _to, address _from) public constant returns(bool);
}

 
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


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract TokenPolicy is StandardToken, Ownable {
  bool public unfrozen;
  UserRegistryInterface public userRegistry;

  function TokenPolicy(address registry) public {
    require(registry != 0x0);
    userRegistry = UserRegistryInterface(registry);
  }

  event Unfrezee();

  modifier shouldPassPolicy(address _from, address _to) {
     
    require(
      !userRegistry.knownAddress(_from) || 
       userRegistry.hasIdentity(_from) || 
       userRegistry.systemAddresses(_to, _from));

     
    require(unfrozen || userRegistry.systemAddresses(_to, _from));

    _;
  }
  function transfer(address _to, uint256 _value) shouldPassPolicy(msg.sender, _to) public returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) shouldPassPolicy(_from, _to) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function unfrezee() onlyOwner public returns (bool) {
    require(!unfrozen);
    unfrozen = true;
  }
}

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract DefaultToken is MintableToken, TokenPolicy, ApproveAndCallToken {
  using SafeMath for uint;

  string public name;
  string public ticker;
  uint public decimals;
  
  function DefaultToken(string _name, string _ticker, uint _decimals, address _registry) 
    ApproveAndCallToken()
    MintableToken()
    TokenPolicy(_registry) public {
    name = _name;
    ticker = _ticker;
    decimals = _decimals;
  }

  function takeAway(address _holder, address _to) onlyOwner public returns (bool) {
    require(userRegistry.knownAddress(_holder) && !userRegistry.hasIdentity(_holder));

    uint allBalance = balances[_holder];
    balances[_to] = balances[_to].add(allBalance);
    balances[_holder] = 0;
    
    Transfer(_holder, _to, allBalance);
  }
}

contract AltToken is DefaultToken {
  function AltToken(address _registry) DefaultToken("AltEstate token", "ALT", 18, _registry) public {
  }
}