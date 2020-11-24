 

pragma solidity ^ 0.4 .15;


 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}



 
contract StandardToken is ERC20, SafeMath {

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) revert();
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value)  returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract owned {
    address owner;

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}

contract Fish is owned, StandardToken {

  string public constant TermsOfUse = "https://github.com/triangles-things/fish.project/blob/master/terms-of-use.md";

   

  string public constant symbol = "FSH";
  string public constant name = "Fish";
  uint8 public constant decimals = 3;

   

  function Fish() {
    owner = msg.sender;
    balances[msg.sender] = 1;                                                    
    totalSupply = 1;
    buyPrice_wie= 100000000000000;                                               
    sellPrice_wie = buyPrice_wie * sell_ppc / 100;
  }

  function () payable { revert(); }

   

   
  uint32 public dailyGrowth_ppm = 6100;                                          
  uint public dailyGrowthUpdated_date = now;                                     
  
  uint32 private constant dailyGrowthMin_ppm =  6096;                            
  uint32 private constant dailyGrowthMax_ppm = 23374;                            
  
  uint32 public constant sell_ppc = 90;                                          

  event DailyGrowthUpdate(uint _newRate_ppm);
  event PriceAdjusted(uint _newBuyPrice_wei, uint _newSellPrice_wei);

   
  modifier adjustPrice() {
    if ( (dailyGrowthUpdated_date + 1 days) < now ) {
      dailyGrowthUpdated_date = now;
      buyPrice_wie = buyPrice_wie * (1000000 + dailyGrowth_ppm) / 1000000;
      sellPrice_wie = buyPrice_wie * sell_ppc / 100;
      PriceAdjusted(buyPrice_wie, sellPrice_wie);
    }
    _;
  }

   
  function setGrowth(uint32 _newGrowth_ppm) onlyOwner external returns(bool result) {
    if (_newGrowth_ppm >= dailyGrowthMin_ppm &&
        _newGrowth_ppm <= dailyGrowthMax_ppm
    ) {
      dailyGrowth_ppm = _newGrowth_ppm;
      DailyGrowthUpdate(_newGrowth_ppm);
      return true;
    } else {
      return false;
    }
  }

   

  uint256 public sellPrice_wie;
  uint256 public buyPrice_wie;

   
  function buy() adjustPrice payable external {
    require(msg.value >= buyPrice_wie);
    var amount = safeDiv(msg.value, buyPrice_wie);

    assignBountryToReferals(msg.sender, amount);                                 

     
    if ( balances[msg.sender] == 0 && referrals[msg.sender][0] != 0 ) {
       
      amount = amount * (100 + landingDiscount_ppc) / 100;
    }

    issueTo(msg.sender, amount);
  }

   
  function sell(uint256 _amount) adjustPrice external {
    require(_amount > 0 && balances[msg.sender] >= _amount);
    uint moneyWorth = safeMul(_amount, sellPrice_wie);
    require(this.balance > moneyWorth);                                          
    
    if (
        balances[this] + _amount > balances[this] &&
        balances[msg.sender] - _amount < balances[msg.sender]
    ) {
      balances[this] = safeAdd(balances[this], _amount);                         
      balances[msg.sender] = safeSub(balances[msg.sender], _amount);             
      if (!msg.sender.send(moneyWorth)) {                                        
        revert();                                                                
      } else {
        Transfer(msg.sender, this, _amount);                                     
      }        
    } else {
      revert();                                                                  
    }  
  }

   
  function issueTo(address _beneficiary, uint256 _amount_tkns) private {
    if (
        balances[this] >= _amount_tkns
    ) {
       
      balances[this] = safeSub(balances[this], _amount_tkns);
      balances[_beneficiary] = safeAdd(balances[_beneficiary], _amount_tkns);
    } else {
       
      uint diff = safeSub(_amount_tkns, balances[this]);

      totalSupply = safeAdd(totalSupply, diff);
      balances[this] = 0;
      balances[_beneficiary] = safeAdd(balances[_beneficiary], _amount_tkns);
    }
    
    Transfer(this, _beneficiary, _amount_tkns);
  }
  
   
    
  mapping(address => address[3]) referrals;
  mapping(address => uint256) bounties;

  uint32 public constant landingDiscount_ppc = 4;                                

   
  function referral(address _referral) external returns(bool) {
    if ( balances[_referral] > 0 &&                                               
         balances[msg.sender] == 0  &&                                           
         referrals[msg.sender][0] == 0                                            
    ) {
      var referral_referrals = referrals[_referral];
      referrals[msg.sender] = [_referral, referral_referrals[0], referral_referrals[1]];
      return true;
    }
    
    return false;
  }

    
  function assignBountryToReferals(address _referralsOf, uint256 _amount) private {
    var refs = referrals[_referralsOf];
    
    if (refs[0] != 0) {
     issueTo(refs[0], (_amount * 4) / 100);                                      
      if (refs[1] != 0) {
        issueTo(refs[1], (_amount * 2) / 100);                                   
        if (refs[2] != 0) {
          issueTo(refs[2], (_amount * 1) / 100);                                 
       }
      }
    }
  }

   
  function assignBounty(address _account, uint256 _amount) onlyOwner external returns(bool) {
    require(_amount > 0); 
     
    if (balances[_account] > 0 &&                                                
        bounties[_account] + _amount <= 1000000                                  
    ) {
      issueTo(_account, _amount);
      return true;
    } else {
      return false;
    }
  }
}