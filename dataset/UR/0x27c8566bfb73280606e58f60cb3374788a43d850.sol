 

pragma solidity ^0.4.11;

 
contract AuthenticationManager {
     
    mapping (address => bool) adminAddresses;

     
    mapping (address => bool) accountReaderAddresses;

     
    address[] adminAudit;

     
    address[] accountReaderAudit;

     
    event AdminAdded(address addedBy, address admin);

     
    event AdminRemoved(address removedBy, address admin);

     
    event AccountReaderAdded(address addedBy, address account);

     
    event AccountReaderRemoved(address removedBy, address account);

         
    function AuthenticationManager() {
         
        adminAddresses[msg.sender] = true;
        AdminAdded(0, msg.sender);
        adminAudit.length++;
        adminAudit[adminAudit.length - 1] = msg.sender;
    }

     
    function contractVersion() constant returns(uint256) {
         
        return 100201707171503;
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
        accountReaderAudit[adminAudit.length - 1] = _address;
    }

     
    function removeAccountReader(address _address) {
         
        if (!isCurrentAdmin(msg.sender))
            throw;

         
        if (!accountReaderAddresses[_address])
            throw;

         
        accountReaderAddresses[_address] = false;
        AccountReaderRemoved(msg.sender, _address);
    }
}

 
contract TransparencyRelayer {
     
    struct FundValueRepresentation {
        uint256 usdValue;
        uint256 etherEquivalent;
        uint256 suppliedTimestamp;
        uint256 blockTimestamp;
    }

     
    struct AccountBalanceRepresentation {
        string accountType;  
        string accountIssuer;  
        uint256 balance;  
        string accountReference;  
        string validationUrl;  
        uint256 suppliedTimestamp;
        uint256 blockTimestamp;
    }

     
    FundValueRepresentation[] public fundValues;
    
     
    AccountBalanceRepresentation[] public accountBalances;

     
    AuthenticationManager authenticationManager;

     
    event FundValue(uint256 usdValue, uint256 etherEquivalent, uint256 suppliedTimestamp, uint256 blockTimestamp);

     
    event AccountBalance(string accountType, string accountIssuer, uint256 balance, string accountReference, string validationUrl, uint256 timestamp, uint256 blockTimestamp);

     
    modifier adminOnly {
        if (!authenticationManager.isCurrentAdmin(msg.sender)) throw;
        _;
    }

     
    function TransparencyRelayer(address _authenticationManagerAddress) {
         
        authenticationManager = AuthenticationManager(_authenticationManagerAddress);
        if (authenticationManager.contractVersion() != 100201707171503)
            throw;
    }

     
    function contractVersion() constant returns(uint256) {
         
        return 200201707071127;
    }

     
    function fundValueCount() constant returns (uint256 _count) {
        _count = fundValues.length;
    }

     
    function accountBalanceCount() constant returns (uint256 _count) {
        _count = accountBalances.length;
    }

     
    function fundValuePublish(uint256 _usdTotalFund, uint256 _etherTotalFund, uint256 _definedTimestamp) adminOnly {
         
        fundValues.length++;
        fundValues[fundValues.length - 1] = FundValueRepresentation(_usdTotalFund, _etherTotalFund, _definedTimestamp, now);

         
        FundValue(_usdTotalFund, _etherTotalFund, _definedTimestamp, now);
    }

    function accountBalancePublish(string _accountType, string _accountIssuer, uint256 _balance, string _accountReference, string _validationUrl, uint256 _timestamp) adminOnly {
         
        accountBalances.length++;
        accountBalances[accountBalances.length - 1] = AccountBalanceRepresentation(_accountType, _accountIssuer, _balance, _accountReference, _validationUrl, _timestamp, now);

         
        AccountBalance(_accountType, _accountIssuer, _balance, _accountReference, _validationUrl, _timestamp, now);
    }
}