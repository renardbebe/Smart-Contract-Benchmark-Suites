 

pragma solidity ^0.4.21;

 
contract ERC20Basic {
  uint256 public totalSupply;
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

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
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
    owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
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

 
contract ACNCToken is StandardToken, Ownable, Pausable, Destructible
{
    using SafeMath for uint;
    string public constant name     = "AirConn Coin";
    string public constant symbol   = "ACNC";
    uint public constant decimals   = 18;
    uint constant million           = 1000000e18;
    uint constant totalToken        = 360*million;

     
    uint constant nCommunityDistribute      = 240*million;
    uint constant nDevelopFunds             = 26*million;
    uint constant nInvestor                 = 12*million;
    uint constant nMarketing                = 10*million;
    uint constant nRewardPlan               = 15*million;
    uint constant nDevelopGroup             = 26*million;
    uint constant nPartnerPocket            = 31*million;

     
    address  public constant AddrCommunityDistribute   = 0x299ee579Fa267cCf07e98029cf529dEB3b8b043b;
    address  public constant AddrDevelopFunds          = 0xc10d80bC0940136D60AcbcFF473433c88C42E8Fb;
    address  public constant AddrInvestor              = 0x6E6522036322B59296aCA456A55904F435654868;
    address  public constant AddrMarketing             = 0x006f931AEE00D6e1aaa89Ee34c90815918F0Ecc0;
    address  public constant AddrRewardPlan            = 0xdbC2F80140788FF5E1c0A494933f327e0f6C2106;
    address  public constant AddrDevelopGroup          = 0x2375E2b6C7026ba8E53dE3a74C303ba223402eB6;
    address  public constant AddrPartnerPocket         = 0x621f21a81F77a254e8677a4e8e5c403Ec9733b2B;

    function ACNCToken() public
    {
        totalSupply                            = totalToken;
        balances[msg.sender]                   = 0;
        balances[AddrCommunityDistribute]      = nCommunityDistribute;
        balances[AddrDevelopFunds]             = nDevelopFunds;
        balances[AddrInvestor]                 = nInvestor;
        balances[AddrMarketing]                = nMarketing;
        balances[AddrRewardPlan]               = nRewardPlan;
        balances[AddrDevelopGroup]             = nDevelopGroup;
        balances[AddrPartnerPocket]            = nPartnerPocket;
    }

}