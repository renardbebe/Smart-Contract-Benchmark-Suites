 

pragma solidity ^0.4.23;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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
    emit OwnershipTransferred(owner, newOwner);
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
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

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


contract Consumer is Ownable {

    address public hookableTokenAddress;

    modifier onlyHookableTokenAddress {
        require(msg.sender == hookableTokenAddress);
        _;
    }

    function setHookableTokenAddress(address _hookableTokenAddress) onlyOwner {
        hookableTokenAddress = _hookableTokenAddress;
    }

    function onMint(address _sender, address _to, uint256 _amount) onlyHookableTokenAddress {
    }

    function onBurn(address _sender, uint256 _value) onlyHookableTokenAddress {
    }

    function onTransfer(address _sender, address _to, uint256 _value) onlyHookableTokenAddress {
    }

    function onTransferFrom(address _sender, address _from, address _to, uint256 _value) onlyHookableTokenAddress {
    }

    function onApprove(address _sender, address _spender, uint256 _value) onlyHookableTokenAddress {
    }

    function onIncreaseApproval(address _sender, address _spender, uint _addedValue) onlyHookableTokenAddress {
    }

    function onDecreaseApproval(address _sender, address _spender, uint _subtractedValue) onlyHookableTokenAddress {
    }

    function onTaxTransfer(address _from, uint _tokensAmount) onlyHookableTokenAddress {
    }
}

contract HookableToken is MintableToken, PausableToken, BurnableToken {

    Consumer public consumerAddress;
    
    constructor(address _consumerAddress) public {
        consumerAddress = Consumer(_consumerAddress);
    }

     modifier onlyConsumerAddress(){
        require(msg.sender == address(consumerAddress));
        _;
    }

    function setConsumerAddress(address _newConsumerAddress) public onlyOwner {
        require(_newConsumerAddress != address(0));
        consumerAddress = Consumer(_newConsumerAddress);
    }

    function mint(address _to, uint256 _amount) public returns (bool){
        consumerAddress.onMint(msg.sender,_to, _amount);
        return super.mint(_to, _amount);
    }

    function burn(uint256 _value) public {
        consumerAddress.onBurn(msg.sender, _value);
        return super.burn(_value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        consumerAddress.onTransfer(msg.sender, _to, _value);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        consumerAddress.onTransferFrom(msg.sender, _from, _to, _value);
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        consumerAddress.onApprove(msg.sender, _spender, _value);
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        consumerAddress.onIncreaseApproval(msg.sender, _spender, _addedValue);
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        consumerAddress.onDecreaseApproval(msg.sender, _spender, _subtractedValue);
        return super.decreaseApproval(_spender, _subtractedValue);
    }

}



 
contract ICOToken is MintableToken, PausableToken, HookableToken {

    string public constant name = "Artificial Intelligence Quotient";
    string public constant symbol = "AIQ";
    uint8 public constant decimals = 18;


     
    constructor(address _consumerAdr) public 
    HookableToken(_consumerAdr){
    }

     
    function taxTransfer(address _from, address _to, uint256 _tokensAmount) public onlyConsumerAddress returns (bool) {
        require(_from != address(0));
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_tokensAmount);
        balances[_to] = balances[_to].add(_tokensAmount);

        consumerAddress.onTaxTransfer(_from, _tokensAmount);

        return true;
    }
}