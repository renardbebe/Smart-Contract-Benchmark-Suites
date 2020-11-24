 

pragma solidity ^0.4.15;

 
contract IERC20Token {
     
    function name() public constant returns (string) {}
    function symbol() public constant returns (string) {}
    function decimals() public constant returns (uint8) {}
    function totalSupply() public constant returns (uint) {}
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function balanceOf(address _owner) public constant returns (uint balance);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract StandardToken is IERC20Token {
  using SafeMath for uint;

  mapping (address => mapping (address => uint256)) internal allowed;
  mapping (address => uint) balances;
  uint256 totalSupply_;


   
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

 
contract Burnable is StandardToken {
  using SafeMath for uint;

   
  event Burn(address indexed from, uint value);

  function burn(uint _value) public returns (bool success) {
    require(_value > 0 && balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(msg.sender, _value);
    return true;
  }

  function burnFrom(address _from, uint _value) public returns (bool success) {
    require(_from != 0x0 && _value > 0 && balances[_from] >= _value);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Burn(_from, _value);
    return true;
  }

  function transfer(address _to, uint _value) public returns (bool success) {
    require(_to != 0x0);  

    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    require(_to != 0x0);  

    return super.transferFrom(_from, _to, _value);
  }
}

 
contract Utils {
     
    function Utils() public {
    }

     
    modifier greaterThanZero(uint _amount) {
        require(_amount > 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }


    function _validAddress(address _address) internal pure returns (bool) {
      return  _address != 0x0;
    }

     

     
    function safeAdd(uint _x, uint _y) internal pure returns (uint) {
        uint z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint _x, uint _y) internal pure returns (uint) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint _x, uint _y) internal pure returns (uint) {
        uint z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 
contract IOwned {
     
    function owner() public constant returns (address) {}

    function transferOwnership(address _newOwner) public;
}

 
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint _amount) public;
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

 
contract TokenHolder is ITokenHolder, Ownable, Utils {

     
    function TokenHolder() public {
    }


     
     
     
     
     
    function withdrawTokens(IERC20Token _token, address _to, uint _amount) public
    onlyOwner
    validAddress(_to)
    {
        require(_to != address(this));
        assert(_token.transfer(_to, _amount));
    }
}

 
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint _amount) public;
    function destroy(address _from, uint _amount) public;
}

contract SmartToken is ISmartToken, Burnable, TokenHolder {
    string public version = '0.3';

    bool public transfersEnabled = true;     

     
    event NewSmartToken(address _token);
     
    event Issuance(uint _amount);
     
    event Destruction(uint _amount);

     
    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

     
    function disableTransfers(bool _disable) public onlyOwner {
        transfersEnabled = !_disable;
    }

     
    function issue(address _to, uint _amount)
        public
        onlyOwner
        validAddress(_to)
        notThis(_to)
    {
        totalSupply_ = safeAdd(totalSupply_, _amount);
        balances[_to] = safeAdd(balances[_to], _amount);

        Issuance(_amount);
        Transfer(this, _to, _amount);
    }

     
    function destroy(address _from, uint _amount) public {
        require(msg.sender == _from || msg.sender == owner);  

        balances[_from] = safeSub(balances[_from], _amount);
        totalSupply_ = safeSub(totalSupply_, _amount);

        Transfer(_from, this, _amount);
        Destruction(_amount);
    }

     

     
    function transfer(address _to, uint _value) public transfersAllowed returns (bool success) {
        assert(super.transfer(_to, _value));
        return true;
    }

     
    function transferFrom(address _from, address _to, uint _value) public transfersAllowed returns (bool success) {
        assert(super.transferFrom(_from, _to, _value));
        return true;
    }
}

contract ContractReceiver {
   function tokenFallback(address _from, uint _value, bytes _data) external;
}

 
contract FinTabToken is SmartToken {

  uint public constant INITIAL_SUPPLY = 3079387 * (10 ** 8);

  uint public releaseTokensBlock;  

  mapping (address => bool) public teamAddresses;
  mapping (address => bool) public tokenBurners;

  event Transfer(address indexed _from, address indexed _to, uint _value, bytes _data);

   
  modifier canTransfer(address _sender) {
    require(block.number >= releaseTokensBlock || !teamAddresses[_sender]);
    _;
  }

  modifier canBurnTokens(address _sender) {
    require(tokenBurners[_sender] == true || owner == _sender);
    _;
  }

   
  function FinTabToken(uint _releaseBlock) public {
    releaseTokensBlock = _releaseBlock;
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    NewSmartToken(this);
  }

  function name() public constant returns (string) { return "FinTab"; }
  function symbol() public constant returns (string) { return "FNTB" ;}
  function decimals() public constant returns (uint8) { return 8; }

  function totalSupply() public constant returns (uint) {
    return totalSupply_;
  }
  function balanceOf(address _owner) public constant returns (uint balance) {
    require(_owner != 0x0);
    return balances[_owner];
  }


   
  function setTeamAddress(address addr, bool state) onlyOwner public {
    require(addr != 0x0);
    teamAddresses[addr] = state;
  }

  function setBurner(address addr, bool state) onlyOwner public {
    require(addr != 0x0);
    tokenBurners[addr] = state;
  }

   
  function transfer(address _to, uint _value, bytes _data) transfersAllowed canTransfer(msg.sender) public returns (bool success) {
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }

   
   
  function transfer(address _to, uint _value) transfersAllowed canTransfer(msg.sender) public returns (bool success) {
     
     
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
  }

   
  function transferFrom(address _from, address _to, uint _value) transfersAllowed canTransfer(_from) public returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

   
  function burn(uint _value) canBurnTokens(msg.sender) public returns (bool success) {
    return super.burn(_value);
  }

   
  function burnFrom(address _from, uint _value) onlyOwner  canBurnTokens(msg.sender) public returns (bool success) {
    return super.burnFrom(_from, _value);
  }


   
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
             
            length := extcodesize(_addr)
      }
      return (length>0);
    }

   
  function transferToAddress(address _to, uint _value, bytes _data) private canTransfer(msg.sender) returns (bool success) {
    require(balanceOf(msg.sender) >= _value);
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferToContract(address _to, uint _value, bytes _data) private canTransfer(msg.sender) returns (bool success) {
    require(balanceOf(msg.sender) >= _value);
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
  }
}