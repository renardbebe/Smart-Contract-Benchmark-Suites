 

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

 
contract InbestToken is StandardToken {

  string public constant name = "Inbest Token";
  string public constant symbol = "IBST";
  uint8 public constant decimals = 18;

   
  uint256 public constant INITIAL_SUPPLY = 17656263110 * (10 ** uint256(decimals));

   
  function InbestToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    Transfer(0x0, msg.sender, INITIAL_SUPPLY);
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

 
contract InbestDistribution is Ownable {
  using SafeMath for uint256;

   
  InbestToken public IBST;

   
  mapping (address => bool) public admins;

   
  uint256 private constant DECIMALFACTOR = 10**uint256(18);

   
  uint256 CLIFF = 180 days;  
   
  uint256 VESTING = 365 days; 

   
  uint256 public constant INITIAL_SUPPLY   =    17656263110 * DECIMALFACTOR;  
   
  uint256 public AVAILABLE_TOTAL_SUPPLY    =    17656263110 * DECIMALFACTOR;  
   
  uint256 public AVAILABLE_PRESALE_SUPPLY  =    16656263110 * DECIMALFACTOR;  
   
  uint256 public AVAILABLE_COMPANY_SUPPLY  =    1000000000 * DECIMALFACTOR;  

   
  enum AllocationType { PRESALE, COMPANY}

   
  uint256 public grandTotalClaimed = 0;
   
  uint256 public startTime;

   
  address public companyWallet;

   
  struct Allocation {
    uint8 allocationType;    
    uint256 endCliff;        
    uint256 endVesting;      
    uint256 totalAllocated;  
    uint256 amountClaimed;   
  }
  mapping (address => Allocation) public allocations;

   
  modifier onlyOwnerOrAdmin() {
    require(msg.sender == owner || admins[msg.sender]);
    _;
  }

   
  event LogNewAllocation(address indexed _recipient, AllocationType indexed _fromSupply, uint256 _totalAllocated, uint256 _grandTotalAllocated);
   
  event LogIBSTClaimed(address indexed _recipient, uint8 indexed _fromSupply, uint256 _amountClaimed, uint256 _totalAllocated, uint256 _grandTotalClaimed);
   
  event SetAdmin(address _caller, address _admin, bool _allowed);
   
  event RefundTokens(address _token, address _refund, uint256 _value);

   
  function InbestDistribution(uint256 _startTime, address _companyWallet) public {
    require(_companyWallet != address(0));
    require(_startTime >= now);
    require(AVAILABLE_TOTAL_SUPPLY == AVAILABLE_PRESALE_SUPPLY.add(AVAILABLE_COMPANY_SUPPLY));
    startTime = _startTime;
    companyWallet = _companyWallet;
    IBST = new InbestToken();
    require(AVAILABLE_TOTAL_SUPPLY == IBST.totalSupply());  

     
    uint256 tokensToAllocate = AVAILABLE_COMPANY_SUPPLY;
    AVAILABLE_COMPANY_SUPPLY = 0;
    allocations[companyWallet] = Allocation(uint8(AllocationType.COMPANY), 0, 0, tokensToAllocate, 0);
    AVAILABLE_TOTAL_SUPPLY = AVAILABLE_TOTAL_SUPPLY.sub(tokensToAllocate);
    LogNewAllocation(companyWallet, AllocationType.COMPANY, tokensToAllocate, grandTotalAllocated());
  }

   
  function setAllocation (address _recipient, uint256 _totalAllocated) public onlyOwnerOrAdmin {
    require(_recipient != address(0));
    require(startTime > now);  
    require(AVAILABLE_PRESALE_SUPPLY >= _totalAllocated);  
    require(allocations[_recipient].totalAllocated == 0 && _totalAllocated > 0);  
    require(_recipient != companyWallet);  

     
    AVAILABLE_PRESALE_SUPPLY = AVAILABLE_PRESALE_SUPPLY.sub(_totalAllocated);
    allocations[_recipient] = Allocation(uint8(AllocationType.PRESALE), startTime.add(CLIFF), startTime.add(CLIFF).add(VESTING), _totalAllocated, 0);
    AVAILABLE_TOTAL_SUPPLY = AVAILABLE_TOTAL_SUPPLY.sub(_totalAllocated);
    LogNewAllocation(_recipient, AllocationType.PRESALE, _totalAllocated, grandTotalAllocated());
  }

   
 function transferTokens (address _recipient) public {
   require(_recipient != address(0));
   require(now >= startTime);  
   require(_recipient != companyWallet);  
   require(now >= allocations[_recipient].endCliff);  
    
   require(allocations[_recipient].amountClaimed < allocations[_recipient].totalAllocated);

   uint256 newAmountClaimed;
   if (allocations[_recipient].endVesting > now) {
      
     newAmountClaimed = allocations[_recipient].totalAllocated.mul(now.sub(allocations[_recipient].endCliff)).div(allocations[_recipient].endVesting.sub(allocations[_recipient].endCliff));
   } else {
      
     newAmountClaimed = allocations[_recipient].totalAllocated;
   }

    
   uint256 tokensToTransfer = newAmountClaimed.sub(allocations[_recipient].amountClaimed);
   allocations[_recipient].amountClaimed = newAmountClaimed;
   require(IBST.transfer(_recipient, tokensToTransfer));
   grandTotalClaimed = grandTotalClaimed.add(tokensToTransfer);
   LogIBSTClaimed(_recipient, allocations[_recipient].allocationType, tokensToTransfer, newAmountClaimed, grandTotalClaimed);
 }

  
 function manualContribution(address _recipient, uint256 _tokensToTransfer) public onlyOwnerOrAdmin {
   require(_recipient != address(0));
   require(_recipient != companyWallet);  
   require(_tokensToTransfer > 0);  
   require(now >= startTime);  
    
   require(allocations[companyWallet].amountClaimed.add(_tokensToTransfer) <= allocations[companyWallet].totalAllocated);

    
   allocations[companyWallet].amountClaimed = allocations[companyWallet].amountClaimed.add(_tokensToTransfer);
   require(IBST.transfer(_recipient, _tokensToTransfer));
   grandTotalClaimed = grandTotalClaimed.add(_tokensToTransfer);
   LogIBSTClaimed(_recipient, uint8(AllocationType.COMPANY), _tokensToTransfer, allocations[companyWallet].amountClaimed, grandTotalClaimed);
 }

  
 function companyRemainingAllocation() public view returns (uint256) {
   return allocations[companyWallet].totalAllocated.sub(allocations[companyWallet].amountClaimed);
 }

  
  function grandTotalAllocated() public view returns (uint256) {
    return INITIAL_SUPPLY.sub(AVAILABLE_TOTAL_SUPPLY);
  }

   
  function setAdmin(address _admin, bool _allowed) public onlyOwner {
    require(_admin != address(0));
    admins[_admin] = _allowed;
     SetAdmin(msg.sender,_admin,_allowed);
  }

  function refundTokens(address _token, address _refund, uint256 _value) public onlyOwner {
    require(_refund != address(0));
    require(_token != address(0));
    require(_token != address(IBST));
    ERC20 token = ERC20(_token);
    require(token.transfer(_refund, _value));
    RefundTokens(_token, _refund, _value);
  }
}