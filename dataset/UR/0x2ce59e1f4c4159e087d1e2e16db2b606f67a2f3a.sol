 

pragma solidity 0.4.24;


 
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
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor () public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
contract ERC20Basic {
     
  uint256 public totalSupply;
  
  function balanceOf(address _owner) public view returns (uint256 balance);
  
  function transfer(address _to, uint256 _amount) public returns (bool success);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);
  
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
  
  function approve(address _spender, uint256 _amount) public returns (bool success);
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

   
  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(_to != address(0));
    require(balances[msg.sender] >= _amount && _amount > 0
        && balances[_to].add(_amount) > balances[_to]);

     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender, _to, _amount);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {
  
  
  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    require(_to != address(0));
    require(balances[_from] >= _amount);
    require(allowed[_from][msg.sender] >= _amount);
    require(_amount > 0 && balances[_to].add(_amount) > balances[_to]);

    balances[_from] = balances[_from].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    emit Transfer(_from, _to, _amount);
    return true;
  }

   
  function approve(address _spender, uint256 _amount) public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract BurnableToken is StandardToken, Ownable {

    event Burn(address indexed burner, uint256 value);

   

  function burn(uint256 _value) public {

    _burn(msg.sender, _value);

  }

  function _burn(address _who, uint256 _value) internal {

    require(_value <= balances[_who]);
     
     
    balances[_who] = balances[_who].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
} 

 

contract MintableToken is StandardToken, Ownable {
    using SafeMath for uint256;

  mapping(address => uint256)public shares;
  
  address[] public beneficiaries;
 
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event BeneficiariesAdded();
  
  uint256 public lastMintingTime;
  uint256 public mintingStartTime = 1543622400;
  uint256 public mintingThreshold = 31536000;
  uint256 public lastMintedTokens = 91000000000000000;

  bool public mintingFinished = false;
  
  

  modifier canMint() {
    require(!mintingFinished);
    require(totalSupply < 910000000000000000); 
    require(beneficiaries.length == 7); 
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   

  function mint() hasMintPermission  canMint public  returns (bool){
    
    uint256 _amount = tokensToMint();
    
    totalSupply = totalSupply.add(_amount);
    
    
    for(uint8 i = 0; i<beneficiaries.length; i++){
        
        balances[beneficiaries[i]] = balances[beneficiaries[i]].add(_amount.mul(shares[beneficiaries[i]]).div(100));
        emit Mint(beneficiaries[i], _amount.mul(shares[beneficiaries[i]]).div(100));
        emit Transfer(address(0), beneficiaries[i], _amount.mul(shares[beneficiaries[i]]).div(100));
    }
    
    lastMintingTime = now;
    
   
     return true;
  }
  
   
  function tokensToMint()private returns(uint256 _tokensToMint){
      
      uint8 tiersToBeMinted = currentTier() - getTierForLastMiniting();
      
      require(tiersToBeMinted>0);
      
      for(uint8 i = 0;i<tiersToBeMinted;i++){
          _tokensToMint = _tokensToMint.add(lastMintedTokens.sub(lastMintedTokens.mul(10).div(100)));
          lastMintedTokens = lastMintedTokens.sub(lastMintedTokens.mul(10).div(100));
      }
      
      return _tokensToMint;
      
  }
 
  function currentTier()private view returns(uint8 _tier) {
      
      uint256 currentTime = now;
      
      uint256 nextTierStartTime = mintingStartTime;
      
      while(nextTierStartTime < currentTime) {
          nextTierStartTime = nextTierStartTime.add(mintingThreshold);
          _tier++;
      }
      
      return _tier;
      
  }
  
  function getTierForLastMiniting()private view returns(uint8 _tier) {
      
       uint256 nextTierStartTime = mintingStartTime;
      
      while(nextTierStartTime < lastMintingTime) {
          nextTierStartTime = nextTierStartTime.add(mintingThreshold);
          _tier++;
      }
      
      return _tier;
      
  }
  

   

  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }


function beneficiariesPercentage(address[] _beneficiaries, uint256[] percentages) onlyOwner external returns(bool){
   
    require(_beneficiaries.length == 7);
    require(percentages.length == 7);
    
    uint256 sumOfPercentages;
    
    if(beneficiaries.length>0) {
        
        for(uint8 j = 0;j<beneficiaries.length;j++) {
            
            shares[beneficiaries[j]] = 0;
            delete beneficiaries[j];
            
            
        }
        beneficiaries.length = 0;
        
    }

    for(uint8 i = 0; i < _beneficiaries.length; i++){

      require(_beneficiaries[i] != 0x0);
      require(percentages[i] > 0);
      beneficiaries.push(_beneficiaries[i]);
      
      shares[_beneficiaries[i]] = percentages[i];
      sumOfPercentages = sumOfPercentages.add(percentages[i]); 
     
    }

    require(sumOfPercentages == 100);
    emit BeneficiariesAdded();
    return true;
  } 
}

 
 contract EraSwapToken is BurnableToken, MintableToken{
     string public name ;
     string public symbol ;
     uint8 public decimals = 8 ;
     
      
     function ()public payable {
         revert();
     }
     
      
     constructor (
            uint256 initialSupply,
            string tokenName,
            string tokenSymbol
         ) public {
         totalSupply = initialSupply.mul( 10 ** uint256(decimals));  
         name = tokenName;
         symbol = tokenSymbol;
         balances[msg.sender] = totalSupply;
         
          
         emit Transfer(address(0), msg.sender, totalSupply);
     }
     
      
    function getTokenDetail() public view returns (string, string, uint256) {
	    return (name, symbol, totalSupply);
    }
 }