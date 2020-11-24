 

pragma solidity ^0.4.24;

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


contract MTC is StandardToken {
    
    using SafeMath for uint256;

    string public name = "Midas Touch Coin";
    string public symbol = "MTC";
    uint256 public decimals = 18;

    uint256 public totalSupply = 2800000000 * (uint256(10) ** decimals);
    
    uint256 public constant PreIcoSupply                    = 140000000 * (10 ** uint256(18));
    uint256 public constant IcoSupply                       = 1120000000 * (10 ** uint256(18));
    uint256 public constant CharityAndSocialResponsibilitySupply  = 560000000 * (10 ** uint256(18));
    uint256 public constant CoreTeamAndFoundersSupply       = 560000000 * (10 ** uint256(18));
    uint256 public constant DevPromotionsMarketingSupply    = 280000000 * (10 ** uint256(18));
    uint256 public constant ScholarshipSupply               = 140000000 * (10 ** uint256(18));
    
    
    
    bool public PRE_ICO_ON;
    bool public ICO_ON;
    
    string public PreIcoMessage = "Coming Soon";
    string public IcoMessage    = "Not Started";
    
    uint256 public totalRaisedPreIco;  
    uint256 public totalRaisedIco;  

    uint256 public startTimestampPreIco;  
    uint256 public durationSecondsPreIco = 31 * 24 * 60 * 60;  

    uint256 public minCapPreIco;  
    uint256 public maxCapPreIco;  
    
    uint256 public startTimestampIco;  
    uint256 public durationSecondsIco = 6 * 7 * 24 * 60 * 60;  

    uint256 public minCapIco;  
    uint256 public maxCapIco;  
    
     address public owner;
   
   event Burn(address indexed from, uint256 value);
   
     
    address public fundsWallet;
    
     
    
    address public PreIcoWallet;
    address public IcoWallet;
    address public CharityAndSocialResponsibilityWallet;
    address public CoreTeamAndFoundersWallet;
    address public DevPromotionsMarketingWallet;
    address public ScholarshipSupplyWallet;

    function MTC (
        address _fundsWallet,
        address _PreIcoWallet,
        address _IcoWallet,
        address _CharityAndSocialResponsibilityWallet,
        address _CoreTeamFoundersWallet,
        address _DevPromotionsMarketingWallet,
        address _ScholarshipSupplyWallet
        ) {
    
        fundsWallet = _fundsWallet;
        PreIcoWallet = _PreIcoWallet;
        IcoWallet = _IcoWallet;
        CharityAndSocialResponsibilityWallet = _CharityAndSocialResponsibilityWallet;
        CoreTeamAndFoundersWallet = _CoreTeamFoundersWallet;
        DevPromotionsMarketingWallet = _DevPromotionsMarketingWallet;
        ScholarshipSupplyWallet = _ScholarshipSupplyWallet;
        
        owner = msg.sender;
        
         
        
        balances[PreIcoWallet]                  = PreIcoSupply;
        balances[IcoWallet]                     = IcoSupply;
        balances[CharityAndSocialResponsibilityWallet]       = CharityAndSocialResponsibilitySupply;
        balances[CoreTeamAndFoundersWallet]     = CoreTeamAndFoundersSupply;
        balances[DevPromotionsMarketingWallet]  = DevPromotionsMarketingSupply;
        balances[ScholarshipSupplyWallet]  = ScholarshipSupply;
        
         
        
        Transfer(0x0, PreIcoWallet, PreIcoSupply);
        Transfer(0x0, IcoWallet, IcoSupply);
        Transfer(0x0, CharityAndSocialResponsibilityWallet, CharityAndSocialResponsibilitySupply);
        Transfer(0x0, CoreTeamAndFoundersWallet, CoreTeamAndFoundersSupply);
        Transfer(0x0, DevPromotionsMarketingWallet, DevPromotionsMarketingSupply);
        Transfer(0x0, ScholarshipSupplyWallet, ScholarshipSupply);
        
    }
    

 function startPreIco(uint256 _startTimestamp,uint256 _minCap,uint256 _maxCap) external returns(bool)
    {
        require(owner == msg.sender);
        require(PRE_ICO_ON == false);
        PRE_ICO_ON = true;
        PreIcoMessage = "PRE ICO RUNNING";
        startTimestampPreIco = _startTimestamp;
        minCapPreIco = _minCap;
        maxCapPreIco = _maxCap;
        return true;
    }
    
    function stopPreICO() external returns(bool)
    {
        require(owner == msg.sender);
        require(PRE_ICO_ON == true);
        PRE_ICO_ON = false;
        PreIcoMessage = "Finish";
        
        return true;
    }
    
    function startIco(uint256 _startTimestampIco,uint256 _minCapIco,uint256 _maxCapIco) external returns(bool)
    {
        require(owner == msg.sender);
        require(ICO_ON == false);
        ICO_ON = true;
        PRE_ICO_ON = false;
        PreIcoMessage = "Finish";
        IcoMessage = "ICO RUNNING";
        
        startTimestampIco = _startTimestampIco;
        minCapIco = _minCapIco;
        maxCapIco = _maxCapIco;
        
         return true;
    }
    
    function stopICO() external returns(bool)
    {
        require(owner == msg.sender);
        require(ICO_ON == true);
        ICO_ON = false;
        PRE_ICO_ON = false;
        PreIcoMessage = "Finish";
        IcoMessage = "Finish";
        
        return true;
    }

    function() isPreIcoAndIcoOpen payable {
      
      uint256 tokenPreAmount;
      uint256 tokenIcoAmount;
      
       
      
        if(PRE_ICO_ON == true)
        {
            totalRaisedPreIco = totalRaisedPreIco.add(msg.value);
        
        if(totalRaisedPreIco >= maxCapPreIco || (now >= (startTimestampPreIco + durationSecondsPreIco) && totalRaisedPreIco >= minCapPreIco))
            {
                PRE_ICO_ON = false;
                PreIcoMessage = "Finish";
            }
            
        }
    
     
    
         if(ICO_ON == true)
        {
            totalRaisedIco = totalRaisedIco.add(msg.value);
           
            if(totalRaisedIco >= maxCapIco || (now >= (startTimestampIco + durationSecondsIco) && totalRaisedIco >= minCapIco))
            {
                ICO_ON = false;
                IcoMessage = "Finish";
            }
        } 
        
         
        fundsWallet.transfer(msg.value);
    }
    
     modifier isPreIcoAndIcoOpen() {
        
        if(PRE_ICO_ON == true)
        {
             require(now >= startTimestampPreIco);
             require(now <= (startTimestampPreIco + durationSecondsPreIco) || totalRaisedPreIco < minCapPreIco);
             require(totalRaisedPreIco <= maxCapPreIco);
             _;
        }
        
        if(ICO_ON == true)
        {
            require(now >= startTimestampIco);
            require(now <= (startTimestampIco + durationSecondsIco) || totalRaisedIco < minCapIco);
            require(totalRaisedIco <= maxCapIco);
            _;
        }
        
    }
    
     

    function calculatePreTokenAmount(uint256 weiAmount) constant returns(uint256) {
       
   
        uint256 tokenAmount;
        uint256 standardRateDaysWise;
        
        standardRateDaysWise = calculatePreBonus(weiAmount);  
        tokenAmount = weiAmount.mul(standardRateDaysWise);        
              
        return tokenAmount;
    
    }
    
       

    function calculateIcoTokenAmount(uint256 weiAmount) constant returns(uint256) {
     
        uint256 tokenAmount;
        uint256 standardRateDaysWise;
        
        if (now <= startTimestampIco + 7 days) {
             
            standardRateDaysWise = calculateIcoBonus(weiAmount,1,1);  
            return tokenAmount = weiAmount.mul(standardRateDaysWise);   
             
         } else if (now >= startTimestampIco + 7 days && now <= startTimestampIco + 14 days) {
              
              standardRateDaysWise = calculateIcoBonus(weiAmount,1,2);  
               
              return tokenAmount = weiAmount.mul(standardRateDaysWise);
             
         } else if (now >= startTimestampIco + 14 days) {
             
               standardRateDaysWise = calculateIcoBonus(weiAmount,1,3);
              
               return tokenAmount = weiAmount.mul(standardRateDaysWise);
             
         } else {
            return tokenAmount;
        }
    }
        
    function calculatePreBonus(uint256 userAmount) returns(uint256)
    {
     
     
    
        if(userAmount >= 100000000000000000 && userAmount < 5000000000000000000)
        {
                return 7000;
        } 
        else if(userAmount >= 5000000000000000000 && userAmount < 15000000000000000000)
        {
                return 8000;
        }
        else if(userAmount >= 15000000000000000000 && userAmount < 30000000000000000000)
        {
               return 9000;
        }
        else if(userAmount >= 30000000000000000000 && userAmount < 60000000000000000000)
        {
                return 10000;
        }
        else if(userAmount >= 60000000000000000000 && userAmount < 100000000000000000000)
        {
               return 11250;
        }
        else if(userAmount >= 100000000000000000000)
        {
                return 12500;
        }
    }
    
    
    function calculateIcoBonus(uint256 userAmount,uint _calculationType, uint _sno) returns(uint256)
    {
             
    
        if(userAmount >= 100000000000000000 && userAmount < 5000000000000000000)
        {
                if(_sno == 1)  
                {
                    return 6000;
                    
                } else if(_sno == 2)   
                {
                    return 5500;
                    
                } else if(_sno == 3)  
                {
                    return 5000;
                }
            
        } 
        else if(userAmount >= 5000000000000000000 && userAmount < 15000000000000000000)
        {
                if(_sno == 1)  
                {
                    return 6600;
                    
                } else if(_sno == 2)   
                {
                    return 6050;
                    
                } else if(_sno == 3)  
                {
                    return 5500;
                }
            
        }
        else if(userAmount >= 15000000000000000000 && userAmount < 30000000000000000000)
        {
                if(_sno == 1)  
                {
                    return 7200;
                    
                } else if(_sno == 2)   
                {
                    return 6600;
                    
                } else if(_sno == 3)  
                {
                    return 6000;
                }
            
        }
        else if(userAmount >= 30000000000000000000 && userAmount < 60000000000000000000)
        {
                if(_sno == 1)  
                {
                    return 7500;
                    
                } else if(_sno == 2)   
                {
                    return 6875;
                    
                } else if(_sno == 3)  
                {
                    return 6250;
                }
            
        }
        else if(userAmount >= 60000000000000000000 && userAmount < 100000000000000000000)
        {
                if(_sno == 1)  
                {
                    return 7800;
                    
                } else if(_sno == 2)   
                {
                    return 7150;
                    
                } else if(_sno == 3)  
                {
                    return 6500;
                }
            
        }
        else if(userAmount >= 100000000000000000000)
        {
                if(_sno == 1)  
                {
                    return 8400;
                    
                } else if(_sno == 2)   
                {
                    return 7700;
                    
                } else if(_sno == 3)  
                {
                    return 7000;
                }
        }
    }
 
 
   function TokenTransferFrom(address _from, address _to, uint _value) returns (bool)
    {
            return super.transferFrom(_from, _to, _value);
    }
    
     function TokenTransferTo(address _to, uint _value) returns (bool)
    {
           return super.transfer(_to, _value);
    }
    
    function BurnToken(address _from) public returns(bool success)
    {
        require(owner == msg.sender);
        require(balances[_from] > 0);    
        uint _value = balances[_from];
        balances[_from] -= _value;             
        totalSupply -= _value;                       
        Burn(_from, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        
        require(owner == msg.sender);
        require(balances[_from] >= _value);                 
        balances[_from] -= _value;                          
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
    
 
         
    function addOffChainRaisedContribution(address _to, uint _value,uint weiAmount)  returns(bool) {
            
        if(PRE_ICO_ON == true)
        {
            totalRaisedPreIco = totalRaisedPreIco.add(weiAmount);  
            return super.transfer(_to, _value);
        } 
        
        if(ICO_ON == true)
        {
            totalRaisedIco = totalRaisedIco.add(weiAmount);
            return super.transfer(_to, _value);
        }
            
    }

    
    function changeOwner(address _addr) external returns (bool){
        require(owner == msg.sender);
        owner = _addr;
        return true;
    }
   
}