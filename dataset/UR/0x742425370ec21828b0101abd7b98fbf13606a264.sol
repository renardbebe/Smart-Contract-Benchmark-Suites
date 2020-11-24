 

 

pragma solidity ^0.4.24;

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

 

pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;


contract ERC20 is ERC20Basic {
   
  string  public  name = "zeosX";
  string  public  symbol;
  uint256  public  decimals = 18;  
    
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.4.24;
 
 
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

 

pragma solidity ^0.4.24;



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

 

pragma solidity ^0.4.24;



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

 

pragma solidity ^0.4.24;


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

 

pragma solidity ^0.4.24;


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

 

pragma solidity ^0.4.24;
 




interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract STRIVEToken is Owned, BurnableToken {
    string public name = "SUREBANQA TRUSTLESS, REWARD, INVESTMENT &  VALUE ENABLER TOKEN";
    string public symbol = "STRIVE";
    uint8 public decimals = 10;
    
    uint256 public initialSupply = 1000000000 * (10 ** uint256(decimals));
    uint256 public totalSupply = 1000000000 * (10 ** uint256(decimals));
    uint256 public externalAuthorizePurchase = 0;
    
    mapping (address => bool) public frozenAccount;
    mapping(address => uint8) authorizedCaller;
     
     
    mapping (address => uint) public userInitialLockinPeriod;

     
    mapping (address => uint) public userFinalLockinPeriod;
     
    mapping (address => uint) public finalYearDebitAmount;
    
    bool public kycEnabled = true;
    uint public capWithdrawPercent = 25;  
     

    KYCVerification public kycVerification;

    event KYCMandateUpdate(bool _kycEnabled);
    event KYCContractAddressUpdate(KYCVerification _kycAddress);
    event LockinPeriodUpdated(address _guy,uint _userInitialLockinPeriod, uint _userFinalalLockinPeriod);
     
    event LockinCapWithdrawPercentUpdated(address _guy, uint _percent);
    event CapWithdrawDebitAmount(address _guy, uint256 value);


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

     
    event FrozenFunds(address target, bool frozen);
    
     
    event AuthorizedCaller(address caller);
    event DeAuthorizedCaller(address caller);

     
    constructor() public {
        owner = msg.sender;
        balances[0xBcd5B67aaeBb9765beE438e4Ce137B9aE2181898] = totalSupply;
        
        emit Transfer(address(0x0), address(this), totalSupply);
        emit Transfer(address(this), address(0xBcd5B67aaeBb9765beE438e4Ce137B9aE2181898), totalSupply);
            
        authorizedCaller[msg.sender] = 1;
        emit AuthorizedCaller(msg.sender);
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
    
    function () payable public {
        revert();
    }
    

     
    function _transfer(address _from, address _to, uint _value) internal returns(bool) {
        require (_to != 0x0);                                
        
        if(msg.sender != owner)
        {
            require (userInitialLockinPeriod[_from] < now);   
         
            if(userInitialLockinPeriod[_from] < now && userFinalLockinPeriod[_from] > now)
            {
                uint _allowWithdrawAmt = balances[_from].mul(capWithdrawPercent).div(100);
                
                finalYearDebitAmount[_from] = finalYearDebitAmount[_from].add(_value);
                
                if(finalYearDebitAmount[_from] <= _allowWithdrawAmt)
                {
                    require (balances[_from] > _value);                 
                    require (balances[_to].add(_value) > balances[_to]);  
                    balances[_from] = balances[_from].sub(_value);                          
                    balances[_to] = balances[_to].add(_value);                            
                    emit Transfer(_from, _to, _value);   
                    
                    emit CapWithdrawDebitAmount(_from,finalYearDebitAmount[_from]);  
                    return true;        
                }
                revert();
            }
            
        }
        
        
        require (balances[_from] > _value);                 
        require (balances[_to].add(_value) > balances[_to]);  
        balances[_from] = balances[_from].sub(_value);                          
        balances[_to] = balances[_to].add(_value);                            
        emit Transfer(_from, _to, _value); 
        
        return true;
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


    function purchaseToken(address _receiver, uint _tokens, uint _userInitialLockinPeriod, uint _userFinalalLockinPeriod) onlyAuthCaller public {
        require(_tokens > 0);
        require(initialSupply > _tokens);
        
         
         
        
        initialSupply = initialSupply.sub(_tokens);
        _transfer(owner, _receiver, _tokens);               
        externalAuthorizePurchase = externalAuthorizePurchase.add(_tokens);
        
          
        if(_userInitialLockinPeriod != 0 && _userFinalalLockinPeriod != 0)
        {
            userInitialLockinPeriod[_receiver] = _userInitialLockinPeriod;  
            userFinalLockinPeriod[_receiver] = _userFinalalLockinPeriod;   

            emit LockinPeriodUpdated(_receiver,_userInitialLockinPeriod,_userFinalalLockinPeriod);
        }
    }

     
    function transfer(address _to, uint256 _value) public kycVerified(msg.sender) frozenVerified(msg.sender)  returns (bool) {
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
    
    
      
    function updateLockinCapPercent(uint _percent) onlyAuthCaller public returns(bool)
    {
        capWithdrawPercent = _percent;

        emit LockinCapWithdrawPercentUpdated(msg.sender,_percent);

        return true;
    }  
    
    
     
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
    
}