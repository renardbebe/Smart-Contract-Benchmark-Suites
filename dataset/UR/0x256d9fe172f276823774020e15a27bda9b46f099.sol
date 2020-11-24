 

pragma solidity 0.4.24;
 
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
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  uint256 totalSupply_;
   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);
  function transferFrom(address from, address to, uint256 value)
    public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));
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
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}
contract MintableToken is StandardToken, Ownable {
   
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event MinterAssigned(address indexed owner, address newMinter);
    bool public mintingFinished = false;
    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    address public crowdsale;
    
     
    modifier hasMintPermission() {
        require(msg.sender == crowdsale || msg.sender == owner);
        _;
    }
    function setCrowdsale(address _crowdsaleContract) external onlyOwner {
        crowdsale = _crowdsaleContract;
        emit MinterAssigned(msg.sender, _crowdsaleContract);
    }
   
    function mint(
        address _to,
        uint256 _amount
    )
        public
        hasMintPermission
        canMint  
        returns (bool)
    { 
        require(balances[_to].add(_amount) > balances[_to]);  
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
   
    function finishMinting() public hasMintPermission canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}
contract BurnableToken is BasicToken, Ownable {
    event Burn(address indexed burner, uint256 value);
    
    address public destroyer;
    modifier onlyDestroyer() {
        require(msg.sender == destroyer || msg.sender == owner);
        _;
    }
    
     
    function setDestroyer(address _destroyer) external onlyOwner {
        destroyer = _destroyer;
    }
    function burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}
contract BitminerFactoryToken is MintableToken, BurnableToken {
  
    using SafeMath for uint256;
    
     
    string public constant name = "Bitminer Factory Token";
    string public constant symbol = "BMF";
    uint8 public constant decimals = 18;
    
    uint256 public cap;
    
    mapping (address => uint256) amount;
    
    event MultiplePurchase(address indexed purchaser);
    
    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }
    function burnFrom(address _from, uint256 _value) external onlyDestroyer {
        require(balances[_from] >= _value && _value > 0);
        
        burn(_from, _value);
    }
    function mint(
        address _to,
        uint256 _amount
    )  
    public
    returns (bool)
    {
        require(totalSupply_.add(_amount) <= cap);
        return super.mint(_to, _amount);
    }
    
     
    function multipleTransfer(address[] _to, uint256[] _amount) public hasMintPermission canMint {
        require(_to.length == _amount.length);
        _multiSet(_to, _amount);  
        _multiMint(_to);
        
        emit MultiplePurchase(msg.sender);
    }
    
     
    
     
    function _multiSet(address[] _to, uint256[] _amount) internal {
        for (uint i = 0; i < _to.length; i++) {
            amount[_to[i]] = _amount[i];
        }
    }
    
     
    function _multiMint(address[] _to) internal {
        for(uint i = 0; i < _to.length; i++) {
            mint(_to[i], amount[_to[i]]);
        }
    }
}