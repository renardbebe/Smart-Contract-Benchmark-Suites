 

pragma solidity ^0.4.18;




 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     
    function Ownable() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}









 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        if (a != 0 && c / a != b) revert();
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        if (b > a) revert();
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        if (c < a) revert();
        return c;
    }
}



contract VLBBonusStore is Ownable {
    mapping(address => uint8) public rates;

    function collectRate(address investor) onlyOwner public returns (uint8) {
        require(investor != address(0));
        uint8 rate = rates[investor];
        if (rate != 0) {
            delete rates[investor];
        }
        return rate;
    }

    function addRate(address investor, uint8 rate) onlyOwner public {
        require(investor != address(0));
        rates[investor] = rate;
    }
}
contract VLBRefundVault is Ownable {
    using SafeMath for uint256;

    enum State {Active, Refunding, Closed}
    State public state;

    mapping (address => uint256) public deposited;

    address public wallet;

    event Closed();
    event FundsDrained(uint256 weiAmount);
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function VLBRefundVault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function unhold() onlyOwner public {
        require(state == State.Active);
        FundsDrained(this.balance);
        wallet.transfer(this.balance);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        FundsDrained(this.balance);
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }

    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }
}


interface Token {
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function tokensWallet() public returns (address);
}

 
contract VLBCrowdsale is Ownable {
    using SafeMath for uint;

     
    address public escrow;

     
    Token public token;

     
    VLBRefundVault public vault;

     
    VLBBonusStore public bonuses;

     
    uint startTime = 1513512000;

     
    uint endTime = 1523275200;

     
    uint256 public constant MIN_SALE_AMOUNT = 5 * 10**17;  

     
    uint256 public constant USD_GOAL = 4 * 10**6;   
    uint256 public constant USD_CAP  = 12 * 10**6;  

     
    uint256 public weiRaised;

     
    bool public isFinalized = false;

     
    bool public paused = false;

     
    bool public refunding = false;

     
    bool public isMinCapReached = false;

     
    uint public ETHUSD;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    event Finalized();

         
    event Pause();

         
    event Unpause();

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    modifier onlyEscrow() {
        require(msg.sender == escrow);
        _;
    }

     
    function VLBCrowdsale(address _tokenAddress, address _wallet, address _escrow, uint rate) public {
        require(_tokenAddress != address(0));
        require(_wallet != address(0));
        require(_escrow != address(0));

        escrow = _escrow;

         
        ETHUSD = rate;

         
        token = Token(_tokenAddress);

        vault = new VLBRefundVault(_wallet);
        bonuses = new VLBBonusStore();
    }

     
    function() public payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) whenNotPaused public payable {
        require(beneficiary != address(0));
        require(validPurchase(msg.value));

        uint256 weiAmount = msg.value;

         
        address buyer = msg.sender;

        weiRaised = weiRaised.add(weiAmount);

         
        uint256 tokens = weiAmount.mul(getConversionRate());

        uint8 rate = bonuses.collectRate(beneficiary);
        if (rate != 0) {
            tokens = tokens.mul(rate).div(100);
        }

        if (!token.transferFrom(token.tokensWallet(), beneficiary, tokens)) {
            revert();
        }

        TokenPurchase(buyer, beneficiary, weiAmount, tokens);

        vault.deposit.value(weiAmount)(buyer);
    }

     
    function validPurchase(uint256 _value) internal constant returns (bool) {
        bool nonZeroPurchase = _value != 0;
        bool withinPeriod = now >= startTime && now <= endTime;
        bool withinCap = !capReached(weiRaised.add(_value));

         
        bool withinAmount = msg.value >= MIN_SALE_AMOUNT;

        return nonZeroPurchase && withinPeriod && withinCap && withinAmount;
    }

     
    function unholdFunds() onlyOwner public {
        if (goalReached()) {
            isMinCapReached = true;
            vault.unhold();
        } else {
            revert();
        }
    }
    
     
    function hasEnded() public constant returns (bool) {
        bool timeIsUp = now > endTime;
        return timeIsUp || capReached();
    }

     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        if (goalReached()) {
            vault.close();
        } else {
            refunding = true;
            vault.enableRefunds();
        }

        isFinalized = true;
        Finalized();
    }

     
    function addRate(address investor, uint8 rate) onlyOwner public {
        require(investor != address(0));
        bonuses.addRate(investor, rate);
    }

     
    function goalReached() public view returns (bool) {        
        return isMinCapReached || weiRaised.mul(ETHUSD).div(10**20) >= USD_GOAL;
    }

     
    function capReached() internal view returns (bool) {
        return weiRaised.mul(ETHUSD).div(10**20) >= USD_CAP;
    }

     
    function capReached(uint256 raised) internal view returns (bool) {
        return raised.mul(ETHUSD).div(10**20) >= USD_CAP;
    }

     
    function claimRefund() public {
        require(isFinalized && refunding);

        vault.refund(msg.sender);
    }    

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
    
     
    function updateExchangeRate(uint rate) onlyEscrow public {
        ETHUSD = rate;
    } 

     
    function getConversionRate() public constant returns (uint256) {
        if (now >= startTime + 106 days) {
            return 650;
        } else if (now >= startTime + 99 days) {
            return 676;
        } else if (now >= startTime + 92 days) {
            return 715;
        } else if (now >= startTime + 85 days) {
            return 780;
        } else if (now >= startTime) {
            return 845;
        }
        return 0;
    }

     
    function kill() onlyOwner whenPaused public {
        selfdestruct(owner);
    }
}