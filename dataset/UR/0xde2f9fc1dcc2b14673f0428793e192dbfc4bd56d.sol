 

pragma solidity ^0.4.24;

contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
                             address indexed previousOwner,
                             address indexed newOwner
                             );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership (address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);  

    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract ERC20Token {
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

  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender,uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract StandardToken is ERC20Token {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value ) public returns (bool) {
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

   
  function allowance( address _owner,  address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval( address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval( address _spender, uint _subtractedValue) public returns (bool) {
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
     
    function burn(uint256 _value) public returns (bool) {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        return true;
    }
}

contract FrozenableToken is BurnableToken, Ownable {
  mapping (address => bool) public frozenAccount;
  event FrozenFunds(address target, bool frozen);

   
   
   
  function freezeAccount(address target, bool freeze) onlyOwner public {
      frozenAccount[target] = freeze;
      emit FrozenFunds(target, freeze);
  }

  function transfer( address _to, uint256 _value) public returns (bool) {
    require(!frozenAccount[msg.sender]);                      
    require(!frozenAccount[_to]);                        

    return super.transfer(_to, _value);
    }

  function transferFrom( address _from, address _to, uint256 _value) public returns (bool) {
    require(!frozenAccount[_from]);                      
    require(!frozenAccount[_to]);                        

    return super.transferFrom(_from, _to, _value);
  }

  function approve( address _spender, uint256 _value) public  returns (bool) {
    require(!frozenAccount[msg.sender]);                      
    require(!frozenAccount[_spender]);                        

    return super.approve(_spender, _value);
  }

  function increaseApproval( address _spender, uint _addedValue) public  returns (bool success) {
    require(!frozenAccount[msg.sender]);                      
    require(!frozenAccount[_spender]);                        

    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval( address _spender, uint _subtractedValue) public  returns (bool success) {
    require(!frozenAccount[msg.sender]);                      
    require(!frozenAccount[_spender]);                        

    return super.decreaseApproval(_spender, _subtractedValue);
  }
  

}

contract PausableToken is FrozenableToken {
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

  function transfer( address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom( address _from, address _to, uint256 _value) public whenNotPaused returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve( address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval( address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval( address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract CoinPoolCoin is PausableToken {

  using SafeMath for uint256;

   
  bool public transferable = false;

   
  address public CPBWallet;

   
  uint public constant INITIAL_SUPPLY = 2.1e27;

  modifier onlyWhenTransferEnabled() {
    if (!transferable) {
      require(msg.sender == owner || msg.sender == CPBWallet);
    }
    _;
  }

  modifier validDestination(address to) {
    require(to != address(this));
    _;
  }

  constructor(address _CPBWallet) public StandardToken("CoinPool Coin", "CPB", 18) {

    require(_CPBWallet != address(0));
    CPBWallet = _CPBWallet;
    totalSupply_ = INITIAL_SUPPLY;
    balances[_CPBWallet] = totalSupply_;
    emit Transfer(address(0), _CPBWallet, totalSupply_);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public validDestination(_to) onlyWhenTransferEnabled returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
  function transfer(address _to, uint256 _value) public validDestination(_to) onlyWhenTransferEnabled returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function enableTransfer() external onlyOwner {
    transferable = true;
  }

}

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