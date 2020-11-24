 

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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract ST20EToken is Owned, BurnableToken {

    string public name = "SUREBANQA ENTERPRISE e-SHARE";
    string public symbol = "ST20E";
    uint8 public decimals = 2;
    
    uint256 public initialSupply = 1000000 * (10 ** uint256(decimals));
    uint256 public totalSupply = 1000000 * (10 ** uint256(decimals));
    uint256 public externalAuthorizePurchase = 0;

    
     
    mapping (address => uint) public userLockinPeriod;

     
    mapping (address => uint) public userLockinPeriodType;

    mapping (address => bool) public frozenAccount;
    mapping(address => uint8) authorizedCaller;
    
    bool public kycEnabled = true;
    bool public authorizedTransferOnly = true;  
    
    
    mapping(address => mapping(bytes32 => bool)) private transferRequestStatus;
    
    struct fundReceiver{
        address _to;
        uint _value;
    }
    
    mapping(address => mapping(bytes32 => fundReceiver)) private transferRequestReceiver;

    KYCVerification public kycVerification;

    event KYCMandateUpdate(bool _kycEnabled);
    event KYCContractAddressUpdate(KYCVerification _kycAddress);

     
    event FrozenFunds(address target, bool frozen);
    
     
    event AuthorizedCaller(address caller);
    event DeAuthorizedCaller(address caller);

    event LockinPeriodUpdated(address _guy,uint _userLockinPeriodType, uint _userLockinPeriod);
    
    event TransferAuthorizationOverride(bool _authorize);
    event TransferRequested(address _from, address _to, uint _value,bytes32 _signature);
    event TransferRequestFulfilled(address _from, address _to, uint _value,bytes32 _signature);
    
    
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
    
    modifier transferAuthorized(address _guy) {
        
        if(authorizedTransferOnly == true)
        {
            if(authorizedCaller[msg.sender] == 0 || msg.sender != owner)
            {
                revert();
            }
        }
        _;
    }


     
    constructor() public {
        owner = msg.sender;
        balances[0xBcd5B67aaeBb9765beE438e4Ce137B9aE2181898] = totalSupply;
        
        authorizedCaller[msg.sender] = 1;
        emit AuthorizedCaller(msg.sender);
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

    function overrideUserLockinPeriod(address _guy,uint _userLockinPeriodType, uint _userLockinPeriod) public onlyAuthCaller
    {
        userLockinPeriodType[_guy] = _userLockinPeriodType;
        userLockinPeriod[_guy] = _userLockinPeriod;

        emit LockinPeriodUpdated(_guy,_userLockinPeriodType, _userLockinPeriod);
    }
    
    function overrideTransferAuthorization(bool _authorize) public onlyAuthCaller
    {
        authorizedTransferOnly = _authorize;
        emit TransferAuthorizationOverride(_authorize);
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
    

     
    function _transfer(address _from, address _to, uint _value) internal transferAuthorized(msg.sender) {
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


    function purchaseToken(address _receiver, uint _tokens, uint _userLockinPeriod, uint _userLockinPeriodType) onlyAuthCaller public  {
        require(_tokens > 0);
        require(initialSupply > _tokens);
        
        initialSupply = initialSupply.sub(_tokens);
        _transfer(owner, _receiver, _tokens);               
        externalAuthorizePurchase = externalAuthorizePurchase.add(_tokens);

         
        if(_userLockinPeriod != 0 && _userLockinPeriodType != 0)
        {
            userLockinPeriod[_receiver] = _userLockinPeriod;
            userLockinPeriodType[_receiver] = _userLockinPeriodType;

            emit LockinPeriodUpdated(_receiver,_userLockinPeriodType, _userLockinPeriod);
        }
    }

     
    function transfer(address _to, uint256 _value) public kycVerified(msg.sender) frozenVerified(msg.sender) returns (bool) {

         
        if(kycEnabled == true){
             
            if(kycVerification.isVerified(_to) == false)
            {
                revert("KYC Not Verified for Receiver");
            }
        }

        _transfer(msg.sender,_to,_value);
        return true;
    }
    
     
    function multiTransfer(address[] _to,uint[] _value) public kycVerified(msg.sender) frozenVerified(msg.sender) returns (bool) {
        require(_to.length == _value.length, "Length of Destination should be equal to value");
        require(_to.length <= 25, "Max 25 Senders allowed" );        

        for(uint _interator = 0;_interator < _to.length; _interator++ )
        {
             
            if(kycEnabled == true){
                 
                if(kycVerification.isVerified(_to[_interator]) == false)
                {
                    revert("KYC Not Verified for Receiver");
                }
            }
        }


        for(_interator = 0;_interator < _to.length; _interator++ )
        {
            _transfer(msg.sender,_to[_interator],_value[_interator]);
        }
        
        return true;    
    }
    
    function requestTransfer(address _to, uint _value, bytes32 _signature) public returns(bool)
    {
        require(transferRequestStatus[msg.sender][_signature] == false,"Signature already processed");
        require (balances[msg.sender] > _value,"Insufficient Sender Balance");
        
        transferRequestReceiver[msg.sender][_signature] = fundReceiver(_to,_value);
        
        emit TransferRequested(msg.sender, _to, _value,_signature);
        
        return true;
    }

    function batchRequestTransfer(address[] _to, uint[] _value, bytes32[] _signature) public returns(bool)
    {
        require(_to.length == _value.length ,"Length for to, value should be equal");
        require(_to.length == _signature.length ,"Length for to, signature should be equal");
        

        for(uint _interator = 0; _interator < _to.length ; _interator++)
        {
            require(transferRequestStatus[msg.sender][_signature[_interator]] == false,"Signature already processed");
            
            transferRequestReceiver[msg.sender][_signature[_interator]] = fundReceiver(_to[_interator],_value[_interator]);
            
            emit TransferRequested(msg.sender, _to[_interator], _value[_interator],_signature[_interator]);
        }

        
        
        return true;
    }
    
    function fullTransferRequest(address _from, bytes32 _signature) public onlyAuthCaller returns(bool) 
    {
        require(transferRequestStatus[_from][_signature] == false);
        
        fundReceiver memory _tmpHolder = transferRequestReceiver[_from][_signature];

        _transfer(_from,_tmpHolder._to,_tmpHolder._value);
        
        transferRequestStatus[_from][_signature] == true;
        
        emit TransferRequestFulfilled(_from, _tmpHolder._to, _tmpHolder._value,_signature);
        
        return true;
    }

    function batchFullTransferRequest(address[] _from, bytes32[] _signature) public onlyAuthCaller returns(bool) 
    {

         
        for(uint _interator = 0; _interator < _from.length ; _interator++)
        {
            require(transferRequestStatus[_from[_interator]][_signature[_interator]] == false);
            
            fundReceiver memory _tmpHolder = transferRequestReceiver[_from[_interator]][_signature[_interator]];
        
             
            require (_tmpHolder._value < balances[_from[_interator]],"Insufficient Sender Balance");
            
            _transfer(_from[_interator],_tmpHolder._to,_tmpHolder._value);
            
            transferRequestStatus[_from[_interator]][_signature[_interator]] == true;
            
            emit TransferRequestFulfilled(_from[_interator], _tmpHolder._to, _tmpHolder._value,_signature[_interator]);
        }
        
        
        return true;
    }
    
    function getTransferRequestStatus(address _from, bytes32 _signature) public view returns(bool _status)
    {
        return  transferRequestStatus[_from][_signature];
        
    }
    
    function getTransferRequestReceiver(address _from, bytes32 _signature) public view returns(address _to, uint _value)
    {
        fundReceiver memory _tmpHolder = transferRequestReceiver[_from][_signature];
        
        return (_tmpHolder._to, _tmpHolder._value);
    }
}