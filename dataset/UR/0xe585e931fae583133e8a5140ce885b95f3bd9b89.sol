 

pragma solidity ^0.4.11;

contract SafeMath {

    function safeMul(uint256 a, uint256 b) internal returns (uint256 ) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal returns (uint256 ) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal returns (uint256 ) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal returns (uint256 ) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }
}

contract ERC20 {

     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20, SafeMath {

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function transfer(address _to, uint256 _value) returns (bool) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else return false;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else return false;
    }

     
     
     
    function approve(address _spender, uint256 _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Ownable {

    address public owner;
    address public pendingOwner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() {
        if (msg.sender == pendingOwner) {
            owner = pendingOwner;
            pendingOwner = 0;
        }
    }
}

contract MultiOwnable {

    mapping (address => bool) ownerMap;
    address[] public owners;

    event OwnerAdded(address indexed _newOwner);
    event OwnerRemoved(address indexed _oldOwner);

    modifier onlyOwner() {
        if (!isOwner(msg.sender)) throw;
        _;
    }

    function MultiOwnable() {
         
        address owner = msg.sender;
        ownerMap[owner] = true;
        owners.push(owner);
    }

    function ownerCount() constant returns (uint256) {
        return owners.length;
    }

    function isOwner(address owner) constant returns (bool) {
        return ownerMap[owner];
    }

    function addOwner(address owner) onlyOwner returns (bool) {
        if (!isOwner(owner) && owner != 0) {
            ownerMap[owner] = true;
            owners.push(owner);

            OwnerAdded(owner);
            return true;
        } else return false;
    }

    function removeOwner(address owner) onlyOwner returns (bool) {
        if (isOwner(owner)) {
            ownerMap[owner] = false;
            for (uint i = 0; i < owners.length - 1; i++) {
                if (owners[i] == owner) {
                    owners[i] = owners[owners.length - 1];
                    break;
                }
            }
            owners.length -= 1;

            OwnerRemoved(owner);
            return true;
        } else return false;
    }
}

contract Pausable is Ownable {

    bool public paused;

    modifier ifNotPaused {
        if (paused) throw;
        _;
    }

    modifier ifPaused {
        if (!paused) throw;
        _;
    }

     
    function pause() external onlyOwner {
        paused = true;
    }

     
    function resume() external onlyOwner ifPaused {
        paused = false;
    }
}

contract TokenSpender {
    function receiveApproval(address _from, uint256 _value);
}

contract BsToken is StandardToken, MultiOwnable {

    bool public locked;

    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals = 18;
    string public version = 'v0.1';

    address public creator;
    address public seller;
    uint256 public tokensSold;
    uint256 public totalSales;

    event Sell(address indexed _seller, address indexed _buyer, uint256 _value);
    event SellerChanged(address indexed _oldSeller, address indexed _newSeller);

    modifier onlyUnlocked() {
        if (!isOwner(msg.sender) && locked) throw;
        _;
    }

    function BsToken(string _name, string _symbol, uint256 _totalSupplyNoDecimals, address _seller) MultiOwnable() {

         
        locked = true;

        creator = msg.sender;
        seller = _seller;

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupplyNoDecimals * 1e18;

        balances[seller] = totalSupply;
        Transfer(0x0, seller, totalSupply);
    }

    function changeSeller(address newSeller) onlyOwner returns (bool) {
        if (newSeller == 0x0 || seller == newSeller) throw;

        address oldSeller = seller;

        uint256 unsoldTokens = balances[oldSeller];
        balances[oldSeller] = 0;
        balances[newSeller] = safeAdd(balances[newSeller], unsoldTokens);
        Transfer(oldSeller, newSeller, unsoldTokens);

        seller = newSeller;
        SellerChanged(oldSeller, newSeller);
        return true;
    }

    function sellNoDecimals(address _to, uint256 _value) returns (bool) {
        return sell(_to, _value * 1e18);
    }

    function sell(address _to, uint256 _value) onlyOwner returns (bool) {
        if (balances[seller] >= _value && _value > 0) {
            balances[seller] = safeSub(balances[seller], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(seller, _to, _value);

            tokensSold = safeAdd(tokensSold, _value);
            totalSales = safeAdd(totalSales, 1);
            Sell(seller, _to, _value);
            return true;
        } else return false;
    }

    function transfer(address _to, uint256 _value) onlyUnlocked returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyUnlocked returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function lock() onlyOwner {
        locked = true;
    }

    function unlock() onlyOwner {
        locked = false;
    }

    function burn(uint256 _value) returns (bool) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value) ;
            totalSupply = safeSub(totalSupply, _value);
            Transfer(msg.sender, 0x0, _value);
            return true;
        } else return false;
    }

     
    function approveAndCall(address _spender, uint256 _value) {
        TokenSpender spender = TokenSpender(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value);
        }
    }
}

 
contract BsPresale is SafeMath, Ownable, Pausable {

    struct Backer {
        uint256 weiReceived;  
        uint256 tokensSent;   
    }

     
    mapping(address => Backer) public backers;  

     
    mapping (address => mapping (uint256 => uint256)) public externalSales;

    BsToken public token;            
    address public beneficiary;      
    address public notifier;         

    uint256 public usdPerEth;
    uint256 public usdPerEthMin = 200;  
    uint256 public usdPerEthMax = 500;  

    struct UsdPerEthLog {
        uint256 rate;
        uint256 time;
        address changedBy;
    }

    UsdPerEthLog[] public usdPerEthLog;  

    uint256 public minInvestCents = 1;  
    uint256 public tokensPerCents           = 1 * 1e18;     
    uint256 public tokensPerCents_gte5kUsd  = 1.15 * 1e18;  
    uint256 public tokensPerCents_gte50kUsd = 1.25 * 1e18;  
    uint256 public amount5kUsdInCents  =  5 * 1000 * 100;   
    uint256 public amount50kUsdInCents = 50 * 1000 * 100;   
    uint256 public maxCapInCents       = 15 * 1e6 * 100;    

     
    uint256 public totalWeiReceived = 0;    
    uint256 public totalInCents = 41688175;        
    uint256 public totalTokensSold = 8714901250000000000000000;         
    uint256 public totalEthSales = 134;           
    uint256 public totalExternalSales = 0;      

    uint256 public startTime = 1504526400;  
    uint256 public endTime   = 1509451200;  
    uint256 public finalizedTime = 0;       

    bool public saleEnabled = false;        

    event BeneficiaryChanged(address indexed _oldAddress, address indexed _newAddress);
    event NotifierChanged(address indexed _oldAddress, address indexed _newAddress);
    event UsdPerEthChanged(uint256 _oldRate, uint256 _newRate);

    event EthReceived(address _buyer, uint256 _amountInWei);
    event ExternalSale(address _buyer, uint256 _amountInUsd, uint256 _tokensSold, uint256 _unixTs);

    modifier respectTimeFrame() {
        if (!isSaleOn()) throw;
        _;
    }

    modifier canNotify() {
        if (msg.sender != owner && msg.sender != notifier) throw;
        _;
    }

    function BsPresale(address _token, address _beneficiary, uint256 _usdPerEth) {
        token = BsToken(_token);

        owner = msg.sender;
        notifier = 0x73E5B12017A141d41c1a14FdaB43a54A4f9BD490;
        beneficiary = _beneficiary;

        setUsdPerEth(_usdPerEth);
    }

     
    function getNow() constant returns (uint256) {
        return now;
    }

    function setSaleEnabled(bool _enabled) onlyOwner {
        saleEnabled = _enabled;
    }

    function setBeneficiary(address _beneficiary) onlyOwner {
        BeneficiaryChanged(beneficiary, _beneficiary);
        beneficiary = _beneficiary;
    }

    function setNotifier(address _notifier) onlyOwner {
        NotifierChanged(notifier, _notifier);
        notifier = _notifier;
    }

    function setUsdPerEth(uint256 _usdPerEth) canNotify {
        if (_usdPerEth < usdPerEthMin || _usdPerEth > usdPerEthMax) throw;

        UsdPerEthChanged(usdPerEth, _usdPerEth);
        usdPerEth = _usdPerEth;
        usdPerEthLog.push(UsdPerEthLog({ rate: usdPerEth, time: getNow(), changedBy: msg.sender }));
    }

    function usdPerEthLogSize() constant returns (uint256) {
        return usdPerEthLog.length;
    }

     
    function() payable {
        if (saleEnabled) sellTokensForEth(msg.sender, msg.value);
    }

     
     
     
    function externalSale(address _buyer, uint256 _amountInUsd, uint256 _tokensSoldNoDecimals, uint256 _unixTs)
            ifNotPaused canNotify {

        if (_buyer == 0 || _amountInUsd == 0 || _tokensSoldNoDecimals == 0) throw;
        if (_unixTs == 0 || _unixTs > getNow()) throw;  

         
        if (externalSales[_buyer][_unixTs] > 0) throw;

        totalInCents = safeAdd(totalInCents, safeMul(_amountInUsd, 100));
        if (totalInCents > maxCapInCents) throw;  

        uint256 tokensSold = safeMul(_tokensSoldNoDecimals, 1e18);
        if (!token.sell(_buyer, tokensSold)) throw;  

        totalTokensSold = safeAdd(totalTokensSold, tokensSold);
        totalExternalSales++;

        externalSales[_buyer][_unixTs] = tokensSold;
        ExternalSale(_buyer, _amountInUsd, tokensSold, _unixTs);
    }

    function sellTokensForEth(address _buyer, uint256 _amountInWei) internal ifNotPaused respectTimeFrame {

        uint256 amountInCents = weiToCents(_amountInWei);
        if (amountInCents < minInvestCents) throw;

        totalInCents = safeAdd(totalInCents, amountInCents);
        if (totalInCents > maxCapInCents) throw;  

        uint256 tokensSold = centsToTokens(amountInCents);
        if (!token.sell(_buyer, tokensSold)) throw;  

        totalWeiReceived = safeAdd(totalWeiReceived, _amountInWei);
        totalTokensSold = safeAdd(totalTokensSold, tokensSold);
        totalEthSales++;

        Backer backer = backers[_buyer];
        backer.tokensSent = safeAdd(backer.tokensSent, tokensSold);
        backer.weiReceived = safeAdd(backer.weiReceived, _amountInWei);   

        EthReceived(_buyer, _amountInWei);
    }

    function totalSales() constant returns (uint256) {
        return safeAdd(totalEthSales, totalExternalSales);
    }

    function weiToCents(uint256 _amountInWei) constant returns (uint256) {
        return safeDiv(safeMul(_amountInWei, usdPerEth * 100), 1 ether);
    }

    function centsToTokens(uint256 _amountInCents) constant returns (uint256) {
        uint256 rate = tokensPerCents;
         
        if (_amountInCents >= amount50kUsdInCents) {
            rate = tokensPerCents_gte50kUsd;
        } else if (_amountInCents >= amount5kUsdInCents) {
            rate = tokensPerCents_gte5kUsd;
        }
        return safeMul(_amountInCents, rate);
    }

    function isMaxCapReached() constant returns (bool) {
        return totalInCents >= maxCapInCents;
    }

    function isSaleOn() constant returns (bool) {
        uint256 _now = getNow();
        return startTime <= _now && _now <= endTime;
    }

    function isSaleOver() constant returns (bool) {
        return getNow() > endTime;
    }

    function isFinalized() constant returns (bool) {
        return finalizedTime > 0;
    }

     
    function finalize() onlyOwner {

         
        if (!isMaxCapReached() && !isSaleOver()) throw;

        beneficiary.transfer(this.balance);

        finalizedTime = getNow();
    }
}

contract SnovWhitelist is BsPresale {

    function SnovWhitelist() BsPresale(
        0xBDC5bAC39Dbe132B1E030e898aE3830017D7d969,
        0x983F64a550CD9D733f2829275f94B1A3728Fe888,
        310
    ) {}
}