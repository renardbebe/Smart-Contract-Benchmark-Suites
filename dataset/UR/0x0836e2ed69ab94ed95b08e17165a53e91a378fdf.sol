 

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


contract SAVERToken is Owned, BurnableToken {

    string public name = "SureSAVER PRIZE-LINKED REWARD SAVINGS ACCOUNT TOKEN";
    string public symbol = "SAVER";
    uint8 public decimals = 2;
    bool public kycEnabled = true;
    
    uint256 public initialSupply = 81000000 * (10 ** uint256(decimals));
    uint256 public totalSupply = 810000000 * (10 ** uint256(decimals));
    uint256 public externalAuthorizePurchase = 0;
    
    mapping (address => bool) public frozenAccount;
    mapping(address => uint8) authorizedCaller;
    mapping(address => uint) public lockInPeriodForAccount;
    mapping(address => uint) public lockInPeriodDurationForAccount;

    
    KYCVerification public kycVerification;
    
    
     
    address public OptOutPenaltyReceiver = 0x63a2311603aE55d1C7AC5DfA19225Ac2B7b5Cf6a;
    uint public OptOutPenaltyPercent = 20;  
    
    
    modifier onlyAuthCaller(){
        require(authorizedCaller[msg.sender] == 1 || owner == msg.sender);
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

    
    modifier isAccountLocked(address _guy) {
        if((_guy != owner || authorizedCaller[_guy] != 1) && lockInPeriodForAccount[_guy] != 0)
        {
            if(now < lockInPeriodForAccount[_guy])
            {
                revert("Account is Locked");
            }
        }
        
        _;
    }
    
    
    
         
    event KYCMandateUpdate(bool _kycEnabled);
    event KYCContractAddressUpdate(KYCVerification _kycAddress);

     
    event FrozenFunds(address target, bool frozen);
    
     
    event AuthorizedCaller(address caller);
    event DeAuthorizedCaller(address caller);
    
     
    
    event LockinPeriodUpdated(address _guy, uint _lockinPeriod,uint _lockinPeriodDuration);
    event OptedOutLockinPeriod(address indexed _guy,uint indexed _optOutDate, uint _penaltyPercent,uint _penaltyAmt);
    event LockinOptoutPenaltyPercentUpdated(address _guy, uint _percent);
    event LockinOptoutPenaltyReceiverUpdated(address _newReceiver);

    

     
    constructor () public {
        
        owner = msg.sender;

        balances[0xBcd5B67aaeBb9765beE438e4Ce137B9aE2181898] = totalSupply;
        
        
        authorizedCaller[msg.sender] = 1;
        emit AuthorizedCaller(msg.sender);

        emit Transfer(address(0x0), address(this), totalSupply);
        emit Transfer(address(this), address(0xBcd5B67aaeBb9765beE438e4Ce137B9aE2181898), totalSupply);
        
    }
    
    
    
     


     

    function updateKycContractAddress(KYCVerification _kycAddress) public onlyOwner returns(bool)
    {
      kycVerification = _kycAddress;
      emit KYCContractAddressUpdate(_kycAddress);
      return true;
    }

     

    function updateKycMandate(bool _kycEnabled) public onlyAuthCaller
    {
        kycEnabled = _kycEnabled;
        emit KYCMandateUpdate(_kycEnabled);
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
    
    
     
    function _transfer(address _from, address _to, uint _value) internal 
    {
        require (_to != 0x0);                                
        require (balances[_from] > _value);                 
        require (balances[_to].add(_value) > balances[_to]);  
        balances[_from] = balances[_from].sub(_value);                          
        balances[_to] = balances[_to].add(_value);                            
        emit Transfer(_from, _to, _value);
    }

     


     
    function mintToken(address _target, uint256 _mintedAmount) onlyOwner public 
    {
        balances[_target] = balances[_target].add(_mintedAmount);
        totalSupply = totalSupply.add(_mintedAmount);
        emit Transfer(0, this, _mintedAmount);
        emit Transfer(this, _target, _mintedAmount);
    }
    

     
    function freezeAccount(address _target, bool _freeze) onlyOwner public 
    {
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }


     
    function purchaseToken(address _receiver, uint _tokens,uint _lockinPeriod,uint _lockinPeriodDuration) onlyAuthCaller public {
        require(_tokens > 0);
        require(initialSupply > _tokens);
        
        initialSupply = initialSupply.sub(_tokens);
        _transfer(owner, _receiver, _tokens);               
        externalAuthorizePurchase = externalAuthorizePurchase.add(_tokens);
        
         
        if(_lockinPeriod != 0)
        {
            lockInPeriodForAccount[_receiver] = _lockinPeriod;
            lockInPeriodDurationForAccount[_receiver] = _lockinPeriodDuration;
            emit LockinPeriodUpdated(_receiver, _lockinPeriod,_lockinPeriodDuration);
        }
        
    }
    
    

    


     
    function transfer(address _to, uint256 _value) public kycVerified(msg.sender) isAccountLocked(msg.sender) frozenVerified(msg.sender) returns (bool) {
        _transfer(msg.sender,_to,_value);
        return true;
    }
    

     
    function multiTransfer(address[] _to,uint[] _value) public kycVerified(msg.sender) isAccountLocked(msg.sender) frozenVerified(msg.sender) returns (bool) {
        require(_to.length == _value.length, "Length of Destination should be equal to value");
        for(uint _interator = 0;_interator < _to.length; _interator++ )
        {
            _transfer(msg.sender,_to[_interator],_value[_interator]);
        }
        return true;    
    }
    
     
    function optOutLockinPeriod() public returns (bool)
    {
         
        require(owner != msg.sender,"Owner Account Detected");
        
         
        require(authorizedCaller[msg.sender] != 1,"Owner Account Detected");
        
         
        require(now < lockInPeriodForAccount[msg.sender],"Account Already Unlocked");
        
         
        require(balances[msg.sender] > 0,"Not sufficient balance available");
        
         
        uint _penaltyAmt = balances[msg.sender].mul(OptOutPenaltyPercent).div(100);
        
         
        _transfer(msg.sender,OptOutPenaltyReceiver,_penaltyAmt);
        
         
        lockInPeriodForAccount[msg.sender] = 0;     
        lockInPeriodDurationForAccount[msg.sender] = 0;     
        
         
        emit OptedOutLockinPeriod(msg.sender,now, OptOutPenaltyPercent,_penaltyAmt);
        
        return true;
    }
    
     
    function updateLockinOptoutPenaltyPercent(uint _percent) onlyAuthCaller public returns(bool)
    {
        OptOutPenaltyPercent = _percent;

        emit LockinOptoutPenaltyPercentUpdated(msg.sender,_percent);

        return true;
    }  

     
    function updateLockinOptoutPenaltyReceiver(address _newReceiver) onlyAuthCaller public returns(bool)
    {
        OptOutPenaltyReceiver = _newReceiver;

        emit LockinOptoutPenaltyReceiverUpdated(_newReceiver);

        return true;
    }  
    
}