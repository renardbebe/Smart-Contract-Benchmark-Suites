 

pragma solidity ^0.4.25;


 
 
contract EPCToken {
    string public name = 'Earth Power Coin';     
    uint8 public decimals = 18;                  
    string public symbol = 'EPC';                
    string public version = '1.3';

    uint256 weisPerEth = 1000000000000000000;
     
    uint256 public totalSupply = 20000000000 * weisPerEth;
    uint256 public tokenWeisPerEth = 25000 * 1000000000000000000;   
    address owner0;      
    address owner;
    uint256 public saleCap = 2000000000 * weisPerEth;
    uint256 public notAttributed = totalSupply - saleCap;

    constructor(
        uint256 _initialAmount,
        uint256 _saleCap,
        string _tokenName,
        string _tokenSymbol,
        uint8 _decimalUnits
        ) public {
        totalSupply = _initialAmount * weisPerEth;            
        saleCap = _saleCap * weisPerEth;
        notAttributed = totalSupply - saleCap;                
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                

        owner0 = msg.sender;
        owner = msg.sender;
        
        balances[owner] = 100 * weisPerEth;                   
        notAttributed -= balances[owner];
        emit Transfer(0, owner, balances[owner]);
    }
    
    modifier ownerOnly {
        require(owner == msg.sender || owner0 == msg.sender);
        _;
    }

    function setOwner(address _newOwner) public ownerOnly {
        if (owner0 == 0) {
            if (owner == 0) {
                owner0 = _newOwner;
            } else {
                owner0 = owner;
            }
        }
        owner = _newOwner;
    }
    
    function addToTotalSupply(uint256 _delta) public ownerOnly returns (uint256 availableAmount) {
        totalSupply += _delta * weisPerEth;
        notAttributed += _delta * weisPerEth;
        return notAttributed;
    }
    
    function withdraw() public ownerOnly {
        msg.sender.transfer(address(this).balance);
    }
    
    function setSaleCap(uint256 _saleCap) public ownerOnly returns (uint256 toBeSold) {
        notAttributed += saleCap;            
        saleCap = _saleCap * weisPerEth;
        if (saleCap > notAttributed) {       
            saleCap = notAttributed;
        }
        notAttributed -= saleCap;            
        return saleCap;
    }
    
    bool public onSaleFlag = false;
    
    function setSaleFlag(bool _saleFlag) public ownerOnly {
        onSaleFlag = _saleFlag;
    }
    
    bool public useWhitelistFlag = false;
    
    function setUseWhitelistFlag(bool _useWhitelistFlag) public ownerOnly {
        useWhitelistFlag = _useWhitelistFlag;
    }
    
    function calcTokenSold(uint256 _ethValue) public view returns (uint256 tokenValue) {
        return _ethValue * tokenWeisPerEth / weisPerEth;
    }
    
    uint256 public percentFrozenWhenBought = 75;    
    uint256 public percentUnfrozenAfterBuyPerPeriod = 25;   
    uint public buyUnfreezePeriodSeconds = 30 * 24 * 3600;   
    
    function setPercentFrozenWhenBought(uint256 _percentFrozenWhenBought) public ownerOnly {
        percentFrozenWhenBought = _percentFrozenWhenBought;
    }
    
    function setPercentUnfrozenAfterBuyPerPeriod(uint256 _percentUnfrozenAfterBuyPerPeriod) public ownerOnly {
        percentUnfrozenAfterBuyPerPeriod = _percentUnfrozenAfterBuyPerPeriod;
    }
    
    function setBuyUnfreezePeriodSeconds(uint _buyUnfreezePeriodSeconds) public ownerOnly {
        buyUnfreezePeriodSeconds = _buyUnfreezePeriodSeconds;
    }
    
    function buy() payable public {
        if (useWhitelistFlag) {
            if (!isWhitelist(msg.sender)) {
                emit NotWhitelisted(msg.sender);
                revert();
            }
        }
        if (saleCap>0) {
            uint256 tokens = calcTokenSold(msg.value);
            if (tokens<=saleCap) {
                if (tokens > 0) { 
                    lastUnfrozenTimestamps[msg.sender] = block.timestamp;
                    boughtTokens[msg.sender] += tokens;
                    frozenTokens[msg.sender] += tokens * percentFrozenWhenBought / 100;
                    balances[msg.sender] += tokens * ( 100 - percentFrozenWhenBought) / 100;
                    saleCap -= tokens;
                    emit Transfer(0, msg.sender, tokens);
                } else {
                    revert();
                }
            } else {
                emit NotEnoughTokensLeftForSale(saleCap);
                revert();
            }
        } else {
            emit NotEnoughTokensLeftForSale(saleCap);
            revert();
        }
    }

    function () payable public {
         
        if (!onSaleFlag) {
            revert();
        } else {
            buy();
        }
    }
    
    mapping (address => uint256) public boughtTokens;   
    mapping (address => uint) public lastUnfrozenTimestamps;
    mapping (address => uint256) public frozenTokens;
    
    uint256 public percentFrozenWhenAwarded = 100;    
    uint256 public percentUnfrozenAfterAwardedPerPeriod = 25;   
    uint public awardedInitialWaitSeconds = 6 * 30 * 24 * 3600;   
    uint public awardedUnfreezePeriodSeconds = 30 * 24 * 3600;   
    
    function setPercentFrozenWhenAwarded(uint256 _percentFrozenWhenAwarded) public ownerOnly {
        percentFrozenWhenAwarded = _percentFrozenWhenAwarded;
    }
    
    function setPercentUnfrozenAfterAwardedPerPeriod(uint256 _percentUnfrozenAfterAwardedPerPeriod) public ownerOnly {
        percentUnfrozenAfterAwardedPerPeriod = _percentUnfrozenAfterAwardedPerPeriod;
    }
    
    function setAwardedInitialWaitSeconds(uint _awardedInitialWaitSeconds) public ownerOnly {
        awardedInitialWaitSeconds = _awardedInitialWaitSeconds;
    }
    
    function setAwardedUnfreezePeriodSeconds(uint _awardedUnfreezePeriodSeconds) public ownerOnly {
        awardedUnfreezePeriodSeconds = _awardedUnfreezePeriodSeconds;
    }
    
    function award(address _to, uint256 _nbTokens) public ownerOnly {
        if (notAttributed>0) {
            uint256 tokens = _nbTokens * weisPerEth;
            if (tokens<=notAttributed) {
                if (tokens > 0) {
                    awardedTimestamps[_to] = block.timestamp;
                    awardedTokens[_to] += tokens;
                    frozenAwardedTokens[_to] += tokens * percentFrozenWhenAwarded / 100;
                    balances[_to] += tokens * ( 100 - percentFrozenWhenAwarded) / 100;
                    notAttributed -= tokens;
                    emit Transfer(0, _to, tokens);
                }
            } else {
                emit NotEnoughTokensLeft(notAttributed);
            }
        } else {
            emit NotEnoughTokensLeft(notAttributed);
        }
    }
    
    mapping (address => uint256) public awardedTokens;
    mapping (address => uint) public awardedTimestamps;
    mapping (address => uint) public lastUnfrozenAwardedTimestamps;
    mapping (address => uint256) public frozenAwardedTokens;
    
     
    function grant(address _to, uint256 _nbTokens) public ownerOnly {
        if (notAttributed>0) {
            uint256 tokens = _nbTokens * weisPerEth;
            if (tokens<=notAttributed) {
                if (tokens > 0) {
                    balances[_to] += tokens;
                    notAttributed -= tokens;
                    emit Transfer(0, _to, tokens);
                }
            } else {
                emit NotEnoughTokensLeft(notAttributed);
            }
        } else {
            emit NotEnoughTokensLeft(notAttributed);
        }
    }
    
    function setWhitelist(address _addr, bool _wlStatus) public ownerOnly {
        whitelist[_addr] = _wlStatus;
    }
    
    function isWhitelist(address _addr) public view returns (bool isWhitelisted) {
        return whitelist[_addr]==true;
    }
    
    mapping (address => bool) public whitelist;
    
    function setSaleAddr(address _addr, bool _saleStatus) public ownerOnly {
        saleAddrs[_addr] = _saleStatus;
    }
    
    function isSaleAddr(address _addr) public view returns (bool isASaleAddr) {
        return saleAddrs[_addr]==true;
    }
    
    mapping (address => bool) public saleAddrs;             
    
    bool public manualSaleFlag = false;
    
    function setManualSaleFlag(bool _manualSaleFlag) public ownerOnly {
        manualSaleFlag = _manualSaleFlag;
    }
    
    mapping (address => uint256) public balances;       
    mapping (address => mapping (address => uint256)) allowed;
    

    function setBlockedAccount(address _addr, bool _blockedStatus) public ownerOnly {
        blockedAccounts[_addr] = _blockedStatus;
    }
    
    function isBlockedAccount(address _addr) public view returns (bool isAccountBlocked) {
        return blockedAccounts[_addr]==true;
    }
    
    mapping (address => bool) public blockedAccounts;   
    
     
    function moveTokens(address _from, address _to, uint256 _amount) public ownerOnly  returns (bool success) {
        if (_amount>0 && balances[_from] >= _amount) {
            balances[_from] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
    
    function unfreezeBoughtTokens(address _owner) public {
        if (frozenTokens[_owner] > 0) {
            uint elapsed = block.timestamp - lastUnfrozenTimestamps[_owner];
            if (elapsed > buyUnfreezePeriodSeconds) {
                uint256 tokensToUnfreeze = boughtTokens[_owner] * percentUnfrozenAfterBuyPerPeriod / 100;
                if (tokensToUnfreeze > frozenTokens[_owner]) {
                    tokensToUnfreeze = frozenTokens[_owner];
                }
                balances[_owner] += tokensToUnfreeze;
                frozenTokens[_owner] -= tokensToUnfreeze;
                lastUnfrozenTimestamps[_owner] = block.timestamp;
            }
        } 
    }

    function unfreezeAwardedTokens(address _owner) public {
        if (frozenAwardedTokens[_owner] > 0) {
            uint elapsed = 0;
            uint waitTime = awardedInitialWaitSeconds;
            if (lastUnfrozenAwardedTimestamps[_owner]<=0) {
                elapsed = block.timestamp - awardedTimestamps[_owner];
            } else {
                elapsed = block.timestamp - lastUnfrozenAwardedTimestamps[_owner];
                waitTime = awardedUnfreezePeriodSeconds;
            }
            if (elapsed > waitTime) {
                uint256 tokensToUnfreeze = awardedTokens[_owner] * percentUnfrozenAfterAwardedPerPeriod / 100;
                if (tokensToUnfreeze > frozenAwardedTokens[_owner]) {
                    tokensToUnfreeze = frozenAwardedTokens[_owner];
                }
                balances[_owner] += tokensToUnfreeze;
                frozenAwardedTokens[_owner] -= tokensToUnfreeze;
                lastUnfrozenAwardedTimestamps[_owner] = block.timestamp;
            }
        } 
    }
    
    function unfreezeTokens(address _owner) public returns (uint256 frozenAmount) {
        unfreezeBoughtTokens(_owner);
        unfreezeAwardedTokens(_owner);
        return frozenTokens[_owner] + frozenAwardedTokens[_owner];
    }

     
     
    function balanceOf(address _owner) public returns (uint256 balance) {
        unfreezeTokens(_owner);
        return balances[_owner];
    }

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        if (!isBlockedAccount(msg.sender) && (balanceOf(msg.sender) >= _value && _value > 0)) {
            if (isSaleAddr(msg.sender)) {
                if (manualSaleFlag) {
                    boughtTokens[_to] += _value;
                    lastUnfrozenTimestamps[_to] = block.timestamp;
                    frozenTokens[_to] += _value * percentFrozenWhenBought / 100;
                    balances[_to] += _value * ( 100 - percentFrozenWhenBought) / 100;
                } else {
                    return false;
                }
            } else {
                balances[_to] += _value;
            }
            balances[msg.sender] -= _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { 
            return false; 
        }
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        if (!isBlockedAccount(msg.sender) && (balanceOf(_from) >= _value && allowed[_from][msg.sender] >= _value) && _value > 0) {
            if (isSaleAddr(_from)) {
                if (manualSaleFlag) {
                    boughtTokens[_to] += _value;
                    lastUnfrozenTimestamps[_to] = block.timestamp;
                    frozenTokens[_to] += _value * percentFrozenWhenBought / 100;
                    balances[_to] += _value * ( 100 - percentFrozenWhenBought) / 100;
                } else {
                    return false;
                }
            } else {
                balances[_to] += _value;
            }
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { 
            return false; 
        }
    }

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    

     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event NotEnoughTokensLeftForSale(uint256 _tokensLeft);
    event NotEnoughTokensLeft(uint256 _tokensLeft);
    event NotWhitelisted(address _addr);
}