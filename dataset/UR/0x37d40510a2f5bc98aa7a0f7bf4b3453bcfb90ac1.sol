 

pragma solidity 0.4.18;


 
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


contract BBIToken is StandardToken {

    string  public constant name    = "Beluga Banking Infrastructure Token";
    string  public constant symbol  = "BBI";
    uint256 public constant decimals= 18;   
    
    uint  public totalUsed   = 0;
    uint  public etherRaised = 0;

     

    uint public icoEndDate        = 1522540799;    
    uint constant SECONDS_IN_YEAR = 31536000;      

     
    bool public halted = false;              
    
    uint  public etherCap               =  30000 * (10 ** uint256(decimals));   

    uint  public maxAvailableForSale    =  29800000 * (10 ** uint256(decimals));       
    uint  public tokensPreSale          =  10200000 * (10 ** uint256(decimals));       
    uint  public tokensTeam             =  30000000 * (10 ** uint256(decimals));       
    uint  public tokensCommunity        =   5000000 * (10 ** uint256(decimals));       
    uint  public tokensMasterNodes      =   5000000 * (10 ** uint256(decimals));       
    uint  public tokensBankPartners     =   5000000 * (10 ** uint256(decimals));       
    uint  public tokensDataProviders    =   5000000 * (10 ** uint256(decimals));       

     

   uint constant teamInternal = 1;    
   uint constant teamPartners = 2;    
   uint constant icoInvestors = 3;    

     

    address public addressETHDeposit       = 0x0D2b5B427E0Bd97c71D4DF281224540044D279E1;  
    address public addressTeam             = 0x7C898F01e85a5387D58b52C6356B5AE0D5aa48ba;   
    address public addressCommunity        = 0xB7218D5a1f1b304E6bD69ea35C93BA4c1379FA43;  
    address public addressBankPartners     = 0xD5BC3c2894af7CB046398257df7A447F44b0CcA1;  
    address public addressDataProviders    = 0x9f6fce8c014210D823FdFFA274f461BAdC279A42;  
    address public addressMasterNodes      = 0x8ceA6dABB68bc9FCD6982E537A16bC9D219605b0;  
    address public addressPreSale          = 0x2526082305FdB4B999340Db3D53bD2a60F674101;     
    address public addressICOManager       = 0xE5B3eF1fde3761225C9976EBde8D67bb54d7Ae17;


     

    function BBIToken() public {
            
                     totalSupply_ = 90000000 * (10 ** uint256(decimals));     

                     balances[addressTeam] = tokensTeam;
                     balances[addressCommunity] = tokensCommunity;
                     balances[addressBankPartners] = tokensBankPartners;
                     balances[addressDataProviders] = tokensDataProviders;
                     balances[addressMasterNodes] = tokensMasterNodes;
                     balances[addressPreSale] = tokensPreSale;
                     balances[addressICOManager] = maxAvailableForSale;
                     
                     Transfer(this, addressTeam, tokensTeam);
                     Transfer(this, addressCommunity, tokensCommunity);
                     Transfer(this, addressBankPartners, tokensBankPartners);
                     Transfer(this, addressDataProviders, tokensDataProviders);
                     Transfer(this, addressMasterNodes, tokensMasterNodes);
                     Transfer(this, addressPreSale, tokensPreSale);
                     Transfer(this, addressICOManager, maxAvailableForSale);
                 
            }
    
     

    function  halt() onlyManager public{
        require(msg.sender == addressICOManager);
        halted = true;
    }

    function  unhalt() onlyManager public {
        require(msg.sender == addressICOManager);
        halted = false;
    }

     

    modifier onIcoRunning() {
         
        require( halted == false);
        _;
    }
   
    modifier onIcoStopped() {
         
      require( halted == true);
        _;
    }

    modifier onlyManager() {
         
        require(msg.sender == addressICOManager);
        _;
    }

     


   function transfer(address _to, uint256 _value) public returns (bool success) 
    {
           if ( msg.sender == addressICOManager) { return super.transfer(_to, _value); }           

            
           if ( !halted &&  msg.sender == addressTeam &&  SafeMath.sub(balances[msg.sender], _value) >= tokensTeam/2 && (now > icoEndDate + SECONDS_IN_YEAR/2) ) 
                { return super.transfer(_to, _value); }         

            
           if ( !halted &&  msg.sender == addressCommunity &&  SafeMath.sub(balances[msg.sender], _value) >= tokensCommunity/2 && (now > icoEndDate + SECONDS_IN_YEAR/2) )
                { return super.transfer(_to, _value); }            
           
            
           if ( !halted && identifyAddress(msg.sender) == icoInvestors && now > icoEndDate ) { return super.transfer(_to, _value); }
           
            
           if ( !halted && now > icoEndDate + SECONDS_IN_YEAR) { return super.transfer(_to, _value); }

        return false;
         
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) 
    {
           if ( msg.sender == addressICOManager) { return super.transferFrom(_from,_to, _value); }

            
           if ( !halted &&  msg.sender == addressTeam &&  SafeMath.sub(balances[msg.sender], _value) >= tokensTeam/2 && (now > icoEndDate + SECONDS_IN_YEAR/2) ) 
                { return super.transferFrom(_from,_to, _value); }
           
            
           if ( !halted &&  msg.sender == addressCommunity &&  SafeMath.sub(balances[msg.sender], _value) >= tokensCommunity/2 && (now > icoEndDate + SECONDS_IN_YEAR/2)) 
                { return super.transferFrom(_from,_to, _value); }      

            
           if ( !halted && identifyAddress(msg.sender) == icoInvestors && now > icoEndDate ) { return super.transferFrom(_from,_to, _value); }

            
           if ( !halted && now > icoEndDate + SECONDS_IN_YEAR) { return super.transferFrom(_from,_to, _value); }

        return false;
    }

   function identifyAddress(address _buyer) constant public returns(uint) {
        if (_buyer == addressTeam || _buyer == addressCommunity) return teamInternal;
        if (_buyer == addressMasterNodes || _buyer == addressBankPartners || _buyer == addressDataProviders) return teamPartners;
             return icoInvestors;
    }

     

    function  burn(uint256 _value)  onlyManager public returns (bool success) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] -= _value;             
        totalSupply_ -= _value;                     
        return true;
    }


         
    
    function buyBBITokens(address _buyer, uint256 _value) internal  {
             
            require(_buyer != 0x0);

             
            require(_value > 0);

             
            require(!halted);

             
            require(now < icoEndDate);

             
            uint tokens = (SafeMath.mul(_value, 960));

             
            require(SafeMath.add(totalUsed, tokens) < balances[addressICOManager]);

             
            require(SafeMath.add(etherRaised, _value) < etherCap);
            
            balances[_buyer] = SafeMath.add( balances[_buyer], tokens);
            balances[addressICOManager] = SafeMath.sub(balances[addressICOManager], tokens);
            totalUsed += tokens;            
            etherRaised += _value;  
      
            addressETHDeposit.transfer(_value);
            Transfer(this, _buyer, tokens );
        }

      
    function () payable onIcoRunning public {
                buyBBITokens(msg.sender, msg.value);           
            }
}