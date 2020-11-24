 

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

 
library BTC {
     
     
    function parseVarInt(bytes txBytes, uint pos) returns (uint, uint) {
         
        var ibit = uint8(txBytes[pos]);
        pos += 1;   

        if (ibit < 0xfd) {
            return (ibit, pos);
        } else if (ibit == 0xfd) {
            return (getBytesLE(txBytes, pos, 16), pos + 2);
        } else if (ibit == 0xfe) {
            return (getBytesLE(txBytes, pos, 32), pos + 4);
        } else if (ibit == 0xff) {
            return (getBytesLE(txBytes, pos, 64), pos + 8);
        }
    }
     
    function getBytesLE(bytes data, uint pos, uint bits) returns (uint) {
        if (bits == 8) {
            return uint8(data[pos]);
        } else if (bits == 16) {
            return uint16(data[pos])
                 + uint16(data[pos + 1]) * 2 ** 8;
        } else if (bits == 32) {
            return uint32(data[pos])
                 + uint32(data[pos + 1]) * 2 ** 8
                 + uint32(data[pos + 2]) * 2 ** 16
                 + uint32(data[pos + 3]) * 2 ** 24;
        } else if (bits == 64) {
            return uint64(data[pos])
                 + uint64(data[pos + 1]) * 2 ** 8
                 + uint64(data[pos + 2]) * 2 ** 16
                 + uint64(data[pos + 3]) * 2 ** 24
                 + uint64(data[pos + 4]) * 2 ** 32
                 + uint64(data[pos + 5]) * 2 ** 40
                 + uint64(data[pos + 6]) * 2 ** 48
                 + uint64(data[pos + 7]) * 2 ** 56;
        }
    }
     
     
    function getFirstTwoOutputs(bytes txBytes)
             returns (uint, bytes20, uint, bytes20)
    {
        uint pos;
        uint[] memory input_script_lens = new uint[](2);
        uint[] memory output_script_lens = new uint[](2);
        uint[] memory script_starts = new uint[](2);
        uint[] memory output_values = new uint[](2);
        bytes20[] memory output_addresses = new bytes20[](2);

        pos = 4;   

        (input_script_lens, pos) = scanInputs(txBytes, pos, 0);

        (output_values, script_starts, output_script_lens, pos) = scanOutputs(txBytes, pos, 2);

        for (uint i = 0; i < 2; i++) {
            var pkhash = parseOutputScript(txBytes, script_starts[i], output_script_lens[i]);
            output_addresses[i] = pkhash;
        }

        return (output_values[0], output_addresses[0],
                output_values[1], output_addresses[1]);
    }
     
     
    function checkValueSent(bytes txBytes, bytes20 btcAddress, uint value)
             returns (bool)
    {
        uint pos = 4;   
        (, pos) = scanInputs(txBytes, pos, 0);   

         
        var (output_values, script_starts, output_script_lens,) = scanOutputs(txBytes, pos, 0);

         
        for (uint i = 0; i < output_values.length; i++) {
            var pkhash = parseOutputScript(txBytes, script_starts[i], output_script_lens[i]);
            if (pkhash == btcAddress && output_values[i] >= value) {
                return true;
            }
        }
    }
     
     
     
     
     
    function scanInputs(bytes txBytes, uint pos, uint stop)
             returns (uint[], uint)
    {
        uint n_inputs;
        uint halt;
        uint script_len;

        (n_inputs, pos) = parseVarInt(txBytes, pos);

        if (stop == 0 || stop > n_inputs) {
            halt = n_inputs;
        } else {
            halt = stop;
        }

        uint[] memory script_lens = new uint[](halt);

        for (var i = 0; i < halt; i++) {
            pos += 36;   
            (script_len, pos) = parseVarInt(txBytes, pos);
            script_lens[i] = script_len;
            pos += script_len + 4;   
        }

        return (script_lens, pos);
    }
     
     
     
     
     
    function scanOutputs(bytes txBytes, uint pos, uint stop)
             returns (uint[], uint[], uint[], uint)
    {
        uint n_outputs;
        uint halt;
        uint script_len;

        (n_outputs, pos) = parseVarInt(txBytes, pos);

        if (stop == 0 || stop > n_outputs) {
            halt = n_outputs;
        } else {
            halt = stop;
        }

        uint[] memory script_starts = new uint[](halt);
        uint[] memory script_lens = new uint[](halt);
        uint[] memory output_values = new uint[](halt);

        for (var i = 0; i < halt; i++) {
            output_values[i] = getBytesLE(txBytes, pos, 64);
            pos += 8;

            (script_len, pos) = parseVarInt(txBytes, pos);
            script_starts[i] = pos;
            script_lens[i] = script_len;
            pos += script_len;
        }

        return (output_values, script_starts, script_lens, pos);
    }
     
    function sliceBytes20(bytes data, uint start) returns (bytes20) {
        uint160 slice = 0;
        for (uint160 i = 0; i < 20; i++) {
            slice += uint160(data[i + start]) << (8 * (19 - i));
        }
        return bytes20(slice);
    }
     
     
    function isP2PKH(bytes txBytes, uint pos, uint script_len) returns (bool) {
        return (script_len == 25)            
            && (txBytes[pos] == 0x76)        
            && (txBytes[pos + 1] == 0xa9)    
            && (txBytes[pos + 2] == 0x14)    
            && (txBytes[pos + 23] == 0x88)   
            && (txBytes[pos + 24] == 0xac);  
    }
     
     
    function isP2SH(bytes txBytes, uint pos, uint script_len) returns (bool) {
        return (script_len == 23)            
            && (txBytes[pos + 0] == 0xa9)    
            && (txBytes[pos + 1] == 0x14)    
            && (txBytes[pos + 22] == 0x87);  
    }
     
     
     
    function parseOutputScript(bytes txBytes, uint pos, uint script_len)
             returns (bytes20)
    {
        if (isP2PKH(txBytes, pos, script_len)) {
            return sliceBytes20(txBytes, pos + 3);
        } else if (isP2SH(txBytes, pos, script_len)) {
            return sliceBytes20(txBytes, pos + 2);
        } else {
            return;
        }
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
        lockedFor   = lockedAddresses[_owner][count].lockedFor;
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

contract Tokensale {
    using SafeMath for uint256;
    
     
    bool public tokenContractDefined = false;
    
     
    bool public salePhase = true;

     
    uint256 public ethereumSaleRate = 700;  

     
    uint256 public bitcoinSaleRate = 14000;  

     
    Token token;

     
    AuthenticationManager authenticationManager;

     
    mapping(uint256 => bool) public transactionsClaimed;

     
    uint256 public minimunEthereumToInvest = 0;

     
    uint256 public minimunBTCToInvest = 0;

     
    event SaleClosed();

     
    event SaleStarted();

     
    event EthereumRateUpdated(uint256 rate, uint256 timestamp);

     
    event BitcoinRateUpdated(uint256 rate, uint256 timestamp);

     
    event MinimumEthereumInvestmentUpdated(uint256 _value, uint256 timestamp);

     
    event MinimumBitcoinInvestmentUpdated(uint256 _value, uint256 timestamp);

     
    modifier onlyDuringSale {

        if (!tokenContractDefined || (!salePhase)) throw;
        _;
    }

     
    modifier adminOnly {
        if (!authenticationManager.isCurrentAdmin(msg.sender)) throw;
        _;
    }

     
    function Tokensale(address _authenticationManagerAddress) {        
                
         
        authenticationManager = AuthenticationManager(_authenticationManagerAddress);
    }

     
    function setTokenContractAddress(address _tokenContractAddress) adminOnly {
         
        if (tokenContractDefined)
            throw;

         
        token = Token(_tokenContractAddress);

        tokenContractDefined = true;
    }

     
    function processBTCTransaction(bytes txn, uint256 _txHash, address ethereumAddress, bytes20 bitcoinAddress) adminOnly returns (uint256)
    {
         
        if(transactionsClaimed[_txHash] != false) 
            throw;

        var (outputValue1, outputAddress1, outputValue2, outputAddress2) = BTC.getFirstTwoOutputs(txn);

        if(BTC.checkValueSent(txn, bitcoinAddress, 1))
        {
            require(outputValue1 >= minimunBTCToInvest);

              
            uint256 tokensPurchased = outputValue1 * bitcoinSaleRate * (10**10);  

            token.mintTokens(ethereumAddress, tokensPurchased);

            transactionsClaimed[_txHash] = true;
        }
        else
        {
             
            throw;
        }
    }

    function btcTransactionClaimed(uint256 _txHash) returns(bool) {
        return transactionsClaimed[_txHash];
    }   
    
     
    function () payable {
    
        buyTokens(msg.sender);
    
    }

     
    function buyTokens(address beneficiary) onlyDuringSale payable {

        require(beneficiary != 0x0);
        require(validPurchase());
        
        uint256 weiAmount = msg.value;

        uint256 tokensPurchased = weiAmount.mul(ethereumSaleRate);
        
         
        if (tokensPurchased > 0)
        {
            token.mintTokens(beneficiary, tokensPurchased);
        }
    }

     
    function validPurchase() internal constant returns (bool) {

        bool nonZeroPurchase = ( msg.value != 0 && msg.value >= minimunEthereumToInvest);
        return nonZeroPurchase;
    }

     
    function setEthereumRate(uint256 _rate) adminOnly {

        ethereumSaleRate = _rate;

         
        EthereumRateUpdated(ethereumSaleRate, now);
    }

       
    function setBitcoinRate(uint256 _rate) adminOnly {

        bitcoinSaleRate = _rate;

         
        BitcoinRateUpdated(bitcoinSaleRate, now);
    }    

         
    function setMinimumEthereumToInvest(uint256 _value) adminOnly {

        minimunEthereumToInvest = _value;

         
        MinimumEthereumInvestmentUpdated(_value, now);
    }    

           
    function setMinimumBitcoinToInvest(uint256 _value) adminOnly {

        minimunBTCToInvest = _value;

         
        MinimumBitcoinInvestmentUpdated(_value, now);
    }

       
    function close() adminOnly onlyDuringSale {

         
        salePhase = false;
        SaleClosed();

         
        if (!msg.sender.send(this.balance))
            throw;
    }

     
    function openSale() adminOnly {        
        salePhase = true;
        SaleStarted();
    }
}