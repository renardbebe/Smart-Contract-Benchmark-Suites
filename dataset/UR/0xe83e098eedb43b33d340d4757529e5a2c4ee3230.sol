 

pragma solidity ^0.4.19;

 
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

contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
    
}


contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier nonZeroEth(uint _value) {
      require(_value > 0);
      _;
    }

    modifier onlyPayloadSize() {
      require(msg.data.length >= 68);
      _;
    }


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Allocate(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


     

    function transfer(address _to, uint256 _value) nonZeroEth(_value) onlyPayloadSize returns (bool) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]){
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }else{
            return false;
        }
    }


     

    function transferFrom(address _from, address _to, uint256 _value) nonZeroEth(_value) onlyPayloadSize returns (bool) {
      if(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]){
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      }else{
        return false;
      }
}


     

    function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}



contract BoonTech is BasicToken, Ownable{

using SafeMath for uint256;

 

string public name = "Boon Tech";                  

string public symbol = "BOON";                       

uint8 public decimals = 18;                         

uint256 public totalSupply = 500000000 * 10**uint256(decimals);   

uint256 private constant decimalFactor = 10**uint256(decimals);

bool public transfersAreLocked = true;

mapping (address => Allocation) public allocations;

 
 
struct Allocation {
  uint256 startTime;
  uint256 endCliff;        
  uint256 endVesting;      
  uint256 totalAllocated;  
  uint256 amountClaimed;   
}

uint256 public grandTotalClaimed = 0;
uint256 tokensForDistribution = totalSupply.div(2);
uint256 ethPrice = 960;
uint256 tokenPrice = 4;

 
event LogNewAllocation(address indexed _recipient, uint256 _totalAllocated);
event LogBoonReleased(address indexed _recipient, uint256 _amountClaimed, uint256 _totalAllocated, uint256 _grandTotalClaimed);

 

  function BoonTech () {
    balances[msg.sender] = totalSupply;
  }

 

 
  modifier canTransfer() {
    require(transfersAreLocked == false);
    _;
  }

  modifier nonZeroAddress(address _to) {
    require(_to != 0x0);
    _;
  }

 

 

  function tokenOwner() public view returns (address) {
    return owner;
  }

 
  function transfer(address _to, uint _value) canTransfer() public returns (bool success) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) canTransfer() public returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }

   
  function transferLock() onlyOwner public{
        transfersAreLocked = true;
  }
  function transferUnlock() onlyOwner public{
        transfersAreLocked = false;
  }

  function setFounderAllocation(address _recipient, uint256 _totalAllocated) onlyOwner public {
    require(allocations[_recipient].totalAllocated == 0 && _totalAllocated > 0);
    require(_recipient != address(0));

    allocations[_recipient] = Allocation(now, now + 0.5 years, now + 2 years, _totalAllocated, 0);
     

    LogNewAllocation(_recipient, _totalAllocated);
  }

 
  function releaseVestedTokens(address _tokenAddress) onlyOwner public{
    require(allocations[_tokenAddress].amountClaimed < allocations[_tokenAddress].totalAllocated);
    require(now >= allocations[_tokenAddress].endCliff);
    require(now >= allocations[_tokenAddress].startTime);
    uint256 newAmountClaimed;
    if (allocations[_tokenAddress].endVesting > now) {
       
      newAmountClaimed = allocations[_tokenAddress].totalAllocated.mul(now.sub(allocations[_tokenAddress].startTime)).div(allocations[_tokenAddress].endVesting.sub(allocations[_tokenAddress].startTime));
    } else {
       
      newAmountClaimed = allocations[_tokenAddress].totalAllocated;
    }
    uint256 tokensToTransfer = newAmountClaimed.sub(allocations[_tokenAddress].amountClaimed);
    allocations[_tokenAddress].amountClaimed = newAmountClaimed;
    if(transfersAreLocked == true){
      transfersAreLocked = false;
      require(transfer(_tokenAddress, tokensToTransfer * decimalFactor));
      transfersAreLocked = true;
    }else{
      require(transfer(_tokenAddress, tokensToTransfer * decimalFactor));
    }
    grandTotalClaimed = grandTotalClaimed.add(tokensToTransfer);
    LogBoonReleased(_tokenAddress, tokensToTransfer, newAmountClaimed, grandTotalClaimed);
  }

  function distributeToken(address[] _addresses, uint256[] _value) onlyOwner public {
     for (uint i = 0; i < _addresses.length; i++) {
         transfersAreLocked = false;
         require(transfer(_addresses[i], _value[i] * decimalFactor));
         transfersAreLocked = true;
     }
      
  }

       
    function getNoOfTokensTransfer(uint32 _exchangeRate , uint256 _amount) internal returns (uint256) {
         uint256 noOfToken = _amount.mul(_exchangeRate);
         uint256 noOfTokenWithBonus =(100 * noOfToken ) / 100;
         return noOfTokenWithBonus;
    }

    function setEthPrice(uint256 value)
    external
    onlyOwner
    {
        ethPrice = value;

    }
    function calcToken(uint256 value)
        internal
        returns(uint256 amount){
             amount =  ethPrice.mul(100).mul(value).div(tokenPrice);
             return amount;
        }
     function buyTokens()
            external
            payable
            returns (uint256 amount)
            {
                amount = calcToken(msg.value);
                require(msg.value > 0);
                require(balanceOf(owner) >= amount);
                balances[owner] = balances[owner].sub(msg.value);
                balances[msg.sender] = balances[msg.sender].add(msg.value);
                return amount;
    }
}