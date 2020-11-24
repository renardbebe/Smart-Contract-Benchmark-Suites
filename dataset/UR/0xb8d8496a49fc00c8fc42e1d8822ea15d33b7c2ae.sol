 

 
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) 
    internal 
    pure
    returns (uint256) 
    {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) 
    internal 
    pure
    returns (uint256) 
    {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) 
    internal 
    pure
    returns (uint256) 
    {
        require(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) 
    internal 
    pure
    returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}



 
 
contract Token {
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function balanceOf(address owner) public constant returns (uint256);
    function allowance(address owner, address spender) public constant returns (uint256);
    uint256 public totalSupply;
}


 
contract StandardToken is Token {
  using SafeMath for uint256;
     
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;
    uint256 public totalSupply;

     
     
     
     
     
    function transfer(address to, uint256 value)
        public
        returns (bool)
    {
        require(to != address(0));
        require(value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool)
    {
         
         
         
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowances[from][msg.sender]);
        balances[to] = balances[to].add(value);
        balances[from] = balances[from].sub(value);
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

     
     
     
     
    function approve(address _spender, uint256 value)
        public
        returns (bool success)
    {
        require((value == 0) || (allowances[msg.sender][_spender] == 0));
        allowances[msg.sender][_spender] = value;
        Approval(msg.sender, _spender, value);
        return true;
    }

  
    function increaseApproval(address _spender, uint _addedValue)
        public
        returns (bool)
    {
        allowances[msg.sender][_spender] = allowances[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue)
        public
        returns (bool) 
    {
        uint oldValue = allowances[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowances[msg.sender][_spender] = 0;
        } else {
            allowances[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint256)
    {
        return allowances[_owner][_spender];
    }

     
     
     
    function balanceOf(address _owner)
        public
        constant
        returns (uint256)
    {
        return balances[_owner];
    }
}


contract Balehubuck is StandardToken {
    using SafeMath for uint256;
     
    string public constant name = "balehubuck";
    string public constant symbol = "BUX";
    uint8 public constant decimals = 18;
    uint256 public constant TOTAL_SUPPLY = 1000000000 * 10**18;
     
     
     
    uint256 public constant TOKEN_SALE_ALLOCATION = 199125000 * 10**18;
    uint256 public constant WALLET_ALLOCATION = 800875000 * 10**18;

    function Balehubuck(address wallet)
        public
    {
        totalSupply = TOTAL_SUPPLY;
        balances[msg.sender] = TOKEN_SALE_ALLOCATION;
        balances[wallet] = WALLET_ALLOCATION;
         
        require(TOKEN_SALE_ALLOCATION + WALLET_ALLOCATION == TOTAL_SUPPLY);
    }
}


contract TokenSale {
    using SafeMath for uint256;
     
    event PresaleStart(uint256 indexed presaleStartTime);
    event AllocatePresale(address indexed receiver, uint256 tokenQuantity);
    event PresaleEnd(uint256 indexed presaleEndTime);
    event MainSaleStart(uint256 indexed startMainSaleTime);
    event AllocateMainSale(address indexed receiver, uint256 etherAmount);
    event MainSaleEnd(uint256 indexed endMainSaleTime);
    event TradingStart(uint256 indexed startTradingTime);
    event Refund(address indexed receiver, uint256 etherAmount);

     
     
    uint256 public constant PRESALE_TOKEN_ALLOCATION = 11625000 * 10**18;
    uint256 public constant PRESALE_MAX_RAISE = 3000 * 10**18;

     
    mapping (address => uint256) public presaleAllocations;
    mapping (address => uint256) public mainSaleAllocations;
    address public wallet;
    Balehubuck public token;
    uint256 public presaleEndTime;
    uint256 public mainSaleEndTime;
    uint256 public minTradingStartTime;
    uint256 public maxTradingStartTime;
    uint256 public totalReceived;
    uint256 public minimumMainSaleRaise;
    uint256 public maximumMainSaleRaise;
    uint256 public maximumAllocationPerParticipant;
    uint256 public mainSaleExchangeRate;
    Stages public stage;

    enum Stages {
        Deployed,
        PresaleStarted,
        PresaleEnded,
        MainSaleStarted,
        MainSaleEnded,
        Refund,
        Trading
    }

     
    modifier onlyWallet() {
        require(wallet == msg.sender);
        _;
    }

    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

     
    function ()
        external
        payable
    {
        buy(msg.sender);
    }

     
     
     
    function TokenSale(address _wallet)
        public
    {
        require(_wallet != 0x0);
        wallet = _wallet;
        token = new Balehubuck(wallet);
         
        minimumMainSaleRaise = 23000 * 10**18;
        maximumMainSaleRaise = 78000 * 10**18;
        maximumAllocationPerParticipant = 750 * 10**18;
        mainSaleExchangeRate = 2500;
        stage = Stages.Deployed;
        totalReceived = 0;
    }

     
     
     
    function buy(address _receiver)
        public
        payable
    {
        require(msg.value > 0);
        address receiver = _receiver;
        if (receiver == 0x0)
            receiver = msg.sender;
        if (stage == Stages.PresaleStarted) {
            buyPresale(receiver);
        } else if (stage == Stages.MainSaleStarted) {
            buyMainSale(receiver);
        } else {
            revert();
        }
    }

     
     
    function startPresale()
        external
        onlyWallet
        atStage(Stages.Deployed)
    {
        stage = Stages.PresaleStarted;
        presaleEndTime = now + 8 weeks;
        PresaleStart(now);
    }

     
     
     
     
     
    function changeSettings(uint256 _minimumMainSaleRaise,
                            uint256 _maximumMainSaleRaise,
                            uint256 _maximumAllocationPerParticipant,
                            uint256 _mainSaleExchangeRate)
        external
        onlyWallet
        atStage(Stages.PresaleEnded)
    {
         
        require(_minimumMainSaleRaise > 0 &&
                _maximumMainSaleRaise > 0 &&
                _maximumAllocationPerParticipant > 0 &&
                _mainSaleExchangeRate > 0);
         
        require(_minimumMainSaleRaise < _maximumMainSaleRaise);
         
         
        require(_maximumMainSaleRaise.sub(PRESALE_MAX_RAISE).mul(_mainSaleExchangeRate) <= token.balanceOf(this).sub(PRESALE_TOKEN_ALLOCATION));
        minimumMainSaleRaise = _minimumMainSaleRaise;
        maximumMainSaleRaise = _maximumMainSaleRaise;
        mainSaleExchangeRate = _mainSaleExchangeRate;
        maximumAllocationPerParticipant = _maximumAllocationPerParticipant;
    }

     
     
    function startMainSale()
        external
        onlyWallet
        atStage(Stages.PresaleEnded)
    {
        stage = Stages.MainSaleStarted;
        mainSaleEndTime = now + 8 weeks;
        MainSaleStart(now);
    }

     
    function startTrading()
        external
        atStage(Stages.MainSaleEnded)
    {
         
         
        require((msg.sender == wallet && now >= minTradingStartTime) || now >= maxTradingStartTime);
        stage = Stages.Trading;
        TradingStart(now);
    }

     
    function refund() 
        external
        atStage(Stages.Refund)
    {
        uint256 amount = mainSaleAllocations[msg.sender];
        mainSaleAllocations[msg.sender] = 0;
        msg.sender.transfer(amount);
        Refund(msg.sender, amount);
    }

     
    function claimTokens()
        external
        atStage(Stages.Trading)
    {
        uint256 tokenAllocation = presaleAllocations[msg.sender].add(mainSaleAllocations[msg.sender].mul(mainSaleExchangeRate));
        presaleAllocations[msg.sender] = 0;
        mainSaleAllocations[msg.sender] = 0;
        token.transfer(msg.sender, tokenAllocation);
    }

     
     
     
    function buyPresale(address receiver)
        private
    {
        if (now >= presaleEndTime) {
            endPresale();
            return;
        }
        uint256 totalTokenAllocation = 0;
        uint256 oldTotalReceived = totalReceived;
        uint256 tokenAllocation = 0;
        uint256 weiUsing = 0;
        uint256 weiAmount = msg.value;
        uint256 maxWeiForPresaleStage = 0;
        uint256 buyerRefund = 0;
         
         
         
        while (true) {
             
             
             
             
            maxWeiForPresaleStage = (totalReceived.add(500 * 10**18).div(500 * 10**18).mul(500 * 10**18)).sub(totalReceived);
            if (weiAmount > maxWeiForPresaleStage) {
                weiUsing = maxWeiForPresaleStage;
            } else {
                weiUsing = weiAmount;
            }
            weiAmount = weiAmount.sub(weiUsing);
            if (totalReceived < 500 * 10**18) {
             
                tokenAllocation = calcpresaleAllocations(weiUsing, 5000);
            } else if (totalReceived < 1000 * 10**18) {
             
                tokenAllocation = calcpresaleAllocations(weiUsing, 4500);
            } else if (totalReceived < 1500 * 10**18) {
             
                tokenAllocation = calcpresaleAllocations(weiUsing, 4000);
            } else if (totalReceived < 2000 * 10**18) {
             
                tokenAllocation = calcpresaleAllocations(weiUsing, 3500);
            } else if (totalReceived < 2500 * 10**18) {
             
                tokenAllocation = calcpresaleAllocations(weiUsing, 3250);
            } else if (totalReceived < 3000 * 10**18) {
             
                tokenAllocation = calcpresaleAllocations(weiUsing, 3000);
            } 
            totalTokenAllocation = totalTokenAllocation.add(tokenAllocation);
            totalReceived = totalReceived.add(weiUsing);
            if (totalReceived >= PRESALE_MAX_RAISE) {
                    buyerRefund = weiAmount;
                    endPresale();
            }
             
             
            if (weiAmount == 0 || stage != Stages.PresaleStarted)
                break;
        }
        presaleAllocations[receiver] = presaleAllocations[receiver].add(totalTokenAllocation);
        wallet.transfer(totalReceived.sub(oldTotalReceived));
        msg.sender.transfer(buyerRefund);
        AllocatePresale(receiver, totalTokenAllocation);
    }

     
     
    function buyMainSale(address receiver)
        private
    {
        if (now >= mainSaleEndTime) {
            endMainSale(msg.value);
            msg.sender.transfer(msg.value);
            return;
        }
        uint256 buyerRefund = 0;
        uint256 weiAllocation = mainSaleAllocations[receiver].add(msg.value);
        if (weiAllocation >= maximumAllocationPerParticipant) {
            weiAllocation = maximumAllocationPerParticipant.sub(mainSaleAllocations[receiver]);
            buyerRefund = msg.value.sub(weiAllocation);
        }
        uint256 potentialReceived = totalReceived.add(weiAllocation);
        if (potentialReceived > maximumMainSaleRaise) {
            weiAllocation = maximumMainSaleRaise.sub(totalReceived);
            buyerRefund = buyerRefund.add(potentialReceived.sub(maximumMainSaleRaise));
            endMainSale(buyerRefund);
        }
        totalReceived = totalReceived.add(weiAllocation);
        mainSaleAllocations[receiver] = mainSaleAllocations[receiver].add(weiAllocation);
        msg.sender.transfer(buyerRefund);
        AllocateMainSale(receiver, weiAllocation);
    }

     
     
     
    function calcpresaleAllocations(uint256 weiUsing, uint256 rate)
        private
        pure
        returns (uint256)
    {
        return weiUsing.mul(rate);
    }

     
    function endPresale()
        private
    {
        stage = Stages.PresaleEnded;
        PresaleEnd(now);
    }

     
     
    function endMainSale(uint256 buyerRefund)
        private
    {
        if (totalReceived < minimumMainSaleRaise) {
            stage = Stages.Refund;
        } else {
            minTradingStartTime = now + 2 weeks;
            maxTradingStartTime = now + 8 weeks;
            stage = Stages.MainSaleEnded;
             
            wallet.transfer(this.balance.sub(buyerRefund));
             
             
        }
        MainSaleEnd(now);
    }
}