 

pragma solidity ^0.5.2;


 

 
 
library SafeMath{
    
    
   
  
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    
     
     

    
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

 
    
 
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    
    require(_b > 0);  
    uint256 c = _a / _b;
    
         

    return c;
  }
  
  
 
    
  
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }


   
  
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

    
}

 

contract Ownable {
    
     
    
    address public hotOwner=0xCd39203A332Ff477a35dA3AD2AD7761cDBEAb7F0;

    address public coldOwner=0x1Ba688e70bb4F3CB266b8D721b5597bFbCCFF957;
    
    
     
    
    event OwnershipTransferred(address indexed _newHotOwner,address indexed _newColdOwner,address indexed _oldColdOwner);


     
   
    modifier onlyHotOwner() {
        require(msg.sender == hotOwner);
        _;
    }
    
      
    
    modifier onlyColdOwner() {
        require(msg.sender == coldOwner);
        _;
    }
    
      
    
    function transferOwnership(address _newHotOwner,address _newColdOwner) public onlyColdOwner returns (bool) {
        require(_newHotOwner != address(0));
        require(_newColdOwner!= address(0));
        hotOwner = _newHotOwner;
        coldOwner = _newColdOwner;
        emit OwnershipTransferred(_newHotOwner,_newColdOwner,msg.sender);
        return true;
        
        
    }

}

 

contract Authorizable is Ownable {
    
     
    mapping(address => bool) authorized;
    
     
    event AuthorityAdded(address indexed _toAdd);
    event AuthorityRemoved(address indexed _toRemove);
    
     
    address[] public authorizedAddresses;

    
    modifier onlyAuthorized() {
        require(authorized[msg.sender] || hotOwner == msg.sender);
        _;
    }
    
    
     
      

    function addAuthorized(address _toAdd) onlyHotOwner public returns(bool) {
        require(_toAdd != address(0));
        require(!authorized[_toAdd]);
        authorized[_toAdd] = true;
        authorizedAddresses.push(_toAdd);
        emit AuthorityAdded(_toAdd);
        return true;
    }
    
     

    function removeAuthorized(address _toRemove,uint _toRemoveIndex) onlyHotOwner public returns(bool) {
        require(_toRemove != address(0));
        require(authorized[_toRemove]);
        authorized[_toRemove] = false;
        authorizedAddresses[_toRemoveIndex] = authorizedAddresses[authorizedAddresses.length-1];
        authorizedAddresses.pop();
        emit AuthorityRemoved(_toRemove);
        return true;
    }
    
    
     
    function viewAuthorized() external view returns(address[] memory _authorizedAddresses){
        return authorizedAddresses;
    }
    
    
     
    
    function isAuthorized(address _authorized) external view returns(bool _isauthorized){
        return authorized[_authorized];
    }
    
    
  

}




 

contract EmergencyToggle is Ownable{
     
     
    bool public emergencyFlag; 

     
    constructor () public{
      emergencyFlag = false;                            
      
    }
  
  
    
    
    function emergencyToggle() external onlyHotOwner{
      emergencyFlag = !emergencyFlag;
    }

    
 
 }
 
  
 contract Betalist is Authorizable,EmergencyToggle{
     
     
    mapping(address=>bool) betalisted;
    mapping(address=>bool) blacklisted;

     
    event BetalistedAddress (address indexed _betalisted);
    event BlacklistedAddress (address indexed _blacklisted);
    event RemovedFromBlacklist(address indexed _toRemoveBlacklist);
    event RemovedFromBetalist(address indexed _toRemoveBetalist);
    
     
    bool public requireBetalisted;


     
    constructor () public{
        requireBetalisted=true;
        
    }
    
    
    
    function betalistAddress(address _toBetalist) public onlyAuthorized returns(bool){
        require(!emergencyFlag);
        require(_toBetalist != address(0));
        require(!blacklisted[_toBetalist]);
        require(!betalisted[_toBetalist]);
        betalisted[_toBetalist]=true;
        emit BetalistedAddress(_toBetalist);
        return true;
        
    }
    
      
    function removeAddressFromBetalist(address _toRemoveBetalist) public onlyAuthorized returns(bool){
        require(!emergencyFlag);
        require(_toRemoveBetalist != address(0));
        require(betalisted[_toRemoveBetalist]);
        betalisted[_toRemoveBetalist]=false;
        emit RemovedFromBetalist(_toRemoveBetalist);
        return true;
        
    }
    
      
     
    function blacklistAddress(address _toBlacklist) public onlyAuthorized returns(bool){
        require(!emergencyFlag);
        require(_toBlacklist != address(0));
        require(!blacklisted[_toBlacklist]);
        blacklisted[_toBlacklist]=true;
        emit RemovedFromBlacklist(_toBlacklist);
        return true;
        
    }
    
      
    function removeAddressFromBlacklist(address _toRemoveBlacklist) public onlyAuthorized returns(bool){
        require(!emergencyFlag);
        require(_toRemoveBlacklist != address(0));
        require(blacklisted[_toRemoveBlacklist]);
        blacklisted[_toRemoveBlacklist]=false;
        emit RemovedFromBlacklist(_toRemoveBlacklist);
        return true;
        
    }
 
       
    function isBetaListed(address _betalisted) external view returns(bool){
            return (betalisted[_betalisted]);
    }
    
     
       
    function isBlackListed(address _blacklisted) external view returns(bool){
        return (blacklisted[_blacklisted]);
        
    }
    
    
}

 

contract Token{
    
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 

contract StandardToken is Token,Betalist{
  using SafeMath for uint256;

  mapping (address => uint256)  balances;

  mapping (address => mapping (address => uint256)) allowed;
  
  uint256 public totalSupply;


 
  
  
   

  function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
  }

  
  
   
  
  function allowance(address _owner,address _spender)public view returns (uint256){
        return allowed[_owner][_spender];
  }

 
   
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(!emergencyFlag);
    require(_value <= balances[msg.sender]);
    require(_to != address(0));
    if (requireBetalisted){
        require(betalisted[_to]);
        require(betalisted[msg.sender]);
    }
    require(!blacklisted[msg.sender]);
    require(!blacklisted[_to]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;

  }
  
  
     

  function approve(address _spender, uint256 _value) public returns (bool) {
    require(!emergencyFlag);
    if (requireBetalisted){
        require(betalisted[msg.sender]);
        require(betalisted[_spender]);
    }
    require(!blacklisted[msg.sender]);
    require(!blacklisted[_spender]);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;

  }
  
  
     

  function transferFrom(address _from,address _to,uint256 _value)public returns (bool){
    require(!emergencyFlag);
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));
    if (requireBetalisted){
        require(betalisted[_to]);
        require(betalisted[_from]);
        require(betalisted[msg.sender]);
    }
    require(!blacklisted[_to]);
    require(!blacklisted[_from]);
    require(!blacklisted[msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
    
  }

}

contract AssignOperator is StandardToken{
    
     
    
    mapping(address=>mapping(address=>bool)) isOperator;
    
    
     
    event AssignedOperator (address indexed _operator,address indexed _for);
    event OperatorTransfer (address indexed _developer,address indexed _from,address indexed _to,uint _amount);
    event RemovedOperator  (address indexed _operator,address indexed _for);
    
    
     
    
    function assignOperator(address _developer,address _user) public onlyAuthorized returns(bool){
        require(!emergencyFlag);
        require(_developer != address(0));
        require(_user != address(0));
        require(!isOperator[_developer][_user]);
        if(requireBetalisted){
            require(betalisted[_user]);
            require(betalisted[_developer]);
        }
        require(!blacklisted[_developer]);
        require(!blacklisted[_user]);
        isOperator[_developer][_user]=true;
        emit AssignedOperator(_developer,_user);
        return true;
    }
    
     
    function removeOperator(address _developer,address _user) public onlyAuthorized returns(bool){
        require(!emergencyFlag);
        require(_developer != address(0));
        require(_user != address(0));
        require(isOperator[_developer][_user]);
        isOperator[_developer][_user]=false;
        emit RemovedOperator(_developer,_user);
        return true;
        
    }
    
     
    
    function operatorTransfer(address _from,address _to,uint _amount) public returns (bool){
        require(!emergencyFlag);
        require(isOperator[msg.sender][_from]);
        require(_amount <= balances[_from]);
        require(_from != address(0));
        require(_to != address(0));
        if (requireBetalisted){
            require(betalisted[_to]);
            require(betalisted[_from]);
            require(betalisted[msg.sender]);
        }
        require(!blacklisted[_to]);
        require(!blacklisted[_from]);
        require(!blacklisted[msg.sender]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit OperatorTransfer(msg.sender,_from, _to, _amount);
        emit Transfer(_from,_to,_amount);
        return true;
        
        
    }
    
      
    
    function checkIsOperator(address _developer,address _for) external view returns (bool){
            return (isOperator[_developer][_for]);
    }

    
}



  

contract SilaToken is AssignOperator{
    using SafeMath for uint256;
    
     
    string  public constant name = "SilaToken";
    string  public constant symbol = "SILA";
    uint256 public constant decimals = 18;
    string  public version = "1.0";
    
     
     
    event Issued(address indexed _to,uint256 _value);
    event Redeemed(address indexed _from,uint256 _amount);
    event ProtectedTransfer(address indexed _from,address indexed _to,uint256 _amount);
    event ProtectedApproval(address indexed _owner,address indexed _spender,uint256 _amount);
    event GlobalLaunchSila(address indexed _launcher);
    
    

     

    function issue(address _to, uint256 _amount) public onlyAuthorized returns (bool) {
        require(!emergencyFlag);
        require(_to !=address(0));
        if (requireBetalisted){
            require(betalisted[_to]);
        }
        require(!blacklisted[_to]);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);                 
        emit Issued(_to, _amount);                     
        return true;
    }
    
    
      
    

    function redeem(address _from,uint256 _amount) public onlyAuthorized returns(bool){
        require(!emergencyFlag);
        require(_from != address(0));
        require(_amount <= balances[_from]);
        if(requireBetalisted){
            require(betalisted[_from]);
        }
        require(!blacklisted[_from]);
        balances[_from] = balances[_from].sub(_amount);   
        totalSupply = totalSupply.sub(_amount);
        emit Redeemed(_from,_amount);
        return true;
            

    }
    
    
     

    function protectedTransfer(address _from,address _to,uint256 _amount) public onlyAuthorized returns(bool){
        require(!emergencyFlag);
        require(_amount <= balances[_from]);
        require(_from != address(0));
        require(_to != address(0));
        if (requireBetalisted){
            require(betalisted[_to]);
            require(betalisted[_from]);
        }
        require(!blacklisted[_to]);
        require(!blacklisted[_from]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit ProtectedTransfer(_from, _to, _amount);
        emit Transfer(_from,_to,_amount);
        return true;
        
    }
    
    
     
    
    function globalLaunchSila() public onlyHotOwner{
            require(!emergencyFlag);
            require(requireBetalisted);
            requireBetalisted=false;
            emit GlobalLaunchSila(msg.sender);
    }
    
    
    
      
    
    function batchIssue(address[] memory _toAddresses,uint256[]  memory _amounts) public onlyAuthorized returns(bool) {
            require(!emergencyFlag);
            require(_toAddresses.length==_amounts.length);
            for(uint i = 0; i < _toAddresses.length; i++) {
                bool check=issue(_toAddresses[i],_amounts[i]);
                require(check);
            }
            return true;
            
    }
    
    
     
    
    function batchRedeem(address[] memory  _fromAddresses,uint256[]  memory _amounts) public onlyAuthorized returns(bool){
            require(!emergencyFlag);
            require(_fromAddresses.length==_amounts.length);
            for(uint i = 0; i < _fromAddresses.length; i++) {
                bool check=redeem(_fromAddresses[i],_amounts[i]);
                require(check);
            }  
            return true;
        
    }
    
    
       
    function protectedBatchTransfer(address[] memory _fromAddresses,address[]  memory _toAddresses,uint256[] memory  _amounts) public onlyAuthorized returns(bool){
            require(!emergencyFlag);
            require(_fromAddresses.length==_amounts.length);
            require(_toAddresses.length==_amounts.length);
            require(_fromAddresses.length==_toAddresses.length);
            for(uint i = 0; i < _fromAddresses.length; i++) {
                bool check=protectedTransfer(_fromAddresses[i],_toAddresses[i],_amounts[i]);
                require(check);
               
            }
            return true;
        
    } 
    
    
    

    
    
}