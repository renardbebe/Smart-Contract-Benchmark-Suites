 

pragma solidity ^0.4.19;

interface tokenRecipient { 

    function receiveApproval(

        address _from, 

        uint256 _value,

        address _token, 

        bytes _extraData

    ) public; 

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

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract DRCToken is BurnableToken, MintableToken, PausableToken {    

    string public name = 'DRC Token';

    string public symbol = 'DRC';

    uint8 public decimals = 18;

    uint256 public INITIAL_SUPPLY = 1000000000000000000000000000;

     
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address _target, bool _frozen);

     
    function DRCToken() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = totalSupply;
    }
    
     
    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        frozenAccount[_target] = _freeze;
        FrozenFunds(_target, _freeze);
    }

   
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(!frozenAccount[msg.sender]);
    return super.transfer(_to, _value);
  }
  
   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(!frozenAccount[_from]);
    return super.transferFrom(_from, _to, _value);
  }

   
  function transferMultiAddress(address[] _toMulti, uint256[] _values) public whenNotPaused returns (bool) {
    require(!frozenAccount[msg.sender]);
    assert(_toMulti.length == _values.length);

    uint256 i = 0;
    while ( i < _toMulti.length) {
        require(_toMulti[i] != address(0));
        require(_values[i] <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_values[i]);
        balances[_toMulti[i]] = balances[_toMulti[i]].add(_values[i]);
        Transfer(msg.sender, _toMulti[i], _values[i]);

        i = i.add(1);
    }

    return true;
  }

   
  function transferMultiAddressFrom(address _from, address[] _toMulti, uint256[] _values) public whenNotPaused returns (bool) {
    require(!frozenAccount[_from]);
    assert(_toMulti.length == _values.length);
    
    uint256 i = 0;
    while ( i < _toMulti.length) {
        require(_toMulti[i] != address(0));
        require(_values[i] <= balances[_from]);
        require(_values[i] <= allowed[_from][msg.sender]);

         
        balances[_from] = balances[_from].sub(_values[i]);
        balances[_toMulti[i]] = balances[_toMulti[i]].add(_values[i]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_values[i]);
        Transfer(_from, _toMulti[i], _values[i]);

        i = i.add(1);
    }

    return true;
  }
  
     
    function burn(uint256 _value) whenNotPaused public {
        super.burn(_value);
    }

     
    function burnFrom(address _from, uint256 _value) public whenNotPaused returns (bool success) {
        require(balances[_from] >= _value);                 
        require(_value <= allowed[_from][msg.sender]);     
        balances[_from] = balances[_from].sub(_value);                          
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);              
        totalSupply = totalSupply.sub(_value);
        Burn(_from, _value);
        return true;
    }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint whenNotPaused public returns (bool) {
      return super.mint(_to, _amount);
  }

   
  function finishMinting() onlyOwner canMint whenNotPaused public returns (bool) {
      return super.finishMinting();
  }


     

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public whenNotPaused returns (bool success) {

        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {

            spender.receiveApproval(msg.sender, _value, this, _extraData);

            return true;

        }

    }

}