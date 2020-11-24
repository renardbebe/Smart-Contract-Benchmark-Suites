 

 

pragma solidity ^0.4.24;

contract ERC223Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

  
 
contract ERC223ReceivingContract { 
 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract SRATOKEN is ERC223Interface, Pausable {
    using SafeMath for uint256;
    
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => bool) public frozenAccount;
    
    event FrozenFunds(address target, bool frozen);
    
    constructor(string name, string symbol, uint8 decimals, uint256 totalSupply) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = totalSupply;
        balances[msg.sender] = totalSupply;
    }
    
    function name() public view returns (string) {
        return _name;
    }
    
    function symbol() public view returns (string) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function freezeAccount(address target, bool freeze) 
    public 
    onlyOwner
    {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
    function transfer(address _to, uint256 _value) 
    public
    whenNotPaused
    returns (bool) 
    {
        require(_value > 0 );
        require(_value <= balances[msg.sender]);
        require(!frozenAccount[_to]);
        require(!frozenAccount[msg.sender]);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transfer(address _to, uint _value, bytes _data) 
    public
    whenNotPaused
    returns (bool)
    {
        require(_value > 0 );
        require(!frozenAccount[_to]);
        require(!frozenAccount[msg.sender]);
        if(isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    function isContract(address _addr) 
    private
    view
    returns (bool is_contract) 
    {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length>0);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) 
    public
    whenNotPaused
    returns (bool) 
    {
        require(_value > 0 );
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(!frozenAccount[_to]);
        require(!frozenAccount[_from]);
        
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) 
    public
    whenNotPaused
    returns (bool) 
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) 
    public
    view
    returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) 
    public
    whenNotPaused
    returns (bool) 
    {
        allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) 
    public
    whenNotPaused
    returns (bool) 
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function distributeAirdrop(address[] addresses, uint256 amount) 
    public
    returns (bool seccess) 
    {
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
    
    function distributeAirdrop(address[] addresses, uint256[] amounts) 
    public returns (bool) {
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
    
     
    function collectTokens(address[] addresses, uint256[] amounts) 
    public
    onlyOwner 
    returns (bool) {
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