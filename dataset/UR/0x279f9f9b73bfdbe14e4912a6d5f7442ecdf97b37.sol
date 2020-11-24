 

 
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

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
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
 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract BasicToken is ERC20Basic, Pausable {
  using SafeMath for uint256;
  address companyReserve;
  address marketingReserve;
  address advisorReserve;
  mapping(address => uint256) balances;
   
  function transfer(address _to, uint256 _value) public   returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

 

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
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

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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


contract AMICoin is StandardToken, Destructible {
    string public constant name = "AMI TOKEN";
    uint public constant decimals = 18;
    string public constant symbol = "AMI";
     using SafeMath for uint256;
     event BuyAMI(address indexed from,string userid,uint256 value);
     address depositWalletAddress;
     uint256 public weiRaised =0;
    function AMICoin()  public {
       totalSupply = 50000000 * (10**decimals);  
       owner = msg.sender;
       depositWalletAddress = 0x6f0EA2d0bd5312ab56e1d4108360e557bb38425f; 
       companyReserve = 0x899004f864AAcd954A252A7E9D3d70d4594d4851;
       marketingReserve = 0x955eD316F49878EeE10A3dEBaD4E5Ab72A3F8624;
       advisorReserve = 0x4bfd13D8BCFBA3288043654053Ae13C752d193Eb;
       balances[msg.sender] += 40000000 * (10 ** decimals);
       balances[companyReserve] += 7500000 * (10 ** decimals);
       balances[marketingReserve] += 1500000 * (10 ** decimals);
       balances[advisorReserve] +=   1000000  * (10 ** decimals);
       Transfer(msg.sender,msg.sender, balances[msg.sender]);
       Transfer(msg.sender,companyReserve, balances[companyReserve]);
       Transfer(msg.sender,marketingReserve, balances[marketingReserve]);
       Transfer(msg.sender,advisorReserve, balances[advisorReserve]);
    }

    function()  public {
     revert();
    }
    
    function buyAMI(string userId) public payable{
        require(msg.sender !=0);
        require(msg.value>0);
        forwardFunds();
         weiRaised+=msg.value;
        BuyAMI(msg.sender,userId,msg.value);
    }
   
          
   
  function forwardFunds() internal {
     require(depositWalletAddress!=0);
    depositWalletAddress.transfer(msg.value);
  }
  function changeDepositWalletAddress (address newDepositWalletAddr) public onlyOwner {
       require(newDepositWalletAddr!=0);
       depositWalletAddress = newDepositWalletAddr;
  }
  
  
    
  
}