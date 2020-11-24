 

pragma solidity ^0.4.11;

 
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

 
contract TokenValueRelayer {

     
    struct TokenValueRepresentation {
        uint256 value;
        string currency;
        uint256 timestamp;
    }

     
    TokenValueRepresentation[] public values;
    
     
    AuthenticationManager authenticationManager;

     
    event TokenValue(uint256 value, string currency, uint256 timestamp);

     
    modifier adminOnly {
        if (!authenticationManager.isCurrentAdmin(msg.sender)) throw;
        _;
    }

     
    function TokenValueRelayer(address _authenticationManagerAddress) {
         
        authenticationManager = AuthenticationManager(_authenticationManagerAddress);
    }

     
    function tokenValueCount() constant returns (uint256 _count) {
        _count = values.length;
    }

     
    function tokenValuePublish(uint256 _value, string _currency, uint256 _timestamp) adminOnly {
        values.length++;
        values[values.length - 1] = TokenValueRepresentation(_value, _currency,_timestamp);

         
        TokenValue(_value, _currency, _timestamp);
    }
}