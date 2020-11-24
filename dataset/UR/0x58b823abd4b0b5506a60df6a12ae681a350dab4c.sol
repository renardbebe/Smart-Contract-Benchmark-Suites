 

pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Owned {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
} 
 








contract ERC20 is ERC20Basic {
   
  string  public  name = "zeosX";
  string  public  symbol;
  uint256  public  decimals = 18;  
    
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

  

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function multiTransfer(address[] _to,uint[] _value) public returns (bool);

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}




contract KYCVerification is Owned{
    
    mapping(address => bool) public kycAddress;
    
    event LogKYCVerification(address _kycAddress,bool _status);
    
    constructor () public {
        owner = msg.sender;
    }

    function updateVerifcationBatch(address[] _kycAddress,bool _status) onlyOwner public returns(bool)
    {
        for(uint tmpIndex = 0; tmpIndex < _kycAddress.length; tmpIndex++)
        {
            kycAddress[_kycAddress[tmpIndex]] = _status;
            emit LogKYCVerification(_kycAddress[tmpIndex],_status);
        }
        
        return true;
    }
    
    function updateVerifcation(address _kycAddress,bool _status) onlyOwner public returns(bool)
    {
        kycAddress[_kycAddress] = _status;
        
        emit LogKYCVerification(_kycAddress,_status);
        
        return true;
    }
    
    function isVerified(address _user) view public returns(bool)
    {
        return kycAddress[_user] == true; 
    }
}


contract FEXToken is Owned, BurnableToken {

    string public name = "SUREBANQA UTILITY TOKEN";
    string public symbol = "FEX";
    uint8 public decimals = 5;
    
    uint256 public initialSupply = 450000000 * (10 ** uint256(decimals));
    uint256 public totalSupply = 2100000000 * (10 ** uint256(decimals));
    uint256 public externalAuthorizePurchase = 0;
    
    mapping (address => bool) public frozenAccount;
    mapping(address => uint8) authorizedCaller;
    
    KYCVerification public kycVerification;
    bool public kycEnabled = true;

     
    uint allocatedEAPFund;
    uint allocatedAirdropAndBountyFund;
    uint allocatedMarketingFund;
    uint allocatedCoreTeamFund;
    uint allocatedTreasuryFund;
    
    uint releasedEAPFund;
    uint releasedAirdropAndBountyFund;
    uint releasedMarketingFund;
    uint releasedCoreTeamFund;
    uint releasedTreasuryFund;
    
     
    uint8 EAPMilestoneReleased = 0;  
    uint8 EAPVestingPercent = 25;  
    
    
     
    
    uint8 CoreTeamMilestoneReleased = 0;  
    uint8 CoreTeamVestingPercent = 25;  
    
     
    address public EAPFundReceiver = 0xD89c58BedFf2b59fcDDAE3D96aC32D777fa00bF4;
    address public AirdropAndBountyFundReceiver = 0xE4bBCE2795e5C7fF4B7a40b91f7b611526B5613E;
    address public MarketingFundReceiver = 0xbe4c8660ed5709dF4172936743e6868F11686DBe;
    address public CoreTeamFundReceiver = 0x2c1Ab4B9E4dD402120ECe5DF08E35644d2efCd35;
    address public TreasuryFundReceiver = 0xeB81295b4e60e52c60206B0D12C13F82a36Ac9B6;
    
     
    
    event EAPFundReleased(address _receiver,uint _amount,uint _milestone);
    event CoreTeamFundReleased(address _receiver,uint _amount,uint _milestone);

    bool public initialFundDistributed;
    uint public tokenVestingStartedOn; 


    modifier onlyAuthCaller(){
        require(authorizedCaller[msg.sender] == 1 || msg.sender == owner);
        _;
    }
    
    modifier kycVerified(address _guy) {
      if(kycEnabled == true){
          if(kycVerification.isVerified(_guy) == false)
          {
              revert("KYC Not Verified");
          }
      }
      _;
    }
    
    modifier frozenVerified(address _guy) {
        if(frozenAccount[_guy] == true)
        {
            revert("Account is freeze");
        }
        _;
    }
    
         
    event KYCMandateUpdate(bool _kycEnabled);
    event KYCContractAddressUpdate(KYCVerification _kycAddress);

     
    event FrozenFunds(address target, bool frozen);
    
     
    event AuthorizedCaller(address caller);
    event DeAuthorizedCaller(address caller);
    
     
    constructor () public {
        
        owner = msg.sender;
        balances[0xBcd5B67aaeBb9765beE438e4Ce137B9aE2181898] = totalSupply;
        
        emit Transfer(address(0x0), address(this), totalSupply);
        emit Transfer(address(this), address(0xBcd5B67aaeBb9765beE438e4Ce137B9aE2181898), totalSupply);

        authorizedCaller[msg.sender] = 1;
        emit AuthorizedCaller(msg.sender);

        tokenVestingStartedOn = now;
        initialFundDistributed = false;
    }

    function initFundDistribution() public onlyOwner 
    {
        require(initialFundDistributed == false);
        
         
        
        allocatedAirdropAndBountyFund = 125000000 * (10 ** uint256(decimals));
        _transfer(0xBcd5B67aaeBb9765beE438e4Ce137B9aE2181898,address(AirdropAndBountyFundReceiver),allocatedAirdropAndBountyFund);
        releasedAirdropAndBountyFund = allocatedAirdropAndBountyFund;
        
         
        
        allocatedMarketingFund = 70000000 * (10 ** uint256(decimals));
        _transfer(0xBcd5B67aaeBb9765beE438e4Ce137B9aE2181898,address(MarketingFundReceiver),allocatedMarketingFund);
        releasedMarketingFund = allocatedMarketingFund;
        
        
         
        
        allocatedEAPFund = 125000000 * (10 ** uint256(decimals));
        
         
        
        allocatedCoreTeamFund = 21000000 * (10 ** uint256(decimals));

         
        
        allocatedTreasuryFund = 2100000 * (10 ** uint256(decimals));
        
        initialFundDistributed = true;
    }
    
    function updateKycContractAddress(KYCVerification _kycAddress) public onlyOwner returns(bool)
    {
      kycVerification = _kycAddress;
      emit KYCContractAddressUpdate(_kycAddress);
      return true;
    }

    function updateKycMandate(bool _kycEnabled) public onlyAuthCaller returns(bool)
    {
        kycEnabled = _kycEnabled;
        emit KYCMandateUpdate(_kycEnabled);
        return true;
    }
    
     
    function authorizeCaller(address _caller) public onlyOwner returns(bool) 
    {
        authorizedCaller[_caller] = 1;
        emit AuthorizedCaller(_caller);
        return true;
    }
    
     
    function deAuthorizeCaller(address _caller) public onlyOwner returns(bool) 
    {
        authorizedCaller[_caller] = 0;
        emit DeAuthorizedCaller(_caller);
        return true;
    }
    
    function () public payable {
        revert();
         
    }
    
     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balances[_from] > _value);                 
        require (balances[_to].add(_value) > balances[_to]);  
        balances[_from] = balances[_from].sub(_value);                          
        balances[_to] = balances[_to].add(_value);                            
        emit Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] = balances[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }
    
     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    
    function purchaseToken(address _receiver, uint _tokens) onlyAuthCaller public {
        require(_tokens > 0);
        require(initialSupply > _tokens);
        
        initialSupply = initialSupply.sub(_tokens);
        _transfer(owner, _receiver, _tokens);               
        externalAuthorizePurchase = externalAuthorizePurchase.add(_tokens);
    }
    
     
    function transfer(address _to, uint256 _value) public kycVerified(msg.sender) frozenVerified(msg.sender) returns (bool) {
        _transfer(msg.sender,_to,_value);
        return true;
    }
    
     
    function multiTransfer(address[] _to,uint[] _value) public kycVerified(msg.sender) frozenVerified(msg.sender) returns (bool) {
        require(_to.length == _value.length, "Length of Destination should be equal to value");
        for(uint _interator = 0;_interator < _to.length; _interator++ )
        {
            _transfer(msg.sender,_to[_interator],_value[_interator]);
        }
        return true;    
    }


     
    function releaseTreasuryFund() public onlyAuthCaller returns(bool)
    {
        require(now >= tokenVestingStartedOn.add(730 days));
        require(allocatedTreasuryFund > 0);
        require(releasedTreasuryFund <= 0);
        
        _transfer(address(this),TreasuryFundReceiver,allocatedTreasuryFund);   
        
         
        releasedTreasuryFund = allocatedTreasuryFund;
        
        return true;
    }
    

     
    function releaseEAPFund() public onlyAuthCaller returns(bool)
    {
         
        require(EAPMilestoneReleased <= 4);
        require(allocatedEAPFund > 0);
        require(releasedEAPFund <= allocatedEAPFund);
        
        uint toBeReleased = 0 ;
        
        if(now <= tokenVestingStartedOn.add(365 days))
        {
            toBeReleased = allocatedEAPFund.mul(EAPVestingPercent).div(100);
            EAPMilestoneReleased = 1;
        }
        else if(now <= tokenVestingStartedOn.add(730 days))
        {
            toBeReleased = allocatedEAPFund.mul(EAPVestingPercent).div(100);
            EAPMilestoneReleased = 2;
        }
        else if(now <= tokenVestingStartedOn.add(1095 days))
        {
            toBeReleased = allocatedEAPFund.mul(EAPVestingPercent).div(100);
            EAPMilestoneReleased = 3;
        }
        else if(now <= tokenVestingStartedOn.add(1460 days))
        {
            toBeReleased = allocatedEAPFund.mul(EAPVestingPercent).div(100);
            EAPMilestoneReleased = 4;
        }
         
        else if(now > tokenVestingStartedOn.add(1460 days) && EAPMilestoneReleased != 4)
        {
            toBeReleased = allocatedEAPFund.sub(releasedEAPFund);
            EAPMilestoneReleased = 4;
        }
        else
        {
            revert();
        }
        
        if(toBeReleased > 0)
        {
            releasedEAPFund = releasedEAPFund.add(toBeReleased);
            _transfer(address(this),EAPFundReceiver,toBeReleased);
            
            emit EAPFundReleased(EAPFundReceiver,toBeReleased,EAPMilestoneReleased);
            
            return true;
        }
        else
        {
            revert();
        }
    }
    

     
    function releaseCoreTeamFund() public onlyAuthCaller returns(bool)
    {
         
        require(CoreTeamMilestoneReleased <= 4);
        require(allocatedCoreTeamFund > 0);
        require(releasedCoreTeamFund <= allocatedCoreTeamFund);
        
        uint toBeReleased = 0 ;
        
        if(now <= tokenVestingStartedOn.add(90 days))
        {
            toBeReleased = allocatedCoreTeamFund.mul(CoreTeamVestingPercent).div(100);
            CoreTeamMilestoneReleased = 1;
        }
        else if(now <= tokenVestingStartedOn.add(180 days))
        {
            toBeReleased = allocatedCoreTeamFund.mul(CoreTeamVestingPercent).div(100);
            CoreTeamMilestoneReleased = 2;
        }
        else if(now <= tokenVestingStartedOn.add(270 days))
        {
            toBeReleased = allocatedCoreTeamFund.mul(CoreTeamVestingPercent).div(100);
            CoreTeamMilestoneReleased = 3;
        }
        else if(now <= tokenVestingStartedOn.add(360 days))
        {
            toBeReleased = allocatedCoreTeamFund.mul(CoreTeamVestingPercent).div(100);
            CoreTeamMilestoneReleased = 4;
        }
         
        else if(now > tokenVestingStartedOn.add(360 days) && CoreTeamMilestoneReleased != 4)
        {
            toBeReleased = allocatedCoreTeamFund.sub(releasedCoreTeamFund);
            CoreTeamMilestoneReleased = 4;
        }
        else
        {
            revert();
        }
        
        if(toBeReleased > 0)
        {
            releasedCoreTeamFund = releasedCoreTeamFund.add(toBeReleased);
            _transfer(address(this),CoreTeamFundReceiver,toBeReleased);
            
            emit CoreTeamFundReleased(CoreTeamFundReceiver,toBeReleased,CoreTeamMilestoneReleased);
            
            return true;
        }
        else
        {
            revert();
        }
        
    }
}