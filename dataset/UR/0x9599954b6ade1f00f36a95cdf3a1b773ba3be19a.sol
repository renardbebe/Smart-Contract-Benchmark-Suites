 

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

 
contract SmartInvestmentFundToken {
    using SafeMath for uint256;

     
    mapping (address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) allowed;

     
    address[] allTokenHolders;

     
    string public name;

     
    string public symbol;

     
    uint8 public decimals;

     
    uint256 totalSupplyAmount = 0;

     
    address public icoContractAddress;

     
    bool public isClosed;

     
    IcoPhaseManagement icoPhaseManagement;

     
    AuthenticationManager authenticationManager;

     
    event FundClosed();
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function SmartInvestmentFundToken(address _icoContractAddress, address _authenticationManagerAddress) {
         
        name = "Smart Investment Fund Token";
        symbol = "SIFT";
        decimals = 0;

         
        icoPhaseManagement = IcoPhaseManagement(_icoContractAddress);
        if (icoPhaseManagement.contractVersion() != 300201707171440)
            throw;
        authenticationManager = AuthenticationManager(_authenticationManagerAddress);
        if (authenticationManager.contractVersion() != 100201707171503)
            throw;
        
         
        icoContractAddress = _icoContractAddress;
    }

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    } 

     
    modifier accountReaderOnly {
        if (!authenticationManager.isCurrentAccountReader(msg.sender)) throw;
        _;
    }

    modifier fundSendablePhase {
         
        if (icoPhaseManagement.icoPhase())
            throw;

         
        if (icoPhaseManagement.icoAbandoned())
            throw;

         
        _;
    }

     
    function contractVersion() constant returns(uint256) {
         
        return 500201707171440;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _amount) fundSendablePhase onlyPayloadSize(3) returns (bool) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to].add(_amount) > balances[_to]) {
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
 
     
    function approve(address _spender, uint256 _amount) fundSendablePhase onlyPayloadSize(2) returns (bool success) {
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

     
    function transfer(address _to, uint256 _amount) fundSendablePhase onlyPayloadSize(2) returns (bool) {
         
        if (balances[msg.sender] < _amount || balances[_to].add(_amount) < balances[_to])
            return false;

         
        bool isRecipientNew = balances[_to] < 1;

         
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

         
        if (isRecipientNew)
            tokenOwnerAdd(_to);
        if (balances[msg.sender] < 1)
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
         
        if (msg.sender != icoContractAddress || !icoPhaseManagement.icoPhase())
            throw;

         
        bool isNew = balances[_address] == 0;
        totalSupplyAmount = totalSupplyAmount.add(_amount);
        balances[_address] = balances[_address].add(_amount);
        if (isNew)
            tokenOwnerAdd(_address);
        Transfer(0, _address, _amount);
    }
}

contract IcoPhaseManagement {
    using SafeMath for uint256;
    
     
    bool public icoPhase = true;

     
    bool public icoAbandoned = false;

     
    bool siftContractDefined = false;
    
     
    uint256 constant icoUnitPrice = 10 finney;

     
    mapping(address => uint256) public abandonedIcoBalances;

     
    SmartInvestmentFundToken smartInvestmentFundToken;

     
    AuthenticationManager authenticationManager;

     
    uint256 constant public icoStartTime = 1501545600;  

     
    uint256 constant public icoEndTime = 1505433600;  

     
    event IcoClosed();

     
    event IcoAbandoned(string details);
    
     
    modifier onlyDuringIco {
        bool contractValid = siftContractDefined && !smartInvestmentFundToken.isClosed();
        if (!contractValid || (!icoPhase && !icoAbandoned)) throw;
        _;
    }

     
    modifier adminOnly {
        if (!authenticationManager.isCurrentAdmin(msg.sender)) throw;
        _;
    }

     
    function IcoPhaseManagement(address _authenticationManagerAddress) {
         
        if (icoStartTime >= icoEndTime)
            throw;

         
        authenticationManager = AuthenticationManager(_authenticationManagerAddress);
        if (authenticationManager.contractVersion() != 100201707171503)
            throw;
    }

     
    function setSiftContractAddress(address _siftContractAddress) adminOnly {
         
        if (siftContractDefined)
            throw;

         
        smartInvestmentFundToken = SmartInvestmentFundToken(_siftContractAddress);
        if (smartInvestmentFundToken.contractVersion() != 500201707171440)
            throw;
        siftContractDefined = true;
    }

     
    function contractVersion() constant returns(uint256) {
         
        return 300201707171440;
    }

     
    function close() adminOnly onlyDuringIco {
         
        if (now <= icoEndTime)
            throw;

         
        icoPhase = false;
        IcoClosed();

         
        if (!msg.sender.send(this.balance))
            throw;
    }
    
     
    function () onlyDuringIco payable {
         
        if (now < icoStartTime || now > icoEndTime)
            throw;

         
        uint256 tokensPurchased = msg.value / icoUnitPrice;
        uint256 purchaseTotalPrice = tokensPurchased * icoUnitPrice;
        uint256 change = msg.value.sub(purchaseTotalPrice);

         
        if (tokensPurchased > 0)
            smartInvestmentFundToken.mintTokens(msg.sender, tokensPurchased);

         
        if (change > 0 && !msg.sender.send(change))
            throw;
    }

     
    function abandon(string details) adminOnly onlyDuringIco {
         
        if (now <= icoEndTime)
            throw;

         
        if (icoAbandoned)
            throw;

         
        uint256 paymentPerShare = this.balance / smartInvestmentFundToken.totalSupply();

         
        uint numberTokenHolders = smartInvestmentFundToken.tokenHolderCount();
        uint256 totalAbandoned = 0;
        for (uint256 i = 0; i < numberTokenHolders; i++) {
             
            address addr = smartInvestmentFundToken.tokenHolder(i);
            uint256 etherToSend = paymentPerShare * smartInvestmentFundToken.balanceOf(addr);
            if (etherToSend < 1)
                continue;

             
            abandonedIcoBalances[addr] = abandonedIcoBalances[addr].add(etherToSend);
            totalAbandoned = totalAbandoned.add(etherToSend);
        }

         
        icoAbandoned = true;
        IcoAbandoned(details);

         
        uint256 remainder = this.balance.sub(totalAbandoned);
        if (remainder > 0)
            if (!msg.sender.send(remainder))
                 
                abandonedIcoBalances[msg.sender] = abandonedIcoBalances[msg.sender].add(remainder);
    }

     
    function abandonedFundWithdrawal() {
         
        if (!icoAbandoned || abandonedIcoBalances[msg.sender] == 0)
            throw;
        
         
        uint256 funds = abandonedIcoBalances[msg.sender];
        abandonedIcoBalances[msg.sender] = 0;
        if (!msg.sender.send(funds))
            throw;
    }
}

 
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

contract DividendManager {
    using SafeMath for uint256;

     
    SmartInvestmentFundToken siftContract;

     
    mapping (address => uint256) public dividends;

     
    event PaymentAvailable(address addr, uint256 amount);

     
    event DividendPayment(uint256 paymentPerShare, uint256 timestamp);

     
    function DividendManager(address _siftContractAddress) {
         
        siftContract = SmartInvestmentFundToken(_siftContractAddress);
        if (siftContract.contractVersion() != 500201707171440)
            throw;
    }

     
    function contractVersion() constant returns(uint256) {
         
        return 600201707171440;
    }

     
    function () payable {
        if (siftContract.isClosed())
            throw;

         
        uint256 validSupply = siftContract.totalSupply();
        uint256 paymentPerShare = msg.value / validSupply;
        if (paymentPerShare == 0)
            throw;

         
        uint256 totalPaidOut = 0;
        for (uint256 i = 0; i < siftContract.tokenHolderCount(); i++) {
            address addr = siftContract.tokenHolder(i);
            uint256 dividend = paymentPerShare * siftContract.balanceOf(addr);
            dividends[addr] = dividends[addr].add(dividend);
            PaymentAvailable(addr, dividend);
            totalPaidOut = totalPaidOut.add(dividend);
        }

         
        uint256 remainder = msg.value.sub(totalPaidOut);
        if (remainder > 0 && !msg.sender.send(remainder)) {
            dividends[msg.sender] = dividends[msg.sender].add(remainder);
            PaymentAvailable(msg.sender, remainder);
        }

         
        DividendPayment(paymentPerShare, now);
    }

     
    function withdrawDividend() {
         
        if (dividends[msg.sender] == 0)
            throw;
        
         
        uint256 dividend = dividends[msg.sender];
        dividends[msg.sender] = 0;

         
        if (!msg.sender.send(dividend))
            throw;
    }
}