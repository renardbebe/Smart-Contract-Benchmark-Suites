 

pragma solidity ^0.4.23;

 
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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

contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data);
}

contract VictoryGlobalCoin is Pausable {
  using SafeMath for uint256;

  mapping (address => uint) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  mapping (address => bool) public frozenAccount;

  event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
  event FrozenFunds(address target, bool frozen);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  constructor(string _name, string _symbol, uint8 _decimals, uint256 _supply)
  {
      name = _name;
      symbol = _symbol;
      decimals = _decimals;
      totalSupply = _supply;
      balances[msg.sender] = totalSupply;
  }


   
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

  function freezeAccount(address target, bool freeze) onlyOwner public {
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }

   
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback)
  whenNotPaused
  returns (bool success)
  {
    require(_to != address(0));
    require(!frozenAccount[_to]);
    require(!frozenAccount[msg.sender]);
    if(isContract(_to)) {
      require(balanceOf(msg.sender) >= _value);
        balances[_to] = balanceOf(_to).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        assert(_to.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data));
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}


   
  function transfer(address _to, uint _value, bytes _data)
  whenNotPaused
  returns (bool success) {
    require(_to != address(0));
    require(!frozenAccount[_to]);
    require(!frozenAccount[msg.sender]);
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}

   
   
  function transfer(address _to, uint _value)
  whenNotPaused
  returns (bool success) {
    require(_to != address(0));
    require(!frozenAccount[_to]);
    require(!frozenAccount[msg.sender]);
     
     
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

 
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
             
            length := extcodesize(_addr)
      }
      return (length>0);
    }

   
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    require(_to != address(0));
    require(!frozenAccount[_to]);
    require(balanceOf(msg.sender) >= _value);
    require(!frozenAccount[msg.sender]);
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }

   
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    require(_to != address(0));
    require(!frozenAccount[_to]);
    require(balanceOf(msg.sender) >= _value);
    require(!frozenAccount[msg.sender]);
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

   
  function approve(address _spender, uint256 _value)
    public
    whenNotPaused
    returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool)
  {
    allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  
    function distributeAirdrop(address[] addresses, uint256 amount) onlyOwner public returns (bool seccess) {
    require(amount > 0);
    require(addresses.length > 0);
    require(!frozenAccount[msg.sender]);

    uint256 totalAmount = amount.mul(addresses.length);
    require(balances[msg.sender] >= totalAmount);
    bytes memory empty;

    for (uint i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0));
      require(!frozenAccount[addresses[i]]);
      balances[addresses[i]] = balances[addresses[i]].add(amount);
      emit Transfer(msg.sender, addresses[i], amount, empty);
    }
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    
    return true;
  }

  function distributeAirdrop(address[] addresses, uint256[] amounts) public returns (bool) {
    require(addresses.length > 0);
    require(addresses.length == amounts.length);
    require(!frozenAccount[msg.sender]);

    uint256 totalAmount = 0;

    for(uint i = 0; i < addresses.length; i++){
      require(amounts[i] > 0);
      require(addresses[i] != address(0));
      require(!frozenAccount[addresses[i]]);

      totalAmount = totalAmount.add(amounts[i]);
    }
    require(balances[msg.sender] >= totalAmount);

    bytes memory empty;
    for (i = 0; i < addresses.length; i++) {
      balances[addresses[i]] = balances[addresses[i]].add(amounts[i]);
      emit Transfer(msg.sender, addresses[i], amounts[i], empty);
    }
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    return true;
  }
  
   
    function collectTokens(address[] addresses, uint256[] amounts) onlyOwner public returns (bool) {
        require(addresses.length > 0);
        require(addresses.length == amounts.length);

        uint256 totalAmount = 0;
        bytes memory empty;
        
        for (uint j = 0; j < addresses.length; j++) {
            require(amounts[j] > 0);
            require(addresses[j] != address(0));
            require(!frozenAccount[addresses[j]]);
                    
            require(balances[addresses[j]] >= amounts[j]);
            balances[addresses[j]] = balances[addresses[j]].sub(amounts[j]);
            totalAmount = totalAmount.add(amounts[j]);
            emit Transfer(addresses[j], msg.sender, amounts[j], empty);
        }
        balances[msg.sender] = balances[msg.sender].add(totalAmount);
        return true;
    }
}