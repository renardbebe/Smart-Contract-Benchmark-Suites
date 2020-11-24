 

pragma solidity ^0.4.24;

 

 

contract F2m{
    using SafeMath for *;

    modifier onlyTokenHolders() {
        require(balances[msg.sender] > 0, "not own any token");
        _;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == devTeam, "admin required");
        _;
    }

    modifier withdrawRight(){
        require((msg.sender == address(bankContract)), "Bank Only");
        _;
    }

    modifier swapNotActived() {
        require(swapActived == false, "swap actived, stop minting new tokens");
        _;
    }

    modifier buyable() {
        require(buyActived == true, "token sale not ready");
        _;
    }

     
     
     
     
    
       
     
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
     
    uint256 public totalSupply;  
    string public name;  
    string public symbol;  
    uint32 public decimals;
    uint256 public unitRate;
     
    mapping(address => uint256) balances;
 
     
    mapping(address => mapping (address => uint256)) allowed;
    
    
    CitizenInterface public citizenContract;
    LotteryInterface public lotteryContract;
    BankInterface public bankContract;
    NewTokenInterface public newTokenContract;
    WhitelistInterface public whitelistContract;

    uint256 constant public ONE_HOUR= 3600;
    uint256 constant public ONE_DAY = 24 * ONE_HOUR;  
     
     
    uint256 constant public BEFORE_SLEEP_DURAION = 30 * ONE_DAY;

    uint256 public HARD_TOTAL_SUPPLY = 8000000;

    uint256 public refPercent = 15;
    uint256 public divPercent = 10;
    uint256 public fundPercent = 2;
     

     
    uint256 public startPrice = 0.0014 ether;
     
    uint256 constant public BEP = 30;

     
    mapping(address => int256) public credit;
    mapping(address => uint256) public withdrawnAmount;
    mapping(address => uint256) public fromSellingAmount;

    mapping(address => uint256) public lastActiveDay;
    mapping(address => int256) public todayCredit;

    mapping(address => uint256) public pInvestedSum;

    uint256 public investedAmount;
    uint256 public totalBuyVolume;
    uint256 public totalSellVolume;
    uint256 public totalDividends;
    mapping(uint256 => uint256) public totalDividendsByRound;

     
    uint256 public pps = 0;

     
    mapping(uint256 => uint256) rPps;
    mapping(address => mapping (uint256 => int256)) rCredit; 

     
    uint256 public deployedDay;

     
    bool public autoBuy = false;

    bool public round0 = false;  

     
    mapping(uint256 => uint256) public ppsInDay;  
    mapping(uint256 => uint256) public divInDay;
    mapping(uint256 => uint256) public totalBuyVolumeInDay;
    mapping(uint256 => uint256) public totalSellVolumeInDay;

    address public devTeam;  

    uint256 public swapTime;
    bool public swapActived = false;
    bool public buyActived = false;

     
    constructor (address _devTeam)
        public
    {
        symbol = "F2M2";  
        name = "Fomo2Moon2";  
        decimals = 10;
        unitRate = 10**uint256(decimals);
        HARD_TOTAL_SUPPLY = HARD_TOTAL_SUPPLY * unitRate;
        DevTeamInterface(_devTeam).setF2mAddress(address(this));
        devTeam = _devTeam;
         
        uint256 _amount = 500000 * unitRate;
        totalSupply += _amount;
        balances[devTeam] = _amount;
        emit Transfer(0x0, devTeam, _amount);
        deployedDay = getToday();
    }

     
     
     
     
     
     
     
     
     
     
     

     
    function joinNetwork(address[6] _contract)
        public
    {
        require(address(citizenContract) == 0x0, "already setup");
        bankContract = BankInterface(_contract[1]);
        citizenContract = CitizenInterface(_contract[2]);
        lotteryContract = LotteryInterface(_contract[3]);
        whitelistContract = WhitelistInterface(_contract[5]);
    }
 
    function()
        public
        payable
    {
         
    }

     
 

    function activeBuy()
        public
        onlyAdmin()
    {
        require(buyActived == false, "already actived");
        buyActived = true;
        deployedDay = getToday();
    }

     
    function pushDividends() 
        public 
        payable 
    {
         
        uint256 ethAmount = msg.value;
        uint256 dividends = ethAmount * divPercent / (divPercent + fundPercent);
        uint256 fund = ethAmount.sub(dividends);
        uint256 _buyPrice = getBuyPrice();
         
        distributeTax(msg.sender, fund, dividends, 0);
        if (autoBuy) devTeamAutoBuy(0, _buyPrice);
    }

    function addFund(uint256 _fund)
        private
    {
        credit[devTeam] = credit[devTeam].sub(int256(_fund));
    }

    function addDividends(uint256 _dividends)
        private
    {
        if (_dividends == 0) return;
        totalDividends += _dividends;
        uint256 today = getToday();
        divInDay[today] = _dividends.add(divInDay[today]);

        if (totalSupply == 0) {
            addFund(_dividends);
        } else {
             
             
            addFund(_dividends % totalSupply);
            uint256 deltaShare = _dividends / totalSupply;
            pps = pps.add(deltaShare);

             
            uint256 curRoundId = getCurRoundId();
            rPps[curRoundId] += deltaShare;
            totalDividendsByRound[curRoundId] += _dividends;
            ppsInDay[today] = deltaShare + ppsInDay[today];
        }
    }

    function addToRef(address _sender, uint256 _toRef)
        private
    {
        if (_toRef == 0) return;
        citizenContract.pushRefIncome.value(_toRef)(_sender);
    }

 

 

    function distributeTax(
        address _sender,
        uint256 _fund,
        uint256 _dividends,
        uint256 _toRef)
         
        private
    {
        addFund(_fund);
        addDividends(_dividends);
        addToRef(_sender, _toRef);
         
    }

    function updateCredit(address _owner, uint256 _currentEthAmount, uint256 _rDividends, uint256 _todayDividends) 
        private 
    {
         
         
        uint256 curRoundId = getCurRoundId();
        credit[_owner] = int256(pps.mul(balances[_owner])).sub(int256(_currentEthAmount));
         
        rCredit[_owner][curRoundId] = int256(rPps[curRoundId] * balances[_owner]) - int256(_rDividends);
        todayCredit[_owner] = int256(ppsInDay[getToday()] * balances[_owner]) - int256(_todayDividends);
    }

    function mintToken(address _buyer, uint256 _taxedAmount, uint256 _buyPrice) 
        private 
        swapNotActived()
        buyable()
        returns(uint256) 
    {
        uint256 revTokens = ethToToken(_taxedAmount, _buyPrice);
        investedAmount = investedAmount.add(_taxedAmount);
         
         
        if (revTokens + totalSupply > HARD_TOTAL_SUPPLY) 
            revTokens = HARD_TOTAL_SUPPLY.sub(totalSupply);
        balances[_buyer] = balances[_buyer].add(revTokens);
        totalSupply = totalSupply.add(revTokens);
        emit Transfer(0x0, _buyer, revTokens);
        return revTokens;
    }

    function burnToken(address _seller, uint256 _tokenAmount) 
        private 
        returns (uint256) 
    {
        require(balances[_seller] >= _tokenAmount, "not enough to burn");
        uint256 revEthAmount = tokenToEth(_tokenAmount);
        investedAmount = investedAmount.sub(revEthAmount);
        balances[_seller] = balances[_seller].sub(_tokenAmount);
        totalSupply = totalSupply.sub(_tokenAmount);
        emit Transfer(_seller, 0x0, _tokenAmount);
        return revEthAmount;
    }

    function devTeamAutoBuy(uint256 _reserved, uint256 _buyPrice)
        private
    {
        uint256 _refClaim = citizenContract.devTeamReinvest();
        credit[devTeam] -= int256(_refClaim);
        uint256 _ethAmount = ethBalance(devTeam);
        if ((_ethAmount + _reserved) / _buyPrice + totalSupply > HARD_TOTAL_SUPPLY) return;

        uint256 _rDividends = getRDividends(devTeam);
        uint256 _todayDividends = getTodayDividendsByAddress(devTeam);
        mintToken(devTeam, _ethAmount, _buyPrice);
        updateCredit(devTeam, 0, _rDividends, _todayDividends);
    }

    function buy()
        public
        payable
    {
        address _buyer = msg.sender;
        buyFor(_buyer);
    }

 

    function buyFor(address _buyer) 
        public 
        payable
    {
         
         
        updateLastActive(_buyer);
        uint256 _buyPrice = getBuyPrice();
        uint256 ethAmount = msg.value;
        pInvestedSum[_buyer] += ethAmount;
         
        uint256 onePercent = ethAmount / 100;
        uint256 fund = onePercent.mul(fundPercent);
        uint256 dividends = onePercent.mul(divPercent);
        uint256 toRef = onePercent.mul(refPercent);
         
         
        uint256 tax = fund + dividends + toRef;
        uint256 taxedAmount = ethAmount.sub(tax);
        
        totalBuyVolume = totalBuyVolume + ethAmount;
        totalBuyVolumeInDay[getToday()] += ethAmount;

         
        distributeTax(_buyer, fund, dividends, toRef);
        if (autoBuy) devTeamAutoBuy(taxedAmount, _buyPrice);

        uint256 curEthBalance = ethBalance(_buyer);
        uint256 _rDividends = getRDividends(_buyer);
        uint256 _todayDividends = getTodayDividendsByAddress(_buyer);

        mintToken(_buyer, taxedAmount, _buyPrice);
        updateCredit(_buyer, curEthBalance, _rDividends, _todayDividends);
    }

    function sell(uint256 _tokenAmount)
        public
        onlyTokenHolders()
    {
         
        updateLastActive(msg.sender);
        address seller = msg.sender;
        uint256 curEthBalance = ethBalance(seller);
        uint256 _rDividends = getRDividends(seller);
        uint256 _todayDividends = getTodayDividendsByAddress(seller);

        uint256 ethAmount = burnToken(seller, _tokenAmount);
        uint256 fund = ethAmount.mul(fundPercent) / 100;
        uint256 taxedAmount = ethAmount.sub(fund);

        totalSellVolume = totalSellVolume + ethAmount;
        totalSellVolumeInDay[getToday()] += ethAmount;
        curEthBalance = curEthBalance.add(taxedAmount);
        fromSellingAmount[seller] += taxedAmount;
        
        updateCredit(seller, curEthBalance, _rDividends, _todayDividends);
         
        distributeTax(msg.sender, fund, 0, 0);
    }

    function devTeamWithdraw()
        public
        returns(uint256)
    {
        address sender = msg.sender;
        require(sender == devTeam, "dev. Team only");
        uint256 amount = ethBalance(sender);
        if (amount == 0) return 0;
        credit[sender] += int256(amount);
        withdrawnAmount[sender] = amount.add(withdrawnAmount[sender]);
        devTeam.transfer(amount);
        return amount;
    }

    function withdrawFor(address sender)
        public
        withdrawRight()
        returns(uint256)
    {
        uint256 amount = ethBalance(sender);
        if (amount == 0) return 0;
        credit[sender] = credit[sender].add(int256(amount));
        withdrawnAmount[sender] = amount.add(withdrawnAmount[sender]);
        bankContract.pushToBank.value(amount)(sender);
        return amount;
    }

    function updateAllowed(address _from, address _to, uint256 _tokenAmount)
        private
    {
        require(balances[_from] >= _tokenAmount, "not enough to transfer");
        if (_from != msg.sender)
        allowed[_from][_to] = allowed[_from][_to].sub(_tokenAmount);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenAmount)
        public
        returns(bool)
    {   
        updateAllowed(_from, _to, _tokenAmount);
        updateLastActive(_from);
        updateLastActive(_to);

        uint256 curEthBalance_from = ethBalance(_from);
        uint256 _rDividends_from = getRDividends(_from);
        uint256 _todayDividends_from = getTodayDividendsByAddress(_from);

        uint256 curEthBalance_to = ethBalance(_to);
        uint256 _rDividends_to = getRDividends(_to);
        uint256 _todayDividends_to = getTodayDividendsByAddress(_to);

        uint256 taxedTokenAmount = _tokenAmount;
        balances[_from] -= taxedTokenAmount;
        balances[_to] += taxedTokenAmount;
        updateCredit(_from, curEthBalance_from, _rDividends_from, _todayDividends_from);
        updateCredit(_to, curEthBalance_to, _rDividends_to, _todayDividends_to);
         
        emit Transfer(_from, _to, taxedTokenAmount);
        
        return true;
    }

    function transfer(address _to, uint256 _tokenAmount)
        public 
        returns (bool) 
    {
        transferFrom(msg.sender, _to, _tokenAmount);
        return true;
    }

    function approve(address spender, uint tokens) 
        public 
        returns (bool success) 
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function updateLastActive(address _sender) 
        private
    {
        if (lastActiveDay[_sender] != getToday()) {
            lastActiveDay[_sender] = getToday();
            todayCredit[_sender] = 0;
        }
    }
    
     

    function setAutoBuy() 
        public
        onlyAdmin()
    {
        autoBuy = !autoBuy;
    }

     
    function totalEthBalance()
        public
        view
        returns(uint256)
    {
        return address(this).balance;
    }
    
    function ethBalance(address _address)
        public
        view
        returns(uint256)
    {
        return (uint256) ((int256)(pps.mul(balances[_address])).sub(credit[_address]));
    }

    function getTotalDividendsByAddress(address _invester)
        public
        view
        returns(uint256)
    {
        return (ethBalance(_invester)) + (withdrawnAmount[_invester]) - (fromSellingAmount[_invester]);
    }

    function getTodayDividendsByAddress(address _invester)
        public
        view
        returns(uint256)
    {
        int256 _todayCredit = (getToday() == lastActiveDay[_invester]) ? todayCredit[_invester] : 0;
        return (uint256) ((int256)(ppsInDay[getToday()] * balances[_invester]) - _todayCredit);
    }
    
     

     
    function getSellPrice() 
        public 
        view 
        returns(uint256)
    {
        if (totalSupply == 0) {
            return 0;
        } else {
            return investedAmount / totalSupply;
        }
    }

    function getSellPriceAfterTax() 
        public 
        view 
        returns(uint256)
    {
        uint256 _sellPrice = getSellPrice();
        uint256 taxPercent = fundPercent;
        return _sellPrice * (100 - taxPercent) / 100;
    }
    
     
    function getBuyPrice() 
        public 
        view 
        returns(uint256)
    {
         
         
        uint256 taxPercent = fundPercent + divPercent + refPercent;
         
        uint256 avgPps = getAvgPps();
        uint256 _sellPrice = getSellPrice();
        uint256 _buyPrice = (startPrice / unitRate + avgPps * BEP * HARD_TOTAL_SUPPLY / (HARD_TOTAL_SUPPLY + unitRate - totalSupply)) * (100 - taxPercent) / 100;
        uint256 _min = _sellPrice * 14 / 10;
        if (_buyPrice < _min) return _min;
        return _buyPrice;
    }

    function getBuyPriceAfterTax()
        public 
        view 
        returns(uint256)
    {
         
        uint256 _buyPrice = getBuyPrice();
         
        uint256 taxPercent = fundPercent + divPercent + refPercent;
        return _buyPrice * 100 / (100 - taxPercent);
    }

    function ethToToken(uint256 _ethAmount, uint256 _buyPrice)
        public
        view
        returns(uint256)
    {
         
         
        uint256 revToken = _ethAmount / _buyPrice;
 
        return revToken;
    }
    
    function tokenToEth(uint256 _tokenAmount)
        public
        view
        returns(uint256)
    {
        uint256 sellPrice = getSellPrice();
        return _tokenAmount.mul(sellPrice);
    }
    
    function getToday() 
        public 
        view 
        returns (uint256) 
    {
        return (block.timestamp / ONE_DAY);
    }

     
    function getAvgPps() 
        public 
        view 
        returns (uint256) 
    {
        uint256 divSum = 0;
        uint256 _today = getToday();
        uint256 _fromDay = _today - 6;
        if (_fromDay < deployedDay) _fromDay = deployedDay;
        for (uint256 i = _fromDay; i <= _today; i++) {
            divSum = divSum.add(divInDay[i]);
        }
        if (totalSupply == 0) return 0;
        return divSum / (_today + 1 - _fromDay) / totalSupply;
    }

    function getTotalVolume() 
        public
        view
        returns(uint256)
    {
        return totalBuyVolume + totalSellVolume;
    }

    function getWeeklyBuyVolume() 
        public
        view
        returns(uint256)
    {
        uint256 _total = 0;
        uint256 _today = getToday();
        for (uint256 i = _today; i + 7 > _today; i--) {
            _total = _total + totalBuyVolumeInDay[i];
        }
        return _total;
    }

    function getWeeklySellVolume() 
        public
        view
        returns(uint256)
    {
        uint256 _total = 0;
        uint256 _today = getToday();
        for (uint256 i = _today; i + 7 > _today; i--) {
            _total = _total + totalSellVolumeInDay[i];
        }
        return _total;
    }

    function getWeeklyVolume()
        public
        view
        returns(uint256)
    {
        return getWeeklyBuyVolume() + getWeeklySellVolume();
    }

    function getTotalDividends()
        public
        view
        returns(uint256)
    {
        return totalDividends;
    }

    function getRDividends(address _invester)
        public
        view
        returns(uint256)
    {
        uint256 curRoundId = getCurRoundId();
        return uint256(int256(rPps[curRoundId] * balances[_invester]) - rCredit[_invester][curRoundId]);
    }

    function getWeeklyDividends()
        public
        view
        returns(uint256)
    {
        uint256 divSum = 0;
        uint256 _today = getToday();
        uint256 _fromDay = _today - 6;
        if (_fromDay < deployedDay) _fromDay = deployedDay;
        for (uint256 i = _fromDay; i <= _today; i++) {
            divSum = divSum.add(divInDay[i]);
        }
        
        return divSum;
    }

    function getMarketCap()
        public
        view
        returns(uint256)
    {
        return totalSupply.mul(getBuyPriceAfterTax());
    }

    function totalSupply()
        public
        view
        returns(uint)
    {
        return totalSupply;
    }

    function balanceOf(address tokenOwner)
        public
        view
        returns(uint256)
    {
        return balances[tokenOwner];
    }

    function myBalance() 
        public 
        view 
        returns(uint256)
    {
        return balances[msg.sender];
    }

    function myEthBalance() 
        public 
        view 
        returns(uint256) 
    {
        return ethBalance(msg.sender);
    }

    function myCredit() 
        public 
        view 
        returns(int256) 
    {
        return credit[msg.sender];
    }

 
     

    function getCurRoundId()
        public
        view
        returns(uint256)
    {
        return lotteryContract.getCurRoundId();
    }

     
    function swapToken()
        public
        onlyTokenHolders()
    {
        require(swapActived, "swap not actived");
        address _invester = msg.sender;
        uint256 _tokenAmount = balances[_invester];
        uint256 _ethAmount = ethBalance(_invester);
         
        _ethAmount += burnToken(_invester, _tokenAmount);
        updateCredit(_invester, 0, 0, 0);
         
        newTokenContract.swapToken.value(_ethAmount)(_tokenAmount, _invester);
    }

     
    function setNewToken(address _newTokenAddress)
        public
        onlyAdmin()
    {
        bool _isLastRound = lotteryContract.isLastRound();
        require(_isLastRound, "too early");
        require(swapActived == false, "already set");
        swapTime = block.timestamp;
        swapActived = true;
        newTokenContract = NewTokenInterface(_newTokenAddress);
        autoBuy = false;
    }

     
    function sleep()
        public
    {
        require(swapActived, "swap not actived");
        require(swapTime + BEFORE_SLEEP_DURAION < block.timestamp, "too early");
        uint256 _ethAmount = address(this).balance;
        devTeam.transfer(_ethAmount);
         
    }
}

 
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface CitizenInterface {
 
    function joinNetwork(address[6] _contract) public;
     
    function devTeamWithdraw() public;

     
    function updateUsername(string _sNewUsername) public;
     
    function pushRefIncome(address _sender) public payable;
    function withdrawFor(address _sender) public payable returns(uint256);
    function devTeamReinvest() public returns(uint256);

     
    function getRefWallet(address _address) public view returns(uint256);
}

interface LotteryInterface {
    function joinNetwork(address[6] _contract) public;
     
    function activeFirstRound() public;
     
    function pushToPot() public payable;
    function finalizeable() public view returns(bool);
     
    function finalize() public;
    function buy(string _sSalt) public payable;
    function buyFor(string _sSalt, address _sender) public payable;
     
    function withdrawFor(address _sender) public returns(uint256);

    function getRewardBalance(address _buyer) public view returns(uint256);
    function getTotalPot() public view returns(uint256);
     
    function getEarlyIncomeByAddress(address _buyer) public view returns(uint256);
     
    function getCurEarlyIncomeByAddress(address _buyer) public view returns(uint256);
    function getCurRoundId() public view returns(uint256);
     
    function setLastRound(uint256 _lastRoundId) public;
    function getPInvestedSumByRound(uint256 _rId, address _buyer) public view returns(uint256);
    function cashoutable(address _address) public view returns(bool);
    function isLastRound() public view returns(bool);
    function sBountyClaim(address _sBountyHunter) public returns(uint256);
}

interface DevTeamInterface {
    function setF2mAddress(address _address) public;
    function setLotteryAddress(address _address) public;
    function setCitizenAddress(address _address) public;
    function setBankAddress(address _address) public;
    function setRewardAddress(address _address) public;
    function setWhitelistAddress(address _address) public;

    function setupNetwork() public;
}

interface BankInterface {
    function joinNetwork(address[6] _contract) public;
    function pushToBank(address _player) public payable;
}

interface NewTokenInterface {
    function swapToken(uint256 _amount, address _invester) public payable;
}

interface WhitelistInterface {
    function joinNetwork(address[6] _contract) public;
     
}