 

pragma solidity ^0.4.18;
    
     
    
     
    contract Ownable {
      address public owner;
    
    
      event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    
       
      function Ownable() public {
        owner = msg.sender;
      }
    
       
      modifier onlyOwner() {
        require(msg.sender == owner);
        _;
      }
    
       
      function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
      }
    
    }
    
     
    
     
    contract Pausable is Ownable {
      event Pause();
      event Unpause();
    
      bool public paused = false;
    
    
       
      modifier whenNotPaused() {
        require(!paused);
        _;
      }
    
       
      modifier whenPaused() {
        require(paused);
        _;
      }
    
       
      function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
      }
    
       
      function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
      }
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
    
     
    
     
    contract ERC20Basic {
      function totalSupply() public view returns (uint256);
      function balanceOf(address who) public view returns (uint256);
      function transfer(address to, uint256 value) public returns (bool);
      event Transfer(address indexed from, address indexed to, uint256 value);
    }
    
     
    
     
    contract BasicToken is ERC20Basic {
      using SafeMath for uint256;
    
      mapping(address => uint256) balances;
    
      uint256 totalSupply_;
    
       
      function totalSupply() public view returns (uint256) {
        return totalSupply_;
      }
    
       
      function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
    
         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
      }
    
       
      function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
      }
    
    }
    
     
    
     
    contract ERC20 is ERC20Basic {
      function allowance(address owner, address spender) public view returns (uint256);
      function transferFrom(address from, address to, uint256 value) public returns (bool);
      function approve(address spender, uint256 value) public returns (bool);
      event Approval(address indexed owner, address indexed spender, uint256 value);
    }
    
     
    
     
    contract StandardToken is ERC20, BasicToken {
    
      mapping (address => mapping (address => uint256)) internal allowed;
    
    
       
      function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
    
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      }
    
       
      function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
      }
    
       
      function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
      }
    
       
      function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
      }
    
       
      function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
      }
    
    }
    
     
    
    contract CurrentToken is StandardToken, Pausable {
        string constant public name = "CurrentCoin";
        string constant public symbol = "CUR";
        uint8 constant public decimals = 18;
    
        uint256 constant public INITIAL_TOTAL_SUPPLY = 1e11 * (uint256(10) ** decimals);
    
        address private addressIco;
    
        modifier onlyIco() {
            require(msg.sender == addressIco);
            _;
        }
    
         
        function CurrentToken (address _ico) public {
            require(_ico != address(0));
    
            addressIco = _ico;
    
            totalSupply_ = totalSupply_.add(INITIAL_TOTAL_SUPPLY);
            balances[_ico] = balances[_ico].add(INITIAL_TOTAL_SUPPLY);
            Transfer(address(0), _ico, INITIAL_TOTAL_SUPPLY);
    
            pause();
        }
    
         
        function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
            super.transfer(_to, _value);
        }
    
         
        function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool) {
            super.transferFrom(_from, _to, _value);
        }
    
         
        function transferFromIco(address _to, uint256 _value) onlyIco public returns (bool) {
            super.transfer(_to, _value);
        }
    
         
        function burnFromIco() onlyIco public {
            uint256 remainingTokens = balanceOf(addressIco);
    
            balances[addressIco] = balances[addressIco].sub(remainingTokens);
            totalSupply_ = totalSupply_.sub(remainingTokens);
            Transfer(addressIco, address(0), remainingTokens);
        }
    
         
        function burnFromAddress(address _from) onlyIco public {
            uint256 amount = balances[_from];
    
            balances[_from] = 0;
            totalSupply_ = totalSupply_.sub(amount);
            Transfer(_from, address(0), amount);
        }
    }
    
     
    
     
    contract Whitelist is Ownable {
        mapping(address => bool) whitelist;
    
        uint256 public whitelistLength = 0;
    
           
        function addWallet(address _wallet) onlyOwner public {
            require(_wallet != address(0));
            require(!isWhitelisted(_wallet));
            whitelist[_wallet] = true;
            whitelistLength++;
        }
    
           
        function removeWallet(address _wallet) onlyOwner public {
            require(_wallet != address(0));
            require(isWhitelisted(_wallet));
            whitelist[_wallet] = false;
            whitelistLength--;
        }
    
          
        function isWhitelisted(address _wallet) constant public returns (bool) {
            return whitelist[_wallet];
        }
    
    }
    
     
    
    contract Whitelistable {
        Whitelist public whitelist;
    
        modifier whenWhitelisted(address _wallet) {
            require(whitelist.isWhitelisted(_wallet));
            _;
        }
    
         
        function Whitelistable() public {
            whitelist = new Whitelist();
        }
    }
    
     
    
    contract CurrentCrowdsale is Pausable, Whitelistable {
        using SafeMath for uint256;
    
        uint256 constant private DECIMALS = 18;
        uint256 constant public RESERVED_TOKENS_FOUNDERS = 40e9 * (10 ** DECIMALS);
        uint256 constant public RESERVED_TOKENS_OPERATIONAL_EXPENSES = 10e9 * (10 ** DECIMALS);
        uint256 constant public HARDCAP_TOKENS_PRE_ICO = 100e6 * (10 ** DECIMALS);
        uint256 constant public HARDCAP_TOKENS_ICO = 499e8 * (10 ** DECIMALS);
    
        uint256 public startTimePreIco = 0;
        uint256 public endTimePreIco = 0;
    
        uint256 public startTimeIco = 0;
        uint256 public endTimeIco = 0;
    
        uint256 public exchangeRatePreIco = 0;
    
        bool public isTokenRateCalculated = false;
    
        uint256 public exchangeRateIco = 0;
    
        uint256 public mincap = 0;
        uint256 public maxcap = 0;
    
        mapping(address => uint256) private investments;    
    
        uint256 public tokensSoldIco = 0;
        uint256 public tokensRemainingIco = HARDCAP_TOKENS_ICO;
        uint256 public tokensSoldTotal = 0;
    
        uint256 public weiRaisedPreIco = 0;
        uint256 public weiRaisedIco = 0;
        uint256 public weiRaisedTotal = 0;
    
        mapping(address => uint256) private investmentsPreIco;
        address[] private investorsPreIco;
    
        address private withdrawalWallet;
    
        bool public isTokensPreIcoDistributed = false;
        uint256 public distributionPreIcoCount = 0;
    
        CurrentToken public token = new CurrentToken(this);
    
        modifier beforeReachingHardCap() {
            require(tokensRemainingIco > 0 && weiRaisedTotal < maxcap);
            _;
        }
    
        modifier whenPreIcoSaleHasEnded() {
            require(now > endTimePreIco);
            _;
        }
    
        modifier whenIcoSaleHasEnded() {
            require(endTimeIco > 0 && now > endTimeIco);
            _;
        }
    
         
        function CurrentCrowdsale(
            uint256 _mincap,
            uint256 _maxcap,
            uint256 _startTimePreIco,
            uint256 _endTimePreIco,
            address _foundersWallet,
            address _operationalExpensesWallet,
            address _withdrawalWallet
        ) Whitelistable() public
        {
            require(_foundersWallet != address(0) && _operationalExpensesWallet != address(0) && _withdrawalWallet != address(0));
            require(_startTimePreIco >= now && _endTimePreIco > _startTimePreIco);
            require(_mincap > 0 && _maxcap > _mincap);
    
            startTimePreIco = _startTimePreIco;
            endTimePreIco = _endTimePreIco;
    
            withdrawalWallet = _withdrawalWallet;
    
            mincap = _mincap;
            maxcap = _maxcap;
    
            whitelist.transferOwnership(msg.sender);
    
            token.transferFromIco(_foundersWallet, RESERVED_TOKENS_FOUNDERS);
            token.transferFromIco(_operationalExpensesWallet, RESERVED_TOKENS_OPERATIONAL_EXPENSES);
            token.transferOwnership(msg.sender);
        }
    
         
        function() public payable {
            if (isPreIco()) {
                sellTokensPreIco();
            } else if (isIco()) {
                sellTokensIco();
            } else {
                revert();
            }
        }
    
         
        function isPreIco() public constant returns (bool) {
            bool withinPreIco = now >= startTimePreIco && now <= endTimePreIco;
            return withinPreIco;
        }
    
         
        function isIco() public constant returns (bool) {
            bool withinIco = now >= startTimeIco && now <= endTimeIco;
            return withinIco;
        }
    
         
        function manualRefund() whenIcoSaleHasEnded public {
            require(weiRaisedTotal < mincap);
    
            uint256 weiAmountTotal = investments[msg.sender];
            require(weiAmountTotal > 0);
    
            investments[msg.sender] = 0;
    
            uint256 weiAmountPreIco = investmentsPreIco[msg.sender];
            uint256 weiAmountIco = weiAmountTotal;
    
            if (weiAmountPreIco > 0) {
                investmentsPreIco[msg.sender] = 0;
                weiRaisedPreIco = weiRaisedPreIco.sub(weiAmountPreIco);
                weiAmountIco = weiAmountIco.sub(weiAmountPreIco);
            }
    
            if (weiAmountIco > 0) {
                weiRaisedIco = weiRaisedIco.sub(weiAmountIco);
                uint256 tokensIco = weiAmountIco.mul(exchangeRateIco);
                tokensSoldIco = tokensSoldIco.sub(tokensIco);
            }
    
            weiRaisedTotal = weiRaisedTotal.sub(weiAmountTotal);
    
            uint256 tokensAmount = token.balanceOf(msg.sender);
    
            tokensSoldTotal = tokensSoldTotal.sub(tokensAmount);
    
            token.burnFromAddress(msg.sender);
    
            msg.sender.transfer(weiAmountTotal);
        }
    
         
        function sellTokensPreIco() beforeReachingHardCap whenWhitelisted(msg.sender) whenNotPaused public payable {
            require(isPreIco());
            require(msg.value > 0);
    
            uint256 weiAmount = msg.value;
            uint256 excessiveFunds = 0;
    
            uint256 plannedWeiTotal = weiRaisedTotal.add(weiAmount);
    
            if (plannedWeiTotal > maxcap) {
                excessiveFunds = plannedWeiTotal.sub(maxcap);
                weiAmount = maxcap.sub(weiRaisedTotal);
            }
    
            investments[msg.sender] = investments[msg.sender].add(weiAmount);
    
            weiRaisedPreIco = weiRaisedPreIco.add(weiAmount);
            weiRaisedTotal = weiRaisedTotal.add(weiAmount);
    
            addInvestmentPreIco(msg.sender, weiAmount);
    
            if (excessiveFunds > 0) {
                msg.sender.transfer(excessiveFunds);
            }
        }
    
         
        function sellTokensIco() beforeReachingHardCap whenWhitelisted(msg.sender) whenNotPaused public payable {
            require(isIco());
            require(msg.value > 0);
    
            uint256 weiAmount = msg.value;
            uint256 excessiveFunds = 0;
    
            uint256 plannedWeiTotal = weiRaisedTotal.add(weiAmount);
    
            if (plannedWeiTotal > maxcap) {
                excessiveFunds = plannedWeiTotal.sub(maxcap);
                weiAmount = maxcap.sub(weiRaisedTotal);
            }
    
            uint256 tokensAmount = weiAmount.mul(exchangeRateIco);
    
            if (tokensAmount > tokensRemainingIco) {
                uint256 weiToAccept = tokensRemainingIco.div(exchangeRateIco);
                excessiveFunds = excessiveFunds.add(weiAmount.sub(weiToAccept));
                
                tokensAmount = tokensRemainingIco;
                weiAmount = weiToAccept;
            }
    
            investments[msg.sender] = investments[msg.sender].add(weiAmount);
    
            tokensSoldIco = tokensSoldIco.add(tokensAmount);
            tokensSoldTotal = tokensSoldTotal.add(tokensAmount);
            tokensRemainingIco = tokensRemainingIco.sub(tokensAmount);
    
            weiRaisedIco = weiRaisedIco.add(weiAmount);
            weiRaisedTotal = weiRaisedTotal.add(weiAmount);
    
            token.transferFromIco(msg.sender, tokensAmount);
    
            if (excessiveFunds > 0) {
                msg.sender.transfer(excessiveFunds);
            }
        }
    
         
        function forwardFunds() onlyOwner public {
            require(weiRaisedTotal >= mincap);
            withdrawalWallet.transfer(this.balance);
        }
    
         
        function calcTokenRate() whenPreIcoSaleHasEnded onlyOwner public {
            require(!isTokenRateCalculated);
            require(weiRaisedPreIco > 0);
    
            exchangeRatePreIco = HARDCAP_TOKENS_PRE_ICO.div(weiRaisedPreIco);
    
            exchangeRateIco = exchangeRatePreIco.div(2);
    
            isTokenRateCalculated = true;
        }
    
         
        function distributeTokensPreIco(uint256 _paginationCount) onlyOwner public {
            require(isTokenRateCalculated && !isTokensPreIcoDistributed);
            require(_paginationCount > 0);
    
            uint256 count = 0;
            for (uint256 i = distributionPreIcoCount; i < getPreIcoInvestorsCount(); i++) {
                if (count == _paginationCount) {
                    break;
                }
                uint256 investment = getPreIcoInvestment(getPreIcoInvestor(i));
                uint256 tokensAmount = investment.mul(exchangeRatePreIco);
                
                tokensSoldTotal = tokensSoldTotal.add(tokensAmount);
    
                token.transferFromIco(getPreIcoInvestor(i), tokensAmount);
    
                count++;
            }
    
            distributionPreIcoCount = distributionPreIcoCount.add(count);
    
            if (distributionPreIcoCount == getPreIcoInvestorsCount()) {
                isTokensPreIcoDistributed = true;
            }
        }
    
         
        function burnUnsoldTokens() whenIcoSaleHasEnded onlyOwner public {
            require(tokensRemainingIco > 0);
            token.burnFromIco();
            tokensRemainingIco = 0;
        }
    
         
        function getPreIcoInvestorsCount() constant public returns (uint256) {
            return investorsPreIco.length;
        }
    
         
        function getPreIcoInvestor(uint256 _index) constant public returns (address) {
            return investorsPreIco[_index];
        }
    
         
        function getPreIcoInvestment(address _investorPreIco) constant public returns (uint256) {
            return investmentsPreIco[_investorPreIco];
        }
    
         
        function setStartTimeIco(uint256 _startTimeIco, uint256 _endTimeIco) whenPreIcoSaleHasEnded beforeReachingHardCap onlyOwner public {
            require(_startTimeIco >= now && _endTimeIco > _startTimeIco);
            require(isTokenRateCalculated);
    
            startTimeIco = _startTimeIco;
            endTimeIco = _endTimeIco;
        }
    
         
        function addInvestmentPreIco(address _from, uint256 _value) internal {
            if (investmentsPreIco[_from] == 0) {
                investorsPreIco.push(_from);
            }
            investmentsPreIco[_from] = investmentsPreIco[_from].add(_value);
        }  
    }