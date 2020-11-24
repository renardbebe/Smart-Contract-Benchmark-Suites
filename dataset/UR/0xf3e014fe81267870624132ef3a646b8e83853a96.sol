 

pragma solidity 0.4.15;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Contactable is Ownable{

    string public contactInformation;

     
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
     }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LockableToken is ERC20 {
    function addToTimeLockedList(address addr) external returns (bool);
}

contract VinToken is Contactable {
    using SafeMath for uint;

    string constant public name = "VIN";
    string constant public symbol = "VIN";
    uint constant public decimals = 18;
    uint constant public totalSupply = (10 ** 9) * (10 ** decimals);  
    uint constant public lockPeriod1 = 2 years;
    uint constant public lockPeriod2 = 24 weeks;
    uint constant public lockPeriodForBuyers = 12 weeks;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    bool public isActivated = false;
    mapping (address => bool) public whitelistedBeforeActivation;
    mapping (address => bool) public isPresaleBuyer;
    address public saleAddress;
    address public founder1Address;
    address public founder2Address;
    uint public icoEndTime;
    uint public icoStartTime;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function VinToken(
        address _founder1Address,
        address _founder2Address,
        uint _icoStartTime,
        uint _icoEndTime
        ) public 
    {
        require(_founder1Address != 0x0);
        require(_founder2Address != 0x0);
        require(_icoEndTime > _icoStartTime);
        founder1Address = _founder1Address;
        founder2Address = _founder2Address;
        icoStartTime = _icoStartTime;
        icoEndTime = _icoEndTime;
        balances[owner] = totalSupply;
        whitelistedBeforeActivation[owner] = true;
    }

    modifier whenActivated() {
        require(isActivated || whitelistedBeforeActivation[msg.sender]);
        _;
    }
    
    modifier isLockTimeEnded(address from){
        if (from == founder1Address) {
            require(now > icoEndTime + lockPeriod1);
        } else if (from == founder2Address) {
            require(now > icoEndTime + lockPeriod2);
        } else if (isPresaleBuyer[from]) {
            require(now > icoEndTime + lockPeriodForBuyers);
        }
        _;
    }

    modifier onlySaleConract(){
        require(msg.sender == saleAddress);
        _;
    }

     
    function transfer(address _to, uint _value) external isLockTimeEnded(msg.sender) whenActivated returns (bool) {
        require(_to != 0x0);
    
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) external constant returns (uint balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint _value) external whenActivated returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) external constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

     
    function transferFrom(address _from, address _to, uint _value) external isLockTimeEnded(_from) whenActivated returns (bool) {
        require(_to != 0x0);
        uint _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
         
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);

        return true;
    }

     
    function increaseApproval(address _spender, uint _addedValue) external whenActivated returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) external whenActivated returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function activate() external onlyOwner returns (bool) {
        isActivated = true;
        return true;
    }

     
    function editWhitelist(address _address, bool isWhitelisted) external onlyOwner returns (bool) {
        whitelistedBeforeActivation[_address] = isWhitelisted;
        return true;        
    }

    function addToTimeLockedList(address addr) external onlySaleConract returns (bool) {
        require(addr != 0x0);
        isPresaleBuyer[addr] = true;
        return true;
    }

    function setSaleAddress(address newSaleAddress) external onlyOwner returns (bool) {
        require(newSaleAddress != 0x0);
        saleAddress = newSaleAddress;
        return true;
    }

    function setIcoEndTime(uint newTime) external onlyOwner returns (bool) {
        require(newTime > icoStartTime);
        icoEndTime = newTime;
        return true;
    }
}