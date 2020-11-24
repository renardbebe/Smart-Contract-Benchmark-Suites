 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract LockinManager {
    using SafeMath for uint256;

     
    struct Lock {
        uint256 amount;
        uint256 unlockDate;
        uint256 lockedFor;
    }
    
         
    Lock lock;

     
    uint256 defaultAllowedLock = 7;

     
    mapping (address => Lock[]) public lockedAddresses;

     
    mapping (address => uint256) public allowedContracts;

     
    mapping (uint => uint256) public allowedLocks;

     
    Token token;

     
    AuthenticationManager authenticationManager;

      
    event LockedDayAdded(address _admin, uint256 _daysLocked, uint256 timestamp);

      
    event LockedDayRemoved(address _admin, uint256 _daysLocked, uint256 timestamp);

      
    event ValidContractAdded(address _admin, address _validAddress, uint256 timestamp);

      
    event ValidContractRemoved(address _admin, address _validAddress, uint256 timestamp);

     
    function LockinManager(address _token, address _authenticationManager) {
      
         
        token  = Token(_token);
        authenticationManager = AuthenticationManager(_authenticationManager);
    }
   
     
    modifier adminOnly {
        if (!authenticationManager.isCurrentAdmin(msg.sender)) throw;
        _;
    }

     
    modifier validContractOnly {
        require(allowedContracts[msg.sender] != 0);

        _;
    }

     
    function getLocks(address _owner) validContractOnly constant returns (uint256) {
        return lockedAddresses[_owner].length;
    }

    function getLock(address _owner, uint256 count) validContractOnly returns(uint256 amount, uint256 unlockDate, uint256 lockedFor) {
        amount     = lockedAddresses[_owner][count].amount;
        unlockDate = lockedAddresses[_owner][count].unlockDate;
        lockedFor  = lockedAddresses[_owner][count].lockedFor;
    }
    
     
    function getLocksAmount(address _owner, uint256 count) validContractOnly returns(uint256 amount) {        
        amount = lockedAddresses[_owner][count].amount;
    }

     
    function getLocksUnlockDate(address _owner, uint256 count) validContractOnly returns(uint256 unlockDate) {
        unlockDate = lockedAddresses[_owner][count].unlockDate;
    }

     
    function getLocksLockedFor(address _owner, uint256 count) validContractOnly returns(uint256 lockedFor) {
        lockedFor = lockedAddresses[_owner][count].lockedFor;
    }

     
    function defaultLockin(address _address, uint256 _value) validContractOnly
    {
        lockIt(_address, _value, defaultAllowedLock);
    }

     
    function lockForDays(uint256 _value, uint256 _days) 
    {
        require( ! ifInAllowedLocks(_days));        

        require(token.availableBalance(msg.sender) >= _value);
        
        lockIt(msg.sender, _value, _days);     
    }

    function lockIt(address _address, uint256 _value, uint256 _days) internal {
         
        uint256 _expiry = now + _days.mul(86400);
        lockedAddresses[_address].push(Lock(_value, _expiry, _days));        
    }

     
    function ifInAllowedLocks(uint256 _days) constant returns(bool) {
        return allowedLocks[_days] == 0;
    }

     
    function addAllowedLock(uint _day) adminOnly {

         
        if (allowedLocks[_day] != 0)
            throw;
        
         
        allowedLocks[_day] = now;
        LockedDayAdded(msg.sender, _day, now);
    }

     
    function removeAllowedLock(uint _day) adminOnly {

         
        if ( allowedLocks[_day] ==  0)
            throw;

         
        allowedLocks[_day] = 0;
        LockedDayRemoved(msg.sender, _day, now);
    }

     
    function addValidContract(address _address) adminOnly {

         
        if (allowedContracts[_address] != 0)
            throw;
        
         
        allowedContracts[_address] = now;

        ValidContractAdded(msg.sender, _address, now);
    }

     
    function removeValidContract(address _address) adminOnly {

         
        if ( allowedContracts[_address] ==  0)
            throw;

         
        allowedContracts[_address] = 0;

        ValidContractRemoved(msg.sender, _address, now);
    }

     
    function setDefaultAllowedLock(uint _days) adminOnly {
        defaultAllowedLock = _days;
    }
}

 
contract AuthenticationManager {
   
     
    mapping (address => bool) adminAddresses;

     
    mapping (address => bool) accountReaderAddresses;

     
    mapping (address => bool) accountMinterAddresses;

     
    address[] adminAudit;

     
    address[] accountReaderAudit;

     
    address[] accountMinterAudit;

     
    event AdminAdded(address addedBy, address admin);

     
    event AdminRemoved(address removedBy, address admin);

     
    event AccountReaderAdded(address addedBy, address account);

     
    event AccountReaderRemoved(address removedBy, address account);

     
    event AccountMinterAdded(address addedBy, address account);

     
    event AccountMinterRemoved(address removedBy, address account);

         
    function AuthenticationManager() {
         
        adminAddresses[msg.sender] = true;
        AdminAdded(0, msg.sender);
        adminAudit.length++;
        adminAudit[adminAudit.length - 1] = msg.sender;
    }

     
    function isCurrentAdmin(address _address) constant returns (bool) {
        return adminAddresses[_address];
    }

     
    function isCurrentOrPastAdmin(address _address) constant returns (bool) {
        for (uint256 i = 0; i < adminAudit.length; i++)
            if (adminAudit[i] == _address)
                return true;
        return false;
    }

     
    function isCurrentAccountReader(address _address) constant returns (bool) {
        return accountReaderAddresses[_address];
    }

     
    function isCurrentOrPastAccountReader(address _address) constant returns (bool) {
        for (uint256 i = 0; i < accountReaderAudit.length; i++)
            if (accountReaderAudit[i] == _address)
                return true;
        return false;
    }

     
    function isCurrentAccountMinter(address _address) constant returns (bool) {
        return accountMinterAddresses[_address];
    }

     
    function isCurrentOrPastAccountMinter(address _address) constant returns (bool) {
        for (uint256 i = 0; i < accountMinterAudit.length; i++)
            if (accountMinterAudit[i] == _address)
                return true;
        return false;
    }

     
    function addAdmin(address _address) {
         
        if (!isCurrentAdmin(msg.sender))
            throw;

         
        if (adminAddresses[_address])
            throw;
        
         
        adminAddresses[_address] = true;
        AdminAdded(msg.sender, _address);
        adminAudit.length++;
        adminAudit[adminAudit.length - 1] = _address;

    }

     
    function removeAdmin(address _address) {
         
        if (!isCurrentAdmin(msg.sender))
            throw;

         
        if (_address == msg.sender)
            throw;

         
        if (!adminAddresses[_address])
            throw;

         
        adminAddresses[_address] = false;
        AdminRemoved(msg.sender, _address);
    }

     
    function addAccountReader(address _address) {
         
        if (!isCurrentAdmin(msg.sender))
            throw;

         
        if (accountReaderAddresses[_address])
            throw;
        
         
        accountReaderAddresses[_address] = true;
        AccountReaderAdded(msg.sender, _address);
        accountReaderAudit.length++;
        accountReaderAudit[accountReaderAudit.length - 1] = _address;
    }

     
    function removeAccountReader(address _address) {
         
        if (!isCurrentAdmin(msg.sender))
            throw;

         
        if (!accountReaderAddresses[_address])
            throw;

         
        accountReaderAddresses[_address] = false;
        AccountReaderRemoved(msg.sender, _address);
    }

     
    function addAccountMinter(address _address) {
         
        if (!isCurrentAdmin(msg.sender))
            throw;

         
        if (accountMinterAddresses[_address])
            throw;
        
         
        accountMinterAddresses[_address] = true;
        AccountMinterAdded(msg.sender, _address);
        accountMinterAudit.length++;
        accountMinterAudit[accountMinterAudit.length - 1] = _address;
    }

     
    function removeAccountMinter(address _address) {
         
        if (!isCurrentAdmin(msg.sender))
            throw;

         
        if (!accountMinterAddresses[_address])
            throw;

         
        accountMinterAddresses[_address] = false;
        AccountMinterRemoved(msg.sender, _address);
    }
}

 
contract Token {
    using SafeMath for uint256;

     
    mapping (address => uint256) public balances;

     
    mapping(address => mapping (address => uint256)) allowed;

     
    address[] allTokenHolders;

     
    string public name;

     
    string public symbol;

     
    uint8 public decimals;

     
    uint256 totalSupplyAmount = 0;
    
     
    address public refundManagerContractAddress;

     
    AuthenticationManager authenticationManager;

     
    LockinManager lockinManager;

     
    function availableBalance(address _owner) constant returns(uint256) {
        
        uint256 length =  lockinManager.getLocks(_owner);
    
        uint256 lockedValue = 0;
        
        for(uint256 i = 0; i < length; i++) {

            if(lockinManager.getLocksUnlockDate(_owner, i) > now) {
                uint256 _value = lockinManager.getLocksAmount(_owner, i);    
                lockedValue = lockedValue.add(_value);                
            }
        }
        
        return balances[_owner].sub(lockedValue);
    }

     
    event FundClosed();
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function Token(address _authenticationManagerAddress) {
         
        name = "PIE (Authorito Capital)";
        symbol = "PIE";
        decimals = 18;

         
        authenticationManager = AuthenticationManager(_authenticationManagerAddress);        
    }

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

     
    modifier accountReaderOnly {
        if (!authenticationManager.isCurrentAccountReader(msg.sender)) throw;
        _;
    }

     
    modifier adminOnly {
        if (!authenticationManager.isCurrentAdmin(msg.sender)) throw;
        _;
    }   
    
    function setLockinManagerAddress(address _lockinManager) adminOnly {
        lockinManager = LockinManager(_lockinManager);
    }

    function setRefundManagerContract(address _refundManagerContractAddress) adminOnly {
        refundManagerContractAddress = _refundManagerContractAddress;
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3) returns (bool) {
        
        if (availableBalance(_from) >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to].add(_amount) > balances[_to]) {
            bool isNew = balances[_to] == 0;
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            if (isNew)
                tokenOwnerAdd(_to);
            if (balances[_from] == 0)
                tokenOwnerRemove(_from);
            Transfer(_from, _to, _amount);
            return true;
        }
        return false;
    }

     
    function tokenHolderCount() accountReaderOnly constant returns (uint256) {
        return allTokenHolders.length;
    }

     
    function tokenHolder(uint256 _index) accountReaderOnly constant returns (address) {
        return allTokenHolders[_index];
    }
 
     
    function approve(address _spender, uint256 _amount) onlyPayloadSize(2) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function totalSupply() constant returns (uint256) {
        return totalSupplyAmount;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2) returns (bool) {
                
         
        if (availableBalance(msg.sender) < _amount || balances[_to].add(_amount) < balances[_to])
            return false;

         
        bool isRecipientNew = balances[_to] == 0;

         
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        
         
        if (isRecipientNew)
            tokenOwnerAdd(_to);
        if (balances[msg.sender] <= 0)
            tokenOwnerRemove(msg.sender);

         
        Transfer(msg.sender, _to, _amount);
        return true; 
    }

     
    function tokenOwnerAdd(address _addr) internal {
         
        uint256 tokenHolderCount = allTokenHolders.length;
        for (uint256 i = 0; i < tokenHolderCount; i++)
            if (allTokenHolders[i] == _addr)
                 
                return;
        
         
        allTokenHolders.length++;
        allTokenHolders[allTokenHolders.length - 1] = _addr;
    }

     
    function tokenOwnerRemove(address _addr) internal {
         
        uint256 tokenHolderCount = allTokenHolders.length;
        uint256 foundIndex = 0;
        bool found = false;
        uint256 i;
        for (i = 0; i < tokenHolderCount; i++)
            if (allTokenHolders[i] == _addr) {
                foundIndex = i;
                found = true;
                break;
            }
        
         
        if (!found)
            return;
        
         
        for (i = foundIndex; i < tokenHolderCount - 1; i++)
            allTokenHolders[i] = allTokenHolders[i + 1];
        allTokenHolders.length--;
    }

     
    function mintTokens(address _address, uint256 _amount) onlyPayloadSize(2) {

         
        if ( ! authenticationManager.isCurrentAccountMinter(msg.sender))
            throw;

         
        bool isNew = balances[_address] == 0;
        totalSupplyAmount = totalSupplyAmount.add(_amount);
        balances[_address] = balances[_address].add(_amount);

        lockinManager.defaultLockin(_address, _amount);        

        if (isNew)
            tokenOwnerAdd(_address);
        Transfer(0, _address, _amount);
    }

     
    function destroyTokens(address _investor, uint256 tokenCount) returns (bool) {
        
         
        if ( refundManagerContractAddress  == 0x0 || msg.sender != refundManagerContractAddress)
            throw;

        uint256 balance = availableBalance(_investor);

        if (balance < tokenCount) {
            return false;
        }

        balances[_investor] -= tokenCount;
        totalSupplyAmount -= tokenCount;

        if(balances[_investor] <= 0)
            tokenOwnerRemove(_investor);

        return true;
    }
}