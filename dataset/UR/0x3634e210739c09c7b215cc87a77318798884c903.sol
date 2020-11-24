 

pragma solidity ^0.5.11;

 

 
 
library SafeMath{
    
   
  
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

 

library Arrays{
    
  function arr(address _a) internal pure returns (address[] memory _arr) {
    _arr = new address[](1);
    _arr[0] = _a; 
  }

  function arr(address _a, address _b) internal pure returns (address[] memory _arr) {
    _arr = new address[](2);
    _arr[0] = _a; 
    _arr[1] = _b;
  }

  function arr(address _a, address _b, address _c) internal pure returns (address[] memory _arr) {
    _arr = new address[](3);
    _arr[0] = _a; 
    _arr[1] = _b; 
    _arr[2] = _c; 
  }

}

 

contract Ownable{
    
     
    
    address public hotOwner = 0xCd39203A332Ff477a35dA3AD2AD7761cDBEAb7F0;

    address public coldOwner = 0x1Ba688e70bb4F3CB266b8D721b5597bFbCCFF957;
    
     
    
    event OwnershipTransferred(address indexed _newHotOwner, address indexed _newColdOwner, address indexed _oldColdOwner);

    
   
    modifier onlyHotOwner() {
        require(msg.sender == hotOwner);
        _;
    }
    
    
    
    modifier onlyColdOwner() {
        require(msg.sender == coldOwner);
        _;
    }
    
    
    
    function transferOwnership(address _newHotOwner, address _newColdOwner) public onlyColdOwner {
        require(_newHotOwner != address(0));
        require(_newColdOwner!= address(0));
        hotOwner = _newHotOwner;
        coldOwner = _newColdOwner;
        emit OwnershipTransferred(_newHotOwner, _newColdOwner, msg.sender);
    }

}

 

contract EmergencyToggle is Ownable{
     
     
    bool public emergencyFlag; 

     
    constructor () public{
      emergencyFlag = false;                            
    }
  
     
    
    function emergencyToggle() external onlyHotOwner {
      emergencyFlag = !emergencyFlag;
    }

}

 

contract Authorizable is Ownable, EmergencyToggle {
    using SafeMath for uint256;
      
     
    mapping(address => bool) authorized;

     
    event AuthorityAdded(address indexed _toAdd);
    event AuthorityRemoved(address indexed _toRemove);
    
     
    modifier onlyAuthorized() {
        require(authorized[msg.sender] || hotOwner == msg.sender);
        _;
    }
    
    

    function addAuthorized(address _toAdd) public onlyHotOwner {
        require (!emergencyFlag);
        require(_toAdd != address(0));
        require(!authorized[_toAdd]);
        authorized[_toAdd] = true;
        emit AuthorityAdded(_toAdd);
    }
    
    

    function removeAuthorized(address _toRemove) public onlyHotOwner {
        require (!emergencyFlag);
        require(_toRemove != address(0));
        require(authorized[_toRemove]);
        authorized[_toRemove] = false;
        emit AuthorityRemoved(_toRemove);
    }
    
    
   
    function isAuthorized(address _authorized) external view returns(bool _isauthorized) {
        return authorized[_authorized];
    }
    
}

 
 
 contract Betalist is Authorizable {

     
    mapping(address => bool) betalisted;
    mapping(address => bool) blacklisted;

     
    event BetalistedAddress (address indexed _betalisted);
    event BlacklistedAddress (address indexed _blacklisted);
    event RemovedAddressFromBlacklist(address indexed _toRemoveBlacklist);
    event RemovedAddressFromBetalist(address indexed _toRemoveBetalist);

     
    bool public requireBetalisted;
 
     
    constructor () public {
        requireBetalisted = true;
    }
    
     
    
    modifier acceptableTransactors(address[] memory addresses) {
        require(!emergencyFlag);
        if (requireBetalisted){
          for(uint i = 0; i < addresses.length; i++) require( betalisted[addresses[i]] );
        }
        for(uint i = 0; i < addresses.length; i++) {
          address addr = addresses[i];
          require(addr != address(0));
          require(!blacklisted[addr]);
        }
        _;
    }
    
     
  
    function betalistAddress(address _toBetalist) public onlyAuthorized returns(bool) {
        require(!emergencyFlag);
        require(_toBetalist != address(0));
        require(!blacklisted[_toBetalist]);
        require(!betalisted[_toBetalist]);
        betalisted[_toBetalist] = true;
        emit BetalistedAddress(_toBetalist);
        return true;
    }
    
     
  
    function removeAddressFromBetalist(address _toRemoveBetalist) public onlyAuthorized {
        require(!emergencyFlag);
        require(_toRemoveBetalist != address(0));
        require(betalisted[_toRemoveBetalist]);
        betalisted[_toRemoveBetalist] = false;
        emit RemovedAddressFromBetalist(_toRemoveBetalist);
    }
    
     

    function blacklistAddress(address _toBlacklist) public onlyAuthorized returns(bool) {
        require(!emergencyFlag);
        require(_toBlacklist != address(0));
        require(!blacklisted[_toBlacklist]);
        blacklisted[_toBlacklist] = true;
        emit BlacklistedAddress(_toBlacklist);
        return true;
    }
        
     
  
    function removeAddressFromBlacklist(address _toRemoveBlacklist) public onlyAuthorized {
        require(!emergencyFlag);
        require(_toRemoveBlacklist != address(0));
        require(blacklisted[_toRemoveBlacklist]);
        blacklisted[_toRemoveBlacklist] = false;
        emit RemovedAddressFromBlacklist(_toRemoveBlacklist);
    }
        
     

    function batchBlacklistAddresses(address[] memory _toBlacklistAddresses) public onlyAuthorized returns(bool) {
        for(uint i = 0; i < _toBlacklistAddresses.length; i++) {
            bool check = blacklistAddress(_toBlacklistAddresses[i]);
            require(check);
        }
        return true;
    }
    
     

    function batchBetalistAddresses(address[] memory _toBetalistAddresses) public onlyAuthorized returns(bool) {
        for(uint i = 0; i < _toBetalistAddresses.length; i++) {
            bool check = betalistAddress(_toBetalistAddresses[i]);
            require(check);
        }
        return true;
    }
        
     
  
    function isBetalisted(address _betalisted) external view returns(bool) {
            return (betalisted[_betalisted]);
    }
    
     

    function isBlacklisted(address _blacklisted) external view returns(bool) {
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

 

contract StandardToken is Token, Betalist{
  using SafeMath for uint256;

     
    mapping (address => uint256)  balances;
    
    mapping (address => mapping (address => uint256)) allowed;
    
    uint256 public totalSupply;
    
     
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
  
    function allowance(address _owner,address _spender)public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     

    function transfer(address _to, uint256 _value) public acceptableTransactors(Arrays.arr(_to, msg.sender)) returns (bool) {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
  
     
    
    function approve(address _spender, uint256 _value) public acceptableTransactors(Arrays.arr(_spender, msg.sender)) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
  
     
    
    function transferFrom(address _from, address _to, uint256 _value) public acceptableTransactors(Arrays.arr(_from, _to, msg.sender)) returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

}

 

contract AuthorizeDeveloper is StandardToken{
    
     
    mapping(address => mapping(address => bool)) isAuthorizedDeveloper;
    
     
    event SilaAuthorizedDeveloper (address indexed _developer, address indexed _user);
    event DeveloperTransfer (address indexed _developer, address indexed _from, address indexed _to, uint _amount);
    event SilaRemovedDeveloper (address indexed _developer, address indexed _user);
    event UserAuthorizedDeveloper (address indexed _developer, address indexed _user);
    event UserRemovedDeveloper (address indexed _developer, address indexed _user);

    
    
    function silaAuthorizeDeveloper(address _developer, address _user) public acceptableTransactors(Arrays.arr(_developer, _user)) onlyAuthorized {
        require(!isAuthorizedDeveloper[_developer][_user]);
        isAuthorizedDeveloper[_developer][_user] = true;
        emit SilaAuthorizedDeveloper(_developer,_user);
    }
    
    
    
    function userAuthorizeDeveloper(address _developer) public acceptableTransactors(Arrays.arr(_developer, msg.sender)) {
        require(!isAuthorizedDeveloper[_developer][msg.sender]);
        isAuthorizedDeveloper[_developer][msg.sender] = true;
        emit UserAuthorizedDeveloper(_developer, msg.sender);
    }
    
    
    
    function silaRemoveDeveloper(address _developer, address _user) public onlyAuthorized {
        require(!emergencyFlag);
        require(_developer != address(0));
        require(_user != address(0));
        require(isAuthorizedDeveloper[_developer][_user]);
        isAuthorizedDeveloper[_developer][_user] = false;
        emit SilaRemovedDeveloper(_developer, _user);
    }
    
    
    
    function userRemoveDeveloper(address _developer) public {
        require(!emergencyFlag);
        require(_developer != address(0));
        require(isAuthorizedDeveloper[_developer][msg.sender]);
        isAuthorizedDeveloper[_developer][msg.sender] = false;
        emit UserRemovedDeveloper(_developer,msg.sender);
    }
    
    
    
    function developerTransfer(address _from, address _to, uint _amount) public acceptableTransactors(Arrays.arr(_from, _to, msg.sender)) {
        require(isAuthorizedDeveloper[msg.sender][_from]);
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit DeveloperTransfer(msg.sender, _from, _to, _amount);
        emit Transfer(_from, _to, _amount);
    }
    
    
    
    function checkIsAuthorizedDeveloper(address _developer, address _for) external view returns (bool) {
        return (isAuthorizedDeveloper[_developer][_for]);
    }

}

 

contract SilaUsd is AuthorizeDeveloper{
    using SafeMath for uint256;
    
     
    string  public constant name = "SILAUSD";
    string  public constant symbol = "SILA";
    uint256 public constant decimals = 18;
    string  public constant version = "2.0";
    
     
    event Issued(address indexed _to, uint256 _value);
    event Redeemed(address indexed _from, uint256 _amount);
    event ProtectedTransfer(address indexed _from, address indexed _to, uint256 _amount);
    event GlobalLaunchSila(address indexed _launcher);
    event DestroyedBlackFunds(address _blackListedUser, uint _dirtyFunds);

    

   function issue(address _to, uint256 _amount) public acceptableTransactors(Arrays.arr(_to)) onlyAuthorized returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);                 
        emit Issued(_to, _amount);                     
        return true;
    }
    
    

    function redeem(address _from, uint256 _amount) public acceptableTransactors(Arrays.arr(_from)) onlyAuthorized returns(bool) {
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);   
        totalSupply = totalSupply.sub(_amount);
        emit Redeemed(_from, _amount);
        return true;
    }
    
    

    function protectedTransfer(address _from, address _to, uint256 _amount) public acceptableTransactors(Arrays.arr(_from, _to)) onlyAuthorized returns(bool) {
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit ProtectedTransfer(_from, _to, _amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }    
    
     
    
    function destroyBlackFunds(address _blackListedUser) public onlyAuthorized {
        require(blacklisted[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        totalSupply = totalSupply.sub(dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
    
     
    
    function globalLaunchSila() public onlyHotOwner {
        require(!emergencyFlag);
        require(requireBetalisted);
        requireBetalisted = false;
        emit GlobalLaunchSila(msg.sender);
    }
    
     
    
    function batchIssue(address[] memory _toAddresses, uint256[]  memory _amounts) public onlyAuthorized returns(bool) {
        require(_toAddresses.length == _amounts.length);
        for(uint i = 0; i < _toAddresses.length; i++) {
            bool check = issue(_toAddresses[i],_amounts[i]);
            require(check);
        }
        return true;
    }
    
     
    
    function batchRedeem(address[] memory  _fromAddresses, uint256[]  memory _amounts) public onlyAuthorized returns(bool) {
        require(_fromAddresses.length == _amounts.length);
        for(uint i = 0; i < _fromAddresses.length; i++) {
            bool check = redeem(_fromAddresses[i],_amounts[i]);
            require(check);
        }  
        return true;
    }
    
     
    
    function protectedBatchTransfer(address[] memory _fromAddresses, address[]  memory _toAddresses, uint256[] memory  _amounts) public onlyAuthorized returns(bool) {
        require(_fromAddresses.length == _amounts.length);
        require(_toAddresses.length == _amounts.length);
        require(_fromAddresses.length == _toAddresses.length);
        for(uint i = 0; i < _fromAddresses.length; i++) {
            bool check = protectedTransfer(_fromAddresses[i], _toAddresses[i], _amounts[i]);
            require(check);
        }
        return true;
    } 
    
}