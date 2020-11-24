 

pragma solidity ^0.4.19;



 
 
 



 
contract ERC20Basic {
  uint256 public totalSupply;
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


 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}



 
 
 



 

contract XmonetaToken is StandardToken, Claimable {

   

  string public constant name = "Xmoneta Token";
  string public constant symbol = "XMN";
  uint256 public constant decimals = 18;

   

   
   
  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** decimals);
   
  address public vault = msg.sender;
   
  address public salesAgent;

   

  event SalesAgentAppointed(address indexed previousSalesAgent, address indexed newSalesAgent);
  event SalesAgentRemoved(address indexed currentSalesAgent);
  event Burn(uint256 valueToBurn);

   

   
  function XmonetaToken() public {
    owner = msg.sender;
    totalSupply = INITIAL_SUPPLY;
    balances[vault] = totalSupply;
  }

   
  function setSalesAgent(address newSalesAgent) onlyOwner public {
    SalesAgentAppointed(salesAgent, newSalesAgent);
    salesAgent = newSalesAgent;
  }

   
  function removeSalesAgent() onlyOwner public {
    SalesAgentRemoved(salesAgent);
    salesAgent = address(0);
  }

   
  function transferTokensFromVault(address fromAddress, address toAddress, uint256 tokensAmount) public {
    require(salesAgent == msg.sender);
    balances[vault] = balances[vault].sub(tokensAmount);
    balances[toAddress] = balances[toAddress].add(tokensAmount);
    Transfer(fromAddress, toAddress, tokensAmount);
  }

   
  function burn(uint256 valueToBurn) onlyOwner public {
    require(valueToBurn > 0);
    balances[vault] = balances[vault].sub(valueToBurn);
    totalSupply = totalSupply.sub(valueToBurn);
    Burn(valueToBurn);
  }

}



 
 
 



 

contract XmonetaPresale {

  using SafeMath for uint256;

   

   
  XmonetaToken public token;
   
  uint256 public startTime = 1516881600;
   
  uint256 public endTime = 1519560000;
   
  address public wallet1 = 0x36A3c000f8a3dC37FCD261D1844efAF851F81556;
  address public wallet2 = 0x8beDBE45Aa345938d70388E381E2B6199A15B3C3;
   
  uint256 public rate = 2000;
   
  uint256 public cap = 16000 * 1 ether;
   
  uint256 public weiRaised;

   

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 weiAmount, uint256 tokens);

   

   
  function XmonetaPresale() public {
    token = XmonetaToken(0x99705A8B60d0fE21A4B8ee54DB361B3C573D18bb);
  }

   
  function () public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tempWeiRaised = weiRaised.add(weiAmount);
    if (tempWeiRaised > cap) {
      uint256 spareWeis = tempWeiRaised.sub(cap);
      weiAmount = weiAmount.sub(spareWeis);
      beneficiary.transfer(spareWeis);
    }

     
    uint256 bonusPercent = 30;

     
    if (weiAmount >= 5 ether) {
      bonusPercent = 50;
    }

    uint256 additionalPercentInWei = rate.div(100).mul(bonusPercent);
    uint256 rateWithPercents = rate.add(additionalPercentInWei);

     
    uint256 tokens = weiAmount.mul(rateWithPercents);

     
    weiRaised = weiRaised.add(weiAmount);

     
    token.transferTokensFromVault(msg.sender, beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds(weiAmount);
  }

   
  function forwardFunds(uint256 weiAmount) internal {
    uint256 value = weiAmount.div(2);

     
    if (value.mul(2) != weiAmount) {
      wallet1.transfer(weiAmount);
    } else {
      wallet1.transfer(value);
      wallet2.transfer(value);
    }
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised < cap;
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && withinCap;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime || weiRaised >= cap;
  }

}