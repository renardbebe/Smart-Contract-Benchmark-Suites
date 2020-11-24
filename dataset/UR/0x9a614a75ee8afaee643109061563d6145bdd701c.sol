 

 


pragma solidity ^0.4.19;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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


 
contract ERC827 is ERC20 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

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



 
contract ERC827Token is ERC827, StandardToken {

   
  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

    require(_spender.call(_data));

    return true;
  }

   
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function increaseApproval(address _spender, uint _addedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

    require(_spender.call(_data));

    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

    require(_spender.call(_data));

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


contract TALLY is ERC827Token, Ownable
{
    using SafeMath for uint256;
    
    string public constant name = "TALLY";
    string public constant symbol = "TLY";
    uint256 public constant decimals = 18;
    
    address public foundationAddress;
    address public developmentFundAddress;
    uint256 public constant DEVELOPMENT_FUND_LOCK_TIMESPAN = 2 years;
    
    uint256 public developmentFundUnlockTime;
    
    bool public tokenSaleEnabled;
    
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public preSaleTLYperETH;
    
    uint256 public preferredSaleStartTime;
    uint256 public preferredSaleEndTime;
    uint256 public preferredSaleTLYperETH;

    uint256 public mainSaleStartTime;
    uint256 public mainSaleEndTime;
    uint256 public mainSaleTLYperETH;
    
    uint256 public preSaleTokensLeftForSale = 70000000 * (uint256(10)**decimals);
    uint256 public preferredSaleTokensLeftForSale = 70000000 * (uint256(10)**decimals);
    
    uint256 public minimumAmountToParticipate = 0.5 ether;
    
    mapping(address => uint256) public addressToSpentEther;
    mapping(address => uint256) public addressToPurchasedTokens;
    
    function TALLY() public
    {
        owner = 0xd512fa9Ca3DF0a2145e77B445579D4210380A635;
        developmentFundAddress = 0x4D18700A05D92ae5e49724f13457e1959329e80e;
        foundationAddress = 0xf1A2e7a164EF56807105ba198ef8F2465B682B16;
        
        balances[developmentFundAddress] = 300000000 * (uint256(10)**decimals);
        Transfer(0x0, developmentFundAddress, balances[developmentFundAddress]);
        
        balances[this] = 1000000000 * (uint256(10)**decimals);
        Transfer(0x0, this, balances[this]);
        
        totalSupply_ = balances[this] + balances[developmentFundAddress];
        
        preSaleTLYperETH = 30000;
        preferredSaleTLYperETH = 25375;
        mainSaleTLYperETH = 20000;
        
        preSaleStartTime = 1518652800;
        preSaleEndTime = 1519516800;  
        
        preferredSaleStartTime = 1519862400;
        preferredSaleEndTime = 1521072000;  
        
        mainSaleStartTime = 1521504000;
        mainSaleEndTime = 1526774400;  
        
        tokenSaleEnabled = true;
        
        developmentFundUnlockTime = now + DEVELOPMENT_FUND_LOCK_TIMESPAN;
    }
    
    function () payable external
    {
        require(tokenSaleEnabled);
        
        require(msg.value >= minimumAmountToParticipate);
        
        uint256 tokensPurchased;
        if (now >= preSaleStartTime && now < preSaleEndTime)
        {
            tokensPurchased = msg.value.mul(preSaleTLYperETH);
            preSaleTokensLeftForSale = preSaleTokensLeftForSale.sub(tokensPurchased);
        }
        else if (now >= preferredSaleStartTime && now < preferredSaleEndTime)
        {
            tokensPurchased = msg.value.mul(preferredSaleTLYperETH);
            preferredSaleTokensLeftForSale = preferredSaleTokensLeftForSale.sub(tokensPurchased);
        }
        else if (now >= mainSaleStartTime && now < mainSaleEndTime)
        {
            tokensPurchased = msg.value.mul(mainSaleTLYperETH);
        }
        else
        {
            revert();
        }
        
        addressToSpentEther[msg.sender] = addressToSpentEther[msg.sender].add(msg.value);
        addressToPurchasedTokens[msg.sender] = addressToPurchasedTokens[msg.sender].add(tokensPurchased);
        
        this.transfer(msg.sender, tokensPurchased);
    }
    
    function refund() external
    {
         
        require(now < mainSaleEndTime);
        
        uint256 tokensRefunded = addressToPurchasedTokens[msg.sender];
        uint256 etherRefunded = addressToSpentEther[msg.sender];
        addressToPurchasedTokens[msg.sender] = 0;
        addressToSpentEther[msg.sender] = 0;
        
         
        balances[msg.sender] = balances[msg.sender].sub(tokensRefunded);
        balances[this] = balances[this].add(tokensRefunded);
        Transfer(msg.sender, this, tokensRefunded);
        
         
        if (now < preSaleEndTime)
        {
            preSaleTokensLeftForSale = preSaleTokensLeftForSale.add(tokensRefunded);
        }
        else if (now < preferredSaleEndTime)
        {
            preferredSaleTokensLeftForSale = preferredSaleTokensLeftForSale.add(tokensRefunded);
        }
        
         
        msg.sender.transfer(etherRefunded);
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool)
    {
        if (msg.sender == developmentFundAddress && now < developmentFundUnlockTime) revert();
        super.transfer(_to, _value);
    }
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool)
    {
        if (msg.sender == developmentFundAddress && now < developmentFundUnlockTime) revert();
        super.transfer(_to, _value, _data);
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
    {
        if (_from == developmentFundAddress && now < developmentFundUnlockTime) revert();
        super.transferFrom(_from, _to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool)
    {
        if (_from == developmentFundAddress && now < developmentFundUnlockTime) revert();
        super.transferFrom(_from, _to, _value, _data);
    }
    
     
    function drain() external onlyOwner
    {
        owner.transfer(this.balance);
    }
    
     
    function enableTokenSale() external onlyOwner
    {
        tokenSaleEnabled = true;
    }
    function disableTokenSale() external onlyOwner
    {
        tokenSaleEnabled = false;
    }
    
    function moveUnsoldTokensToFoundation() external onlyOwner
    {
        this.transfer(foundationAddress, balances[this]);
    }
    
     
    function setPreSaleTLYperETH(uint256 _newTLYperETH) public onlyOwner
    {
        preSaleTLYperETH = _newTLYperETH;
    }
    function setPreSaleStartAndEndTime(uint256 _newStartTime, uint256 _newEndTime) public onlyOwner
    {
        preSaleStartTime = _newStartTime;
        preSaleEndTime = _newEndTime;
    }
    
     
    function setPreferredSaleTLYperETH(uint256 _newTLYperETH) public onlyOwner
    {
        preferredSaleTLYperETH = _newTLYperETH;
    }
    function setPreferredSaleStartAndEndTime(uint256 _newStartTime, uint256 _newEndTime) public onlyOwner
    {
        preferredSaleStartTime = _newStartTime;
        preferredSaleEndTime = _newEndTime;
    }
    
     
    function setMainSaleTLYperETH(uint256 _newTLYperETH) public onlyOwner
    {
        mainSaleTLYperETH = _newTLYperETH;
    }
    function setMainSaleStartAndEndTime(uint256 _newStartTime, uint256 _newEndTime) public onlyOwner
    {
        mainSaleStartTime = _newStartTime;
        mainSaleEndTime = _newEndTime;
    }
}