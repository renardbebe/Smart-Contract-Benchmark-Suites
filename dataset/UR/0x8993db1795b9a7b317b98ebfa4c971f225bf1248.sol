 

pragma solidity ^0.4.20;

 
contract IERC20 {
    function totalSupply() public constant returns (uint _totalSupply);
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


 
library SafeMathLib {

 
  function minus(uint a, uint b) internal constant returns (uint) {
    assert(b <= a);
    return a - b;
  }

 
  function plus(uint a, uint b) internal constant returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

 
contract Ownable {

  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }
    
}

contract HasAddresses {
    address teamAddress = 0xb72D3a827c7a7267C0c8E14A1F4729bF38950887;
    address advisoryPoolAddress = 0x83a330c4A0f7b2bBe1B463F7a5a5eb6EA429E981;
    address companyReserveAddress = 0x6F221CFDdac264146DEBaF88DaaE7Bb811C29fB5;
    address freePoolAddress = 0x108102b4e6F92a7A140C38F3529c7bfFc950081B;
}


contract VestingPeriods{
    uint teamVestingTime = 1557360000;             
    uint advisoryPoolVestingTime = 1541721600;     
    uint companyReserveAmountVestingTime = 1541721600;     

}


contract Vestable {

    uint defaultVestingDate = 1526428800;   

    mapping(address => uint) vestedAddresses ;     
    bool isVestingOver = false;

    function addVestingAddress(address vestingAddress, uint maturityTimestamp) internal{
        vestedAddresses[vestingAddress] = maturityTimestamp;
    }

    function checkVestingTimestamp(address testAddress) public constant returns(uint){
        return vestedAddresses[testAddress];

    }

    function checkVestingCondition(address sender) internal returns(bool) {
        uint vestingTimestamp = vestedAddresses[sender];
        if(vestingTimestamp == 0){
            vestingTimestamp = defaultVestingDate;
        }
        return now > vestingTimestamp;
    }
}

 
contract ENKToken is IERC20, Ownable, Vestable, HasAddresses, VestingPeriods {
    
    using SafeMathLib for uint256;
    
    uint256 public constant totalTokenSupply = 1500000000 * 10**18;

    uint256 public burntTokens;

    string public constant name = "Enkidu";     
    string public constant symbol = "ENK";   
    uint8 public constant decimals = 18;
            
    mapping (address => uint256) public balances;
     
    mapping(address => mapping(address => uint256)) approved;
    
    function ENKToken() public {
        
        uint256 teamPoolAmount = 420 * 10**6 * 10**18;          
        uint256 advisoryPoolAmount = 19 * 10**5 * 10**18;       
        uint256 companyReserveAmount = 135 * 10**6 * 10**18;    
        
        uint256 freePoolAmmount = totalTokenSupply - teamPoolAmount - advisoryPoolAmount;      
        balances[teamAddress] = teamPoolAmount;
        balances[freePoolAddress] = freePoolAmmount;
        balances[advisoryPoolAddress] = advisoryPoolAmount;    
        balances[companyReserveAddress] = companyReserveAmount;
        emit Transfer(address(this), teamAddress, teamPoolAmount);
        emit Transfer(address(this), freePoolAddress, freePoolAmmount);
        emit Transfer(address(this), advisoryPoolAddress, advisoryPoolAmount);
        emit Transfer(address(this), companyReserveAddress, companyReserveAmount);
        addVestingAddress(teamAddress, teamVestingTime);             
        addVestingAddress(advisoryPoolAddress, advisoryPoolVestingTime);     
        addVestingAddress(companyReserveAddress, companyReserveAmountVestingTime);     
    }

    function burn(uint256 _value) public {
        require (balances[msg.sender] >= _value);                  
        balances[msg.sender] = balances[msg.sender].minus(_value);
        burntTokens += _value;
        emit BurnToken(msg.sender, _value);
    } 

    
    function totalSupply() constant public returns (uint256 _totalSupply) {
        return totalTokenSupply - burntTokens;
    }
    
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }
    
     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);                                
        require (balances[_from] >= _value);                  
        require (balances[_to] + _value > balances[_to]);    
        balances[_from] = balances[_from].minus(_value);     
        balances[_to] = balances[_to].plus(_value);          
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(checkVestingCondition(msg.sender));
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(checkVestingCondition(_from));
        require (_value <= approved[_from][msg.sender]);      
        approved[_from][msg.sender] = approved[_from][msg.sender].minus(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(checkVestingCondition(_spender));
        if(balances[msg.sender] >= _value) {
            approved[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        }
        return false;
    }
        
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return approved[_owner][_spender];
    }
        
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event BurnToken(address _owner, uint256 _value);
    
}