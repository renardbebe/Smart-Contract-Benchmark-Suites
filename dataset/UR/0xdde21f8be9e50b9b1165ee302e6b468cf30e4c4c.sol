 

pragma solidity 0.4.15;


 
 
 
library Math {

     
     
    uint public constant ONE =  0x10000000000000000;
    uint public constant LN2 = 0xb17217f7d1cf79ac;
    uint public constant LOG2_E = 0x171547652b82fe177;

     
     
     
     
    function exp(int x)
        public
        constant
        returns (uint)
    {
         
         
        require(x <= 2454971259878909886679);
         
         
        if (x < -818323753292969962227)
            return 0;
         
        x = x * int(ONE) / int(LN2);
         
         
         
        int shift;
        uint z;
        if (x >= 0) {
            shift = x / int(ONE);
            z = uint(x % int(ONE));
        }
        else {
            shift = x / int(ONE) - 1;
            z = ONE - uint(-x % int(ONE));
        }
         
         
         
         
         
         
         
         
         
         
         
         
         
        uint zpow = z;
        uint result = ONE;
        result += 0xb17217f7d1cf79ab * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x3d7f7bff058b1d50 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe35846b82505fc5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x276556df749cee5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x5761ff9e299cc4 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xa184897c363c3 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xffe5fe2c4586 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x162c0223a5c8 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1b5253d395e * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e4cf5158b * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1e8cac735 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1c3bd650 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1816193 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x131496 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe1b7 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x9c7 * zpow / ONE;
        if (shift >= 0) {
            if (result >> (256-shift) > 0)
                return (2**256-1);
            return result << shift;
        }
        else
            return result >> (-shift);
    }

     
     
     
    function ln(uint x)
        public
        constant
        returns (int)
    {
        require(x > 0);
         
        int ilog2 = floorLog2(x);
        int z;
        if (ilog2 < 0)
            z = int(x << uint(-ilog2));
        else
            z = int(x >> uint(ilog2));
         
         
         
         
         
        int term = (z - int(ONE)) * int(ONE) / (z + int(ONE));
        int halflnz = term;
        int termpow = term * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 3;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 5;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 7;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 9;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 11;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 13;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 15;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 17;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 19;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 21;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 23;
        termpow = termpow * term / int(ONE) * term / int(ONE);
        halflnz += termpow / 25;
        return (ilog2 * int(ONE)) * int(ONE) / int(LOG2_E) + 2 * halflnz;
    }

     
     
     
    function floorLog2(uint x)
        public
        constant
        returns (int lo)
    {
        lo = -64;
        int hi = 193;
         
        int mid = (hi + lo) >> 1;
        while((lo + 1) < hi) {
            if (mid < 0 && x << uint(-mid) < ONE || mid >= 0 && x >> uint(mid) < ONE)
                hi = mid;
            else
                lo = mid;
            mid = (hi + lo) >> 1;
        }
    }

     
     
     
    function max(int[] nums)
        public
        constant
        returns (int max)
    {
        require(nums.length > 0);
        max = -2**255;
        for (uint i = 0; i < nums.length; i++)
            if (nums[i] > max)
                max = nums[i];
    }

     
     
     
     
    function safeToAdd(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return a + b >= a;
    }

     
     
     
     
    function safeToSub(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return a >= b;
    }

     
     
     
     
    function safeToMul(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return b == 0 || a * b / b == a;
    }

     
     
     
     
    function add(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToAdd(a, b));
        return a + b;
    }

     
     
     
     
    function sub(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToSub(a, b));
        return a - b;
    }

     
     
     
     
    function mul(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToMul(a, b));
        return a * b;
    }

     
     
     
     
    function safeToAdd(int a, int b)
        public
        constant
        returns (bool)
    {
        return (b >= 0 && a + b >= a) || (b < 0 && a + b < a);
    }

     
     
     
     
    function safeToSub(int a, int b)
        public
        constant
        returns (bool)
    {
        return (b >= 0 && a - b <= a) || (b < 0 && a - b > a);
    }

     
     
     
     
    function safeToMul(int a, int b)
        public
        constant
        returns (bool)
    {
        return (b == 0) || (a * b / b == a);
    }

     
     
     
     
    function add(int a, int b)
        public
        constant
        returns (int)
    {
        require(safeToAdd(a, b));
        return a + b;
    }

     
     
     
     
    function sub(int a, int b)
        public
        constant
        returns (int)
    {
        require(safeToSub(a, b));
        return a - b;
    }

     
     
     
     
    function mul(int a, int b)
        public
        constant
        returns (int)
    {
        require(safeToMul(a, b));
        return a * b;
    }
}

 


 
contract Token {

     
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

     
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    function balanceOf(address owner) public constant returns (uint);
    function allowance(address owner, address spender) public constant returns (uint);
    function totalSupply() public constant returns (uint);
}



 
contract StandardToken is Token {
    using Math for *;

     
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;
    uint totalTokens;

     
     
     
     
     
    function transfer(address to, uint value)
        public
        returns (bool)
    {
        if (   !balances[msg.sender].safeToSub(value)
            || !balances[to].safeToAdd(value))
            return false;
        balances[msg.sender] -= value;
        balances[to] += value;
        Transfer(msg.sender, to, value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint value)
        public
        returns (bool)
    {
        if (   !balances[from].safeToSub(value)
            || !allowances[from][msg.sender].safeToSub(value)
            || !balances[to].safeToAdd(value))
            return false;
        balances[from] -= value;
        allowances[from][msg.sender] -= value;
        balances[to] += value;
        Transfer(from, to, value);
        return true;
    }

     
     
     
     
    function approve(address spender, uint value)
        public
        returns (bool)
    {
        allowances[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

     
     
     
     
    function allowance(address owner, address spender)
        public
        constant
        returns (uint)
    {
        return allowances[owner][spender];
    }

     
     
     
    function balanceOf(address owner)
        public
        constant
        returns (uint)
    {
        return balances[owner];
    }

     
     
    function totalSupply()
        public
        constant
        returns (uint)
    {
        return totalTokens;
    }
}


 
 
contract OutcomeToken is StandardToken {
    using Math for *;

     
    event Issuance(address indexed owner, uint amount);
    event Revocation(address indexed owner, uint amount);

     
    address public eventContract;

     
    modifier isEventContract () {
         
        require(msg.sender == eventContract);
        _;
    }

     
     
    function OutcomeToken()
        public
    {
        eventContract = msg.sender;
    }
    
     
     
     
    function issue(address _for, uint outcomeTokenCount)
        public
        isEventContract
    {
        balances[_for] = balances[_for].add(outcomeTokenCount);
        totalTokens = totalTokens.add(outcomeTokenCount);
        Issuance(_for, outcomeTokenCount);
    }

     
     
     
    function revoke(address _for, uint outcomeTokenCount)
        public
        isEventContract
    {
        balances[_for] = balances[_for].sub(outcomeTokenCount);
        totalTokens = totalTokens.sub(outcomeTokenCount);
        Revocation(_for, outcomeTokenCount);
    }
}



 
contract Oracle {

    function isOutcomeSet() public constant returns (bool);
    function getOutcome() public constant returns (int);
}



 
 
contract Event {

     
    event OutcomeTokenCreation(OutcomeToken outcomeToken, uint8 index);
    event OutcomeTokenSetIssuance(address indexed buyer, uint collateralTokenCount);
    event OutcomeTokenSetRevocation(address indexed seller, uint outcomeTokenCount);
    event OutcomeAssignment(int outcome);
    event WinningsRedemption(address indexed receiver, uint winnings);

     
    Token public collateralToken;
    Oracle public oracle;
    bool public isOutcomeSet;
    int public outcome;
    OutcomeToken[] public outcomeTokens;

     
     
     
     
     
    function Event(Token _collateralToken, Oracle _oracle, uint8 outcomeCount)
        public
    {
         
        require(address(_collateralToken) != 0 && address(_oracle) != 0 && outcomeCount >= 2);
        collateralToken = _collateralToken;
        oracle = _oracle;
         
        for (uint8 i = 0; i < outcomeCount; i++) {
            OutcomeToken outcomeToken = new OutcomeToken();
            outcomeTokens.push(outcomeToken);
            OutcomeTokenCreation(outcomeToken, i);
        }
    }

     
     
    function buyAllOutcomes(uint collateralTokenCount)
        public
    {
         
        require(collateralToken.transferFrom(msg.sender, this, collateralTokenCount));
         
        for (uint8 i = 0; i < outcomeTokens.length; i++)
            outcomeTokens[i].issue(msg.sender, collateralTokenCount);
        OutcomeTokenSetIssuance(msg.sender, collateralTokenCount);
    }

     
     
    function sellAllOutcomes(uint outcomeTokenCount)
        public
    {
         
        for (uint8 i = 0; i < outcomeTokens.length; i++)
            outcomeTokens[i].revoke(msg.sender, outcomeTokenCount);
         
        require(collateralToken.transfer(msg.sender, outcomeTokenCount));
        OutcomeTokenSetRevocation(msg.sender, outcomeTokenCount);
    }

     
    function setOutcome()
        public
    {
         
        require(!isOutcomeSet && oracle.isOutcomeSet());
         
        outcome = oracle.getOutcome();
        isOutcomeSet = true;
        OutcomeAssignment(outcome);
    }

     
     
    function getOutcomeCount()
        public
        constant
        returns (uint8)
    {
        return uint8(outcomeTokens.length);
    }

     
     
    function getOutcomeTokens()
        public
        constant
        returns (OutcomeToken[])
    {
        return outcomeTokens;
    }

     
     
    function getOutcomeTokenDistribution(address owner)
        public
        constant
        returns (uint[] outcomeTokenDistribution)
    {
        outcomeTokenDistribution = new uint[](outcomeTokens.length);
        for (uint8 i = 0; i < outcomeTokenDistribution.length; i++)
            outcomeTokenDistribution[i] = outcomeTokens[i].balanceOf(owner);
    }

     
     
    function getEventHash() public constant returns (bytes32);

     
     
    function redeemWinnings() public returns (uint);
}



 
contract MarketMaker {

     
    function calcCost(Market market, uint8 outcomeTokenIndex, uint outcomeTokenCount) public constant returns (uint);
    function calcProfit(Market market, uint8 outcomeTokenIndex, uint outcomeTokenCount) public constant returns (uint);
    function calcMarginalPrice(Market market, uint8 outcomeTokenIndex) public constant returns (uint);
}



 
contract Market {

     
    event MarketFunding(uint funding);
    event MarketClosing();
    event FeeWithdrawal(uint fees);
    event OutcomeTokenPurchase(address indexed buyer, uint8 outcomeTokenIndex, uint outcomeTokenCount, uint outcomeTokenCost, uint marketFees);
    event OutcomeTokenSale(address indexed seller, uint8 outcomeTokenIndex, uint outcomeTokenCount, uint outcomeTokenProfit, uint marketFees);
    event OutcomeTokenShortSale(address indexed buyer, uint8 outcomeTokenIndex, uint outcomeTokenCount, uint cost);

     
    address public creator;
    uint public createdAtBlock;
    Event public eventContract;
    MarketMaker public marketMaker;
    uint24 public fee;
    uint public funding;
    int[] public netOutcomeTokensSold;
    Stages public stage;

    enum Stages {
        MarketCreated,
        MarketFunded,
        MarketClosed
    }

     
    function fund(uint _funding) public;
    function close() public;
    function withdrawFees() public returns (uint);
    function buy(uint8 outcomeTokenIndex, uint outcomeTokenCount, uint maxCost) public returns (uint);
    function sell(uint8 outcomeTokenIndex, uint outcomeTokenCount, uint minProfit) public returns (uint);
    function shortSell(uint8 outcomeTokenIndex, uint outcomeTokenCount, uint minProfit) public returns (uint);
    function calcMarketFee(uint outcomeTokenCost) public constant returns (uint);
}


 
 
contract StandardMarket is Market {
    using Math for *;

     
    uint24 public constant FEE_RANGE = 1000000;  

     
    modifier isCreator() {
         
        require(msg.sender == creator);
        _;
    }

    modifier atStage(Stages _stage) {
         
        require(stage == _stage);
        _;
    }

     
     
     
     
     
     
    function StandardMarket(address _creator, Event _eventContract, MarketMaker _marketMaker, uint24 _fee)
        public
    {
         
        require(address(_eventContract) != 0 && address(_marketMaker) != 0 && _fee < FEE_RANGE);
        creator = _creator;
        createdAtBlock = block.number;
        eventContract = _eventContract;
        netOutcomeTokensSold = new int[](eventContract.getOutcomeCount());
        fee = _fee;
        marketMaker = _marketMaker;
        stage = Stages.MarketCreated;
    }

     
     
    function fund(uint _funding)
        public
        isCreator
        atStage(Stages.MarketCreated)
    {
         
        require(   eventContract.collateralToken().transferFrom(msg.sender, this, _funding)
                && eventContract.collateralToken().approve(eventContract, _funding));
        eventContract.buyAllOutcomes(_funding);
        funding = _funding;
        stage = Stages.MarketFunded;
        MarketFunding(funding);
    }

     
    function close()
        public
        isCreator
        atStage(Stages.MarketFunded)
    {
        uint8 outcomeCount = eventContract.getOutcomeCount();
        for (uint8 i = 0; i < outcomeCount; i++)
            require(eventContract.outcomeTokens(i).transfer(creator, eventContract.outcomeTokens(i).balanceOf(this)));
        stage = Stages.MarketClosed;
        MarketClosing();
    }

     
     
    function withdrawFees()
        public
        isCreator
        returns (uint fees)
    {
        fees = eventContract.collateralToken().balanceOf(this);
         
        require(eventContract.collateralToken().transfer(creator, fees));
        FeeWithdrawal(fees);
    }

     
     
     
     
     
    function buy(uint8 outcomeTokenIndex, uint outcomeTokenCount, uint maxCost)
        public
        atStage(Stages.MarketFunded)
        returns (uint cost)
    {
         
        uint outcomeTokenCost = marketMaker.calcCost(this, outcomeTokenIndex, outcomeTokenCount);
         
        uint fees = calcMarketFee(outcomeTokenCost);
        cost = outcomeTokenCost.add(fees);
         
        require(cost > 0 && cost <= maxCost);
         
        require(   eventContract.collateralToken().transferFrom(msg.sender, this, cost)
                && eventContract.collateralToken().approve(eventContract, outcomeTokenCost));
         
        eventContract.buyAllOutcomes(outcomeTokenCost);
         
        require(eventContract.outcomeTokens(outcomeTokenIndex).transfer(msg.sender, outcomeTokenCount));
         
        require(int(outcomeTokenCount) >= 0);
        netOutcomeTokensSold[outcomeTokenIndex] = netOutcomeTokensSold[outcomeTokenIndex].add(int(outcomeTokenCount));
        OutcomeTokenPurchase(msg.sender, outcomeTokenIndex, outcomeTokenCount, outcomeTokenCost, fees);
    }

     
     
     
     
     
    function sell(uint8 outcomeTokenIndex, uint outcomeTokenCount, uint minProfit)
        public
        atStage(Stages.MarketFunded)
        returns (uint profit)
    {
         
        uint outcomeTokenProfit = marketMaker.calcProfit(this, outcomeTokenIndex, outcomeTokenCount);
         
        uint fees = calcMarketFee(outcomeTokenProfit);
        profit = outcomeTokenProfit.sub(fees);
         
        require(profit > 0 && profit >= minProfit);
         
        require(eventContract.outcomeTokens(outcomeTokenIndex).transferFrom(msg.sender, this, outcomeTokenCount));
         
        eventContract.sellAllOutcomes(outcomeTokenProfit);
         
        require(eventContract.collateralToken().transfer(msg.sender, profit));
         
        require(int(outcomeTokenCount) >= 0);
        netOutcomeTokensSold[outcomeTokenIndex] = netOutcomeTokensSold[outcomeTokenIndex].sub(int(outcomeTokenCount));
        OutcomeTokenSale(msg.sender, outcomeTokenIndex, outcomeTokenCount, outcomeTokenProfit, fees);
    }

     
     
     
     
     
     
    function shortSell(uint8 outcomeTokenIndex, uint outcomeTokenCount, uint minProfit)
        public
        returns (uint cost)
    {
         
        require(   eventContract.collateralToken().transferFrom(msg.sender, this, outcomeTokenCount)
                && eventContract.collateralToken().approve(eventContract, outcomeTokenCount));
        eventContract.buyAllOutcomes(outcomeTokenCount);
         
        eventContract.outcomeTokens(outcomeTokenIndex).approve(this, outcomeTokenCount);
        uint profit = this.sell(outcomeTokenIndex, outcomeTokenCount, minProfit);
        cost = outcomeTokenCount - profit;
         
        uint8 outcomeCount = eventContract.getOutcomeCount();
        for (uint8 i = 0; i < outcomeCount; i++)
            if (i != outcomeTokenIndex)
                require(eventContract.outcomeTokens(i).transfer(msg.sender, outcomeTokenCount));
         
        require(eventContract.collateralToken().transfer(msg.sender, profit));
        OutcomeTokenShortSale(msg.sender, outcomeTokenIndex, outcomeTokenCount, cost);
    }

     
     
     
    function calcMarketFee(uint outcomeTokenCost)
        public
        constant
        returns (uint)
    {
        return outcomeTokenCost * fee / FEE_RANGE;
    }
}



 
 
contract StandardMarketFactory {

     
    event StandardMarketCreation(address indexed creator, Market market, Event eventContract, MarketMaker marketMaker, uint24 fee);

     
     
     
     
     
     
    function createMarket(Event eventContract, MarketMaker marketMaker, uint24 fee)
        public
        returns (StandardMarket market)
    {
        market = new StandardMarket(msg.sender, eventContract, marketMaker, fee);
        StandardMarketCreation(msg.sender, market, eventContract, marketMaker, fee);
    }
}