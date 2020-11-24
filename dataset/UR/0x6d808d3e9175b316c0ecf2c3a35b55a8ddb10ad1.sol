 

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

   
  function transferIDCContractOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
   emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 
 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

 
 
contract Contactable is Ownable {

  string public contactInformation;

   
  function setContactInformation(string info) onlyOwner public {
    contactInformation = info;
  }
}
 
 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferIDCContractOwnership(owner);
  }
}
 

 
 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) pure external {
    from_;
    value_;
    data_;
    revert();
  }

}
 
 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
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
  string internal _symbol;
  string internal _name;
  uint8 internal _decimals;
  uint internal _totalSupply;
  mapping (address => uint) internal _balanceOf;

  mapping (address => mapping (address => uint)) internal _allowances;

  function ERC20Basic(string symbol, string name, uint8 decimals, uint totalSupply) public {
      _symbol = symbol;
      _name = name;
      _decimals = decimals;
      _totalSupply = totalSupply;
  }

  function name() public constant returns (string) {
      return _name;
  }

  function symbol() public constant returns (string) {
      return _symbol;
  }

  function decimals() public constant returns (uint8) {
      return _decimals;
  }

  function totalSupply() public constant returns (uint) {
      return _totalSupply;
  }
  function balanceOf(address _addr) public constant returns (uint);
  function transfer(address _to, uint _value) public returns (bool);
  event Transfer(address indexed _from, address indexed _to, uint _value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}
 
 
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

 mapping (address => bool) public frozenAccount;
 event FrozenFunds(address target, bool frozen);

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
   function freezeAccount(address target, bool freeze) onlyOwner external {
         frozenAccount[target] = freeze;
         emit FrozenFunds(target, freeze);
         }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
      require(!frozenAccount[msg.sender]);
    require(_to != address(0));
    require(_value <= _balanceOf[msg.sender]);

     
    _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
    _balanceOf[_to] = _balanceOf[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balanceOf[_owner];
  }

}
 
 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(!frozenAccount[_from] && !frozenAccount[_to] && !frozenAccount[msg.sender]);
    require(_to != address(0));
    require(_value <= _balanceOf[_from]);
    require(_value <= allowed[_from][msg.sender]);

    _balanceOf[_from] = _balanceOf[_from].sub(_value);
    _balanceOf[_to] = _balanceOf[_to].add(_value);
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
 
 
contract ERC827 is ERC20 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}
 
 
contract ERC827Token is ERC827, StandardToken {

   
  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    require(!frozenAccount[msg.sender] && !frozenAccount[_spender]);
    require(_spender != address(this));

    super.approve(_spender, _value);

    require(_spender.call(_data));

    return true;
  }

   
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function increaseApproval(address _spender, uint _addedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

    require(_spender.call(_data));

    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

    require(_spender.call(_data));

    return true;
  }

}



 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

 
contract IdeaCoin is ERC20Basic("IDC", "IdeaCoin", 18, 1000000000000000000000000), ERC827Token, PausableToken, Destructible, Contactable, HasNoTokens, HasNoContracts {

    using SafeMath for uint;

   
    event Burn(address _from, uint256 _value);
    event Mint(address _to, uint _value);


      function IdeaCoin() public {
            _balanceOf[msg.sender] = _totalSupply;
        }

      
       function totalSupply() public constant returns (uint) {
           return _totalSupply;
       }

       function balanceOf(address _addr) public constant returns (uint) {
           return _balanceOf[_addr];
       }


        function burn(address _from, uint256 _value) onlyOwner external {
              require(_balanceOf[_from] >= 0);
              _balanceOf[_from] =  _balanceOf[_from].sub(_value);
              _totalSupply = _totalSupply.sub(_value);
              emit Burn(_from, _value);
            }


        function mintToken(address _to, uint256 _value) onlyOwner external  {
                require(!frozenAccount[msg.sender] && !frozenAccount[_to]);
               _balanceOf[_to] = _balanceOf[_to].add(_value);
               _totalSupply = _totalSupply.add(_value);
               emit Mint(_to,_value);
             }

}

 