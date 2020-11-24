 

pragma solidity 0.4.15;

pragma solidity 0.4.15;

 
contract MultiOwnable {
     
    struct Owner {
        address recipient;
        uint share;
    }

     
    Owner[] public owners;

     
    function ownersCount ()   constant   returns (uint count) {  
        return owners.length;
    }

     
    function owner (uint idx)   constant   returns (address owner_dot_recipient, uint owner_dot_share) {  
Owner memory owner;

        owner = owners[idx];
    owner_dot_recipient = address(owner.recipient);
owner_dot_share = uint(owner.share);}

     
    mapping (address => bool) ownersIdx;

     
    function MultiOwnable (address[16] _owners_dot_recipient, uint[16] _owners_dot_share)   {  
Owner[16] memory _owners;

for(uint __recipient_iterator__ = 0; __recipient_iterator__ < _owners_dot_recipient.length;__recipient_iterator__++)
  _owners[__recipient_iterator__].recipient = address(_owners_dot_recipient[__recipient_iterator__]);
for(uint __share_iterator__ = 0; __share_iterator__ < _owners_dot_share.length;__share_iterator__++)
  _owners[__share_iterator__].share = uint(_owners_dot_share[__share_iterator__]);
        for(var idx = 0; idx < _owners_dot_recipient.length; idx++) {
            if(_owners[idx].recipient != 0) {
                owners.push(_owners[idx]);
                assert(owners[idx].share > 0);
                ownersIdx[_owners[idx].recipient] = true;
            }
        }
    }

     
    modifier onlyOneOfOwners() {
        require(ownersIdx[msg.sender]);
        _;
    }


}


pragma solidity 0.4.15;

pragma solidity 0.4.15;

 
contract ERC20Token {
    

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function totalSupply() constant returns (uint256 totalSupply);

     
    function balanceOf(address owner) constant returns (uint256 balance);

     
    function transfer(address to, uint256 value) returns (bool success);

     
    function transferFrom(address from, address to, uint256 value) returns (bool success);

     
    function approve(address spender, uint256 value) returns (bool success);

     
    function allowance(address owner, address spender) constant returns (uint256 remaining);
}


 
 contract WIN is ERC20Token {
    

    string public constant symbol = "WIN";
    string public constant name = "WIN";

    uint8 public constant decimals = 7;
    uint256 constant TOKEN = 10**7;
    uint256 constant MILLION = 10**6;
    uint256 public totalTokenSupply = 500 * MILLION * TOKEN;

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) allowed;

     
    event Destroyed(address indexed owner, uint256 amount);

     
    function WIN ()   { 
        balances[msg.sender] = totalTokenSupply;
    }

     
    function totalSupply ()  constant  returns (uint256 result) { 
        result = totalTokenSupply;
    }

     
    function balanceOf (address owner)  constant  returns (uint256 balance) { 
        return balances[owner];
    }

     
    function transfer (address to, uint256 amount)   returns (bool success) { 
        if(balances[msg.sender] < amount)
            return false;

        if(amount <= 0)
            return false;

        if(balances[to] + amount <= balances[to])
            return false;

        balances[msg.sender] -= amount;
        balances[to] += amount;
        Transfer(msg.sender, to, amount);
        return true;
    }

     
    function transferFrom (address from, address to, uint256 amount)   returns (bool success) { 
        if (balances[from] < amount)
            return false;

        if(allowed[from][msg.sender] < amount)
            return false;

        if(amount == 0)
            return false;

        if(balances[to] + amount <= balances[to])
            return false;

        balances[from] -= amount;
        allowed[from][msg.sender] -= amount;
        balances[to] += amount;
        Transfer(from, to, amount);
        return true;
    }

     
    function approve (address spender, uint256 amount)   returns (bool success) { 
       allowed[msg.sender][spender] = amount;
       Approval(msg.sender, spender, amount);
       return true;
   }

     
    function allowance (address owner, address spender)  constant  returns (uint256 remaining) { 
        return allowed[owner][spender];
    }

      
    function destroy (uint256 amount)   returns (bool success) { 
        if(amount == 0) return false;
        if(balances[msg.sender] < amount) return false;
        balances[msg.sender] -= amount;
        totalTokenSupply -= amount;
        Destroyed(msg.sender, amount);
    }
}

pragma solidity 0.4.15;

 
library Math {
      

     
    function takePromille (uint value, uint promille)  constant  returns (uint result) { 
        result = value * promille / 1000;
    }

     
    function addPromille (uint value, uint promille)  constant  returns (uint result) { 
        result = value + takePromille(value, promille);
    }
}


 
contract BlindCroupierTokenDistribution is MultiOwnable {
    
    
    
    
    
    

    uint256 constant TOKEN = 10**7;
    uint256 constant MILLION = 10**6;

    uint256 constant MINIMUM_DEPOSIT = 100 finney;  
    uint256 constant PRESALE_TOKEN_PRICE = 0.00035 ether / TOKEN;
    uint256 constant SALE_INITIAL_TOKEN_PRICE = 0.0005 ether / TOKEN;

    uint256 constant TOKENS_FOR_PRESALE = 5 * MILLION * TOKEN;  
    uint256 constant TOKENS_PER_FIRST_PERIOD = 15 * MILLION * TOKEN;  
    uint256 constant TOKENS_PER_PERIOD = 1 * MILLION * TOKEN;  
    uint256 constant FIRST_PERIOD_DURATION = 161 hours;  
    uint256 constant PERIOD_DURATION = 23 hours;  
    uint256 constant PERIOD_PRICE_INCREASE = 5;  
    uint256 constant FULLY_SOLD_PRICE_INCREASE = 10;  
    uint256 constant TOKENS_TO_INCREASE_NEXT_PRICE = 800;  

    uint256 constant NEVER = 0;
    uint16 constant UNKNOWN_COUNTRY = 0;

     
    enum State {
        NotStarted,
        Presale,
        Sale
    }

    uint256 public totalUnclaimedTokens;  
    uint256 public totalTokensSold;  
    uint256 public totalTokensDestroyed;  

    mapping(address => uint256) public unclaimedTokensForInvestor;  

     
    struct Period {
        uint256 startTime;
        uint256 endTime;
        uint256 tokenPrice;
        uint256 tokensSold;
    }

     
    event Deposited(address indexed investor, uint256 amount, uint256 tokenCount);

     
    event PeriodStarted(uint periodIndex, uint256 tokenPrice, uint256 tokensToSale, uint256 startTime, uint256 endTime, uint256 now);

     
    event TokensClaimed(address indexed investor, uint256 claimed);

     
    uint public currentPeriod = 0;

     
    mapping(uint => Period) periods;

     
    WIN public win;

     
    State public state;

     
    mapping(uint16 => uint256) investmentsByCountries;

     
    function getInvestmentsByCountry (uint16 country)   constant   returns (uint256 investment) {  
        investment = investmentsByCountries[country];
    }

     
    function getTokenPrice ()   constant   returns (uint256 tokenPrice) {  
        tokenPrice = periods[currentPeriod].tokenPrice;
    }

     
    function getTokenPriceForPeriod (uint periodIndex)   constant   returns (uint256 tokenPrice) {  
        tokenPrice = periods[periodIndex].tokenPrice;
    }

     
    function getTokensSold (uint period)   constant   returns (uint256 tokensSold) {  
        return periods[period].tokensSold;
    }

     
    function isActive ()   constant   returns (bool active) {  
        return win.balanceOf(this) >= totalUnclaimedTokens + tokensForPeriod(currentPeriod) - periods[currentPeriod].tokensSold;
    }

     
    function deposit (address beneficiar, uint16 countryCode)   payable  {  
        require(msg.value >= MINIMUM_DEPOSIT);
        require(state == State.Sale || state == State.Presale);

         
        tick();

         
        require(isActive());

        uint256 tokensBought = msg.value / getTokenPrice();

        if(periods[currentPeriod].tokensSold + tokensBought >= tokensForPeriod(currentPeriod)) {
            tokensBought = tokensForPeriod(currentPeriod) - periods[currentPeriod].tokensSold;
        }

        uint256 moneySpent = getTokenPrice() * tokensBought;

        investmentsByCountries[countryCode] += moneySpent;

        if(tokensBought > 0) {
            assert(moneySpent <= msg.value);

             
            if(msg.value > moneySpent) {
                msg.sender.transfer(msg.value - moneySpent);
            }

            periods[currentPeriod].tokensSold += tokensBought;
            unclaimedTokensForInvestor[beneficiar] += tokensBought;
            totalUnclaimedTokens += tokensBought;
            totalTokensSold += tokensBought;
            Deposited(msg.sender, moneySpent, tokensBought);
        }

         
        tick();
    }

     
    function() payable {
        deposit(msg.sender, UNKNOWN_COUNTRY);
    }

     
    function BlindCroupierTokenDistribution (address[16] owners_dot_recipient, uint[16] owners_dot_share)   MultiOwnable(owners_dot_recipient, owners_dot_share)  {  
MultiOwnable.Owner[16] memory owners;

for(uint __recipient_iterator__ = 0; __recipient_iterator__ < owners_dot_recipient.length;__recipient_iterator__++)
  owners[__recipient_iterator__].recipient = address(owners_dot_recipient[__recipient_iterator__]);
for(uint __share_iterator__ = 0; __share_iterator__ < owners_dot_share.length;__share_iterator__++)
  owners[__share_iterator__].share = uint(owners_dot_share[__share_iterator__]);
        state = State.NotStarted;
    }

     
    function startPresale (address tokenContractAddress)   onlyOneOfOwners  {  
        require(state == State.NotStarted);

        win = WIN(tokenContractAddress);

        assert(win.balanceOf(this) >= tokensForPeriod(0));

        periods[0] = Period(now, NEVER, PRESALE_TOKEN_PRICE, 0);
        PeriodStarted(0,
            PRESALE_TOKEN_PRICE,
            tokensForPeriod(currentPeriod),
            now,
            NEVER,
            now);
        state = State.Presale;
    }

     
    function endPresale ()   onlyOneOfOwners  {  
        require(state == State.Presale);
        state = State.Sale;
        nextPeriod();
    }

     
    function periodTimeFrame (uint period)   constant   returns (uint256 startTime, uint256 endTime) {  
        require(period <= currentPeriod);

        startTime = periods[period].startTime;
        endTime = periods[period].endTime;
    }

     
    function isPeriodTimePassed (uint period)   constant   returns (bool finished) {  
        require(periods[period].startTime > 0);

        uint256 endTime = periods[period].endTime;

        if(endTime == NEVER) {
            return false;
        }

        return (endTime < now);
    }

     
    function isPeriodClosed (uint period)   constant   returns (bool finished) {  
        return period < currentPeriod;
    }

     
    function isPeriodAllTokensSold (uint period)   constant   returns (bool finished) {  
        return periods[period].tokensSold == tokensForPeriod(period);
    }

     
    function unclaimedTokens ()   constant   returns (uint256 tokens) {  
        return unclaimedTokensForInvestor[msg.sender];
    }

     
    function claimAllTokensForInvestor (address investor)   {  
        assert(totalUnclaimedTokens >= unclaimedTokensForInvestor[investor]);
        totalUnclaimedTokens -= unclaimedTokensForInvestor[investor];
        win.transfer(investor, unclaimedTokensForInvestor[investor]);
        TokensClaimed(investor, unclaimedTokensForInvestor[investor]);
        unclaimedTokensForInvestor[investor] = 0;
    }

     
    function claimAllTokens ()   {  
        claimAllTokensForInvestor(msg.sender);
    }

     
    function tokensForPeriod (uint period)   constant   returns (uint256 tokens) {  
        if(period == 0) {
            return TOKENS_FOR_PRESALE;
        } else if(period == 1) {
            return TOKENS_PER_FIRST_PERIOD;
        } else {
            return TOKENS_PER_PERIOD;
        }
    }

     
    function periodDuration (uint period)   constant   returns (uint256 duration) {  
        require(period > 0);

        if(period == 1) {
            return FIRST_PERIOD_DURATION;
        } else {
            return PERIOD_DURATION;
        }
    }

     
    function nextPeriod() internal {
        uint256 oldPrice = periods[currentPeriod].tokenPrice;
        uint256 newPrice;
        if(currentPeriod == 0) {
            newPrice = SALE_INITIAL_TOKEN_PRICE;
        } else if(periods[currentPeriod].tokensSold  == tokensForPeriod(currentPeriod)) {
            newPrice = Math.addPromille(oldPrice, FULLY_SOLD_PRICE_INCREASE);
        } else if(periods[currentPeriod].tokensSold >= Math.takePromille(tokensForPeriod(currentPeriod), TOKENS_TO_INCREASE_NEXT_PRICE)) {
            newPrice = Math.addPromille(oldPrice, PERIOD_PRICE_INCREASE);
        } else {
            newPrice = oldPrice;
        }

         
        if(periods[currentPeriod].tokensSold < tokensForPeriod(currentPeriod)) {
            uint256 toDestroy = tokensForPeriod(currentPeriod) - periods[currentPeriod].tokensSold;
             
            uint256 balance = win.balanceOf(this);
            if(balance < toDestroy + totalUnclaimedTokens) {
                toDestroy = (balance - totalUnclaimedTokens);
            }
            win.destroy(toDestroy);
            totalTokensDestroyed += toDestroy;
        }

         
        if(periods[currentPeriod].endTime > now ||
            periods[currentPeriod].endTime == NEVER) {
            periods[currentPeriod].endTime = now;
        }

        uint256 duration = periodDuration(currentPeriod + 1);

        periods[currentPeriod + 1] = Period(
            periods[currentPeriod].endTime,
            periods[currentPeriod].endTime + duration,
            newPrice,
            0);

        currentPeriod++;

        PeriodStarted(currentPeriod,
            newPrice,
            tokensForPeriod(currentPeriod),
            periods[currentPeriod].startTime,
            periods[currentPeriod].endTime,
            now);
    }

     
    function tick ()   {  
        if(!isActive()) {
            return;
        }

        while(state == State.Sale &&
            (isPeriodTimePassed(currentPeriod) ||
            isPeriodAllTokensSold(currentPeriod))) {
            nextPeriod();
        }
    }

     
    function withdraw (uint256 amount)   onlyOneOfOwners  {  
        require(this.balance >= amount);

        uint totalShares = 0;
        for(var idx = 0; idx < owners.length; idx++) {
            totalShares += owners[idx].share;
        }

        for(idx = 0; idx < owners.length; idx++) {
            owners[idx].recipient.transfer(amount * owners[idx].share / totalShares);
        }
    }
}