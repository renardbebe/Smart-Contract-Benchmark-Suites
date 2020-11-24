 

pragma solidity ^0.4.16;

 
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

contract Admin {
  address public admin1;
  address public admin2;

  event AdminshipTransferred(address indexed previousAdmin, address indexed newAdmin);

  function Admin() public {
    admin1 = 0xD384CfA70Db590eab32f3C262B84C1E10f27EDa8;
    admin2 = 0x263003A4CC5358aCebBad7E30C60167307dF1ccB;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin1 || msg.sender == admin2);
    _;
  }

  function transferAdminship1(address newAdmin) public onlyAdmin {
    require(newAdmin != address(0));
    AdminshipTransferred(admin1, newAdmin);
    admin1 = newAdmin;
  }
  function transferAdminship2(address newAdmin) public onlyAdmin {
    require(newAdmin != address(0));
    AdminshipTransferred(admin2, newAdmin);
    admin2 = newAdmin;
  }  
}

contract FilterAddress is Admin{
  mapping (address => uint) public AccessAddress;
    
  function SetAccess(address addr, uint access) onlyAdmin public{
    AccessAddress[addr] = access;
  }
    
  function GetAccess(address addr) public constant returns(uint){
    return  AccessAddress[addr];
  }
    
  modifier checkFilterAddress(){
    require(AccessAddress[msg.sender] != 1);
    _;
  }
}

contract Rewards is Admin{
  using SafeMath for uint256;
  uint public CoefRew;
  uint public SummRew;
  address public RewAddr;
  
  function SetCoefRew(uint newCoefRew) public onlyAdmin{
    CoefRew = newCoefRew;
  }
  
  function SetSummRew(uint newSummRew) public onlyAdmin{
    SummRew = newSummRew;
  }    
  
  function SetRewAddr(address newRewAddr) public onlyAdmin{
    RewAddr = newRewAddr;
  } 
  
  function GetSummReward(uint _value) public constant returns(uint){
    return _value.mul(CoefRew).div(100).div(1000); 
  }
}

contract Fees is Admin{
  using SafeMath for uint256;
  uint public Fee;
  address public FeeAddr1;
  address public FeeAddr2;
    
  function SetFee(uint newFee) public onlyAdmin{
    Fee = newFee;
  }
  function GetSummFee(uint _value) public constant returns(uint){
    return _value.mul(Fee).div(100).div(1000).div(3);
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

 
contract BasicToken is ERC20Basic, FilterAddress, Fees, Rewards, Ownable {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  mapping(address => uint256) allSummReward;
   
  function transfer(address _to, uint256 _value) checkFilterAddress public returns (bool) {
    uint256 _valueto;
    uint fSummFee;
    uint fSummReward;
    require(_to != address(0));
    require(_to != msg.sender);
    require(_value <= balances[msg.sender]);
     
    _valueto = _value;
    if (msg.sender != owner){  
      fSummFee = GetSummFee(_value);
      fSummReward = GetSummReward(_value);
        
      balances[msg.sender] = balances[msg.sender].sub(fSummFee);
      balances[FeeAddr1] = balances[FeeAddr1].add(fSummFee);
      _valueto = _valueto.sub(fSummFee);  

      balances[msg.sender] = balances[msg.sender].sub(fSummFee);
      balances[FeeAddr2] = balances[FeeAddr2].add(fSummFee);
      _valueto = _valueto.sub(fSummFee); 
    
      balances[msg.sender] = balances[msg.sender].sub(fSummFee);
      balances[RewAddr] = balances[RewAddr].add(fSummFee);
      _valueto = _valueto.sub(fSummFee); 
     
      allSummReward[msg.sender] = allSummReward[msg.sender].add(_value);    
      if (allSummReward[msg.sender] >= SummRew && balances[RewAddr] >= fSummReward) {
        balances[RewAddr] = balances[RewAddr].sub(fSummReward);
        balances[msg.sender] = balances[msg.sender].add(fSummReward);
        allSummReward[msg.sender] = 0;
      }
    }

     
    balances[msg.sender] = balances[msg.sender].sub(_valueto);
    balances[_to] = balances[_to].add(_valueto);
    Transfer(msg.sender, _to, _valueto);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _valueto;  
    require(_to != msg.sender);  
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    uint fSummFee;
    uint fSummReward;
    _valueto = _value;
    if (_from != owner){  
      fSummFee = GetSummFee(_value);
      fSummReward = GetSummReward(_value);
        
      balances[_from] = balances[_from].sub(fSummFee);
      balances[FeeAddr1] = balances[FeeAddr1].add(fSummFee);
      _valueto = _valueto.sub(fSummFee);  

      balances[_from] = balances[_from].sub(fSummFee);
      balances[FeeAddr2] = balances[FeeAddr2].add(fSummFee);
      _valueto = _valueto.sub(fSummFee); 
    
      balances[_from] = balances[_from].sub(fSummFee);
      balances[RewAddr] = balances[RewAddr].add(fSummFee);
      _valueto = _valueto.sub(fSummFee); 
     
      allSummReward[_from] = allSummReward[_from].add(_value);
      if (allSummReward[_from] >= SummRew && balances[RewAddr] >= fSummReward) {
        balances[RewAddr] = balances[RewAddr].sub(fSummReward);
        balances[_from] = balances[_from].add(fSummReward);
        allSummReward[_from] = 0;
      }
    }
    balances[_from] = balances[_from].sub(_valueto);
    balances[_to] = balances[_to].add(_valueto);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _valueto);
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

 
contract BurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
      require(_value <= balances[msg.sender]);
       
       

      address burner = msg.sender;
      balances[burner] = balances[burner].sub(_value);
      totalSupply = totalSupply.sub(_value);
      Burn(burner, _value);
    }
}

contract Guap is Ownable, BurnableToken {
  using SafeMath for uint256;    
  string public constant name = "Guap";
  string public constant symbol = "Guap";
  uint32 public constant decimals = 18;
  uint256 public INITIAL_SUPPLY = 9999999999 * 1 ether;
  function Guap() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
     
    RewAddr = 0xb94F2E7B4E37a8c03E9C2E451dec09Ce94Be2615;
    CoefRew = 5;  
    SummRew = 90000 * 1 ether; 
     
    FeeAddr1 = 0xBe9517d10397D60eAD7da33Ea50A6431F5Be3790;
    FeeAddr2 = 0xC90F698cc5803B21a04cE46eD1754655Bf2215E5;
    Fee  = 15;  
  }
}