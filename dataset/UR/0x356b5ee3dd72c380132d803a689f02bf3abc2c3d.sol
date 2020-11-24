 

pragma solidity ^0.4.18;
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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
  uint256 totalSupply_;
   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
   
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
 
contract BurnableToken is BasicToken {
  event Burn(address indexed burner, uint256 value);
   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}
interface IEventListener {
    function onTokenTransfer(address _from, address _to, uint256 _value) external;
    function onTokenApproval(address _from, address _to, uint256 _value) external;
}
contract Holdable is PausableToken {
    mapping(address => uint256) holders;
    mapping(address => bool) allowTransfer;
    IEventListener public listener;
    event Hold(address holder, uint256 expired);
    event Unhold(address holder);
    function hold(address _holder, uint256 _expired) public onlyOwner {
        holders[_holder] = _expired;
        Hold(_holder, _expired);
    }
    function isHold(address _holder) public view returns(bool) {
        return holders[_holder] > block.timestamp;
    }
    function unhold() public {
        address holder = msg.sender;
        require(block.timestamp >= holders[holder]);
        delete holders[holder];
        Unhold(holder);
    }
    function unhold(address _holder) public {
        require(block.timestamp >= holders[_holder]);
        delete holders[_holder];
        Unhold(_holder);
    }
    function addAllowTransfer(address _holder) public onlyOwner {
        allowTransfer[_holder] = true;
    }
    function isAllowTransfer(address _holder) public view returns(bool) {
        return allowTransfer[_holder] || (!paused && block.timestamp >= holders[_holder]);
    }
    modifier whenNotPaused() {
        require(isAllowTransfer(msg.sender));
        _;
    }
    function addListener(address _listener) public onlyOwner {
        listener = IEventListener(_listener);
    }
    function isListener() internal view returns(bool) {
        return listener != address(0);
    }
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        super.transferFrom(from, to, value);
        if (isListener()) listener.onTokenTransfer(from, to, value);
        return true;
    }
    function transfer(address to, uint256 value) public returns (bool) {
        super.transfer(to, value);
        if (isListener()) listener.onTokenTransfer(msg.sender, to, value);
        return true;
    }
    function approve(address spender, uint256 value) public returns (bool) {
        super.approve(spender, value);
        if (isListener()) listener.onTokenApproval(msg.sender, spender, value);
        return true;
    }
}
contract YTN is Holdable, MintableToken, BurnableToken {
    using SafeMath for uint256;
    enum States {PreOrder, ProofOfConcept, DAICO, Final}
    States public state;
    string public symbol = 'YTN';
    string public name = 'YouToken';
    uint256 public decimals = 18;
    uint256 public cap;
    uint256 public proofOfConceptCap;
    uint256 public DAICOCap;
    function YTN(uint256 _proofOfConceptCap, uint256 _DAICOCap) public {
        proofOfConceptCap = _proofOfConceptCap;
        DAICOCap = _DAICOCap;
        setState(uint(States.PreOrder));
    }
    function() public payable {
        revert();
    }
    function setState(uint _state) public onlyOwner {
        require(uint(state) <= _state && uint(States.Final) >= _state);
        state = States(_state);
        if (state == States.PreOrder || state == States.ProofOfConcept) {
            cap = proofOfConceptCap;
        }
        if (state == States.DAICO) {
            cap = DAICOCap + totalSupply_;
            pause();
        }
        if (state == States.Final) {
            finishMinting();
            unpause();
        }
    }
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply_.add(_amount) <= cap);
        return super.mint(_to, _amount);
    }
}