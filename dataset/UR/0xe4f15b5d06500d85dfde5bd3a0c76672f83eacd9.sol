 

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

 

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

 

 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external pure {
    from_;
    value_;
    data_;
    revert();
  }

}

 

 
contract Vesting {
  using SafeMath for uint256;

  struct VestingGrant {
    uint256 grantedAmount;        
    uint64 start;
    uint64 cliff;
    uint64 vesting;              
  }  

  mapping (address => VestingGrant) public grants;

  event VestingGrantSet(address indexed to, uint256 grantedAmount, uint64 vesting);

  function getVestingGrantAmount(address _to) public view returns (uint256) {
    return grants[_to].grantedAmount;
  }

   
  function setVestingGrant(address _to, uint256 _grantedAmount, uint64 _start, uint64 _cliff, uint64 _vesting, bool _override) public {

     
    require(_cliff >= _start && _vesting >= _cliff);
     
    require(grants[_to].grantedAmount == 0 || _override);
    grants[_to] = VestingGrant(_grantedAmount, _start, _cliff, _vesting);

    VestingGrantSet(_to, _grantedAmount, _vesting);
  }

   
  function calculateVested (
    uint256 grantedAmount,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) internal pure returns (uint256)
    {
       
      if (time < cliff) return 0;
      if (time >= vesting) return grantedAmount;

       
       
       

       
       

      uint256 vestedAmounts = grantedAmount.mul(time.sub(start).div(30 days)).div(vesting.sub(start).div(30 days));

       

      return vestedAmounts;
  }

  function calculateLocked (
    uint256 grantedAmount,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) internal pure returns (uint256)
    {
      return grantedAmount.sub(calculateVested(grantedAmount, time, start, cliff, vesting));
    }

   
  function getLockedAmountOf(address _to, uint256 _time) public view returns (uint256) {
    VestingGrant storage grant = grants[_to];
    if (grant.grantedAmount == 0) return 0;
    return calculateLocked(grant.grantedAmount, uint256(_time), uint256(grant.start),
      uint256(grant.cliff), uint256(grant.vesting));
  }


}

 

contract DirectToken is MintableToken, HasNoTokens, Vesting {

  string public constant name = "DIREC";
  string public constant symbol = "DIR";
  uint8 public constant decimals = 18;

  bool public tradingStarted = false;    

   
  function setTradingStarted(bool _tradingStarted) public onlyOwner {
    tradingStarted = _tradingStarted;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool success) {
    checkTransferAllowed(msg.sender, _to, _value);
    return super.transfer(_to, _value);
  }

    
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    checkTransferAllowed(msg.sender, _to, _value);
    return super.transferFrom(_from, _to, _value);
  }

   
  function checkTransferAllowed(address _sender, address _to, uint256 _value) private view {
      if (mintingFinished && tradingStarted && isAllowableTransferAmount(_sender, _value)) {
           
          return;
      }

       
       
       
       
      require(_sender == owner || _to == owner);
  }

  function setVestingGrant(address _to, uint256 _grantedAmount, uint64 _start, uint64 _cliff, uint64 _vesting, bool _override) public onlyOwner {
    return super.setVestingGrant(_to, _grantedAmount, _start, _cliff, _vesting, _override);
  }

  function isAllowableTransferAmount(address _sender, uint256 _value) private view returns (bool allowed) {
     if (getVestingGrantAmount(_sender) == 0) {
        return true;
     }
      
     uint256 transferableAmount = balanceOf(_sender).sub(getLockedAmountOf(_sender, now));
     return (_value <= transferableAmount);
  }

}