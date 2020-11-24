 

pragma solidity ^0.4.15;


 
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

contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public constant returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue)
    returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue)
    returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


 
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

 
contract IRBToken is StandardToken, Ownable {
    using SafeMath for uint256;

     
    string public constant name = "IRB Tokens";

    string public constant symbol = "IRB";

    uint8 public decimals = 18;

     
    uint256 public constant crowdsaleTokens = 489580 * 10 ** 21;

     
    uint256 public constant preCrowdsaleTokens = 10420 * 10 ** 21;

     
     
    address public constant preCrowdsaleTokensWallet = 0x0CD95a59fAd089c4EBCCEB54f335eC8f61Caa80e;
     
    address public constant crowdsaleTokensWallet = 0x48545E41696Dc51020C35cA8C36b678101a98437;

     
    address public preCrowdsaleContractAddress;

     
    address public crowdsaleContractAddress;

     
    bool isPreFinished = false;

     
    bool isFinished = false;

     
    modifier onlyPreCrowdsaleContract() {
        require(msg.sender == preCrowdsaleContractAddress);
        _;
    }

     
    modifier onlyCrowdsaleContract() {
        require(msg.sender == crowdsaleContractAddress);
        _;
    }

     
    event TokensBurnt(uint256 tokens);

     
    event Live(uint256 supply);

     
    function IRBToken() {
         
        balances[preCrowdsaleTokensWallet] = balanceOf(preCrowdsaleTokensWallet).add(preCrowdsaleTokens);
        Transfer(address(0), preCrowdsaleTokensWallet, preCrowdsaleTokens);

         
        balances[crowdsaleTokensWallet] = balanceOf(crowdsaleTokensWallet).add(crowdsaleTokens);
        Transfer(address(0), crowdsaleTokensWallet, crowdsaleTokens);

         
        totalSupply = crowdsaleTokens.add(preCrowdsaleTokens);
    }

     
    function setPreCrowdsaleAddress(address _preCrowdsaleAddress) onlyOwner external {
        require(_preCrowdsaleAddress != address(0));
        preCrowdsaleContractAddress = _preCrowdsaleAddress;

         
        uint256 balance = balanceOf(preCrowdsaleTokensWallet);
        allowed[preCrowdsaleTokensWallet][preCrowdsaleContractAddress] = balance;
        Approval(preCrowdsaleTokensWallet, preCrowdsaleContractAddress, balance);
    }

     
    function setCrowdsaleAddress(address _crowdsaleAddress) onlyOwner external {
        require(isPreFinished);
        require(_crowdsaleAddress != address(0));
        crowdsaleContractAddress = _crowdsaleAddress;

         
        uint256 balance = balanceOf(crowdsaleTokensWallet);
        allowed[crowdsaleTokensWallet][crowdsaleContractAddress] = balance;
        Approval(crowdsaleTokensWallet, crowdsaleContractAddress, balance);
    }

     
    function endPreTokensale() onlyPreCrowdsaleContract external {
        require(!isPreFinished);
        uint256 preCrowdsaleLeftovers = balanceOf(preCrowdsaleTokensWallet);

        if (preCrowdsaleLeftovers > 0) {
            balances[preCrowdsaleTokensWallet] = 0;
            balances[crowdsaleTokensWallet] = balances[crowdsaleTokensWallet].add(preCrowdsaleLeftovers);
            Transfer(preCrowdsaleTokensWallet, crowdsaleTokensWallet, preCrowdsaleLeftovers);
        }

        isPreFinished = true;
    }

     
    function endTokensale() onlyCrowdsaleContract external {
        require(!isFinished);
        uint256 crowdsaleLeftovers = balanceOf(crowdsaleTokensWallet);

        if (crowdsaleLeftovers > 0) {
            totalSupply = totalSupply.sub(crowdsaleLeftovers);

            balances[crowdsaleTokensWallet] = 0;
            Transfer(crowdsaleTokensWallet, address(0), crowdsaleLeftovers);
            TokensBurnt(crowdsaleLeftovers);
        }

        isFinished = true;
        Live(totalSupply);
    }
}


 
contract IRBPreRefundVault is Ownable {
    using SafeMath for uint256;

    enum State {Active, Refunding, Closed}
    State public state;

    mapping (address => uint256) public deposited;

    uint256 public totalDeposited;

    address public constant wallet = 0x26dB9eF39Bbfe437f5b384c3913E807e5633E7cE;

    address preCrowdsaleContractAddress;

    event Closed();

    event RefundsEnabled();

    event Refunded(address indexed beneficiary, uint256 weiAmount);

    event Withdrawal(address indexed receiver, uint256 weiAmount);

    function IRBPreRefundVault() {
        state = State.Active;
    }

    modifier onlyCrowdsaleContract() {
        require(msg.sender == preCrowdsaleContractAddress);
        _;
    }

    function setPreCrowdsaleAddress(address _preCrowdsaleAddress) external onlyOwner {
        require(_preCrowdsaleAddress != address(0));
        preCrowdsaleContractAddress = _preCrowdsaleAddress;
    }

    function deposit(address investor) onlyCrowdsaleContract external payable {
        require(state == State.Active);
        uint256 amount = msg.value;
        deposited[investor] = deposited[investor].add(amount);
        totalDeposited = totalDeposited.add(amount);
    }

    function close() onlyCrowdsaleContract external {
        require(state == State.Active);
        state = State.Closed;
        totalDeposited = 0;
        Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyCrowdsaleContract external {
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

     
    function withdraw(uint value) onlyCrowdsaleContract external returns (bool success) {
        require(state == State.Active);
        require(totalDeposited >= value);
        totalDeposited = totalDeposited.sub(value);
        wallet.transfer(value);
        Withdrawal(wallet, value);
        return true;
    }

     
    function kill() onlyOwner {
        require(state == State.Closed);
        selfdestruct(owner);
    }
}



 
contract IRBPreCrowdsale is Ownable, Pausable {
    using SafeMath for uint;

     
    IRBToken public token;

     
    IRBPreRefundVault public vault;

     
    uint startTime = 1513065600;

     
    uint endTime = 1515963599;

     
    uint256 public constant minPresaleAmount = 108 * 10 ** 15;  

     
    uint256 public constant goal = 1125 * 10 ** 18;   
    uint256 public constant cap = 2250 * 10 ** 18;  

     
    uint256 public weiRaised;

     
    bool public isFinalized = false;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    event Finalized();

     
    function IRBPreCrowdsale(address _tokenAddress, address _vaultAddress) {
        require(_tokenAddress != address(0));
        require(_vaultAddress != address(0));

         
        token = IRBToken(_tokenAddress);
        vault = IRBPreRefundVault(_vaultAddress);
    }

     
    function() payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) whenNotPaused public payable {
        require(beneficiary != address(0));
        require(validPurchase(msg.value));

        uint256 weiAmount = msg.value;

         
        address buyer = msg.sender;

         
        uint256 tokens = convertAmountToTokens(weiAmount);

        weiRaised = weiRaised.add(weiAmount);

        if (!token.transferFrom(token.preCrowdsaleTokensWallet(), beneficiary, tokens)) {
            revert();
        }

        TokenPurchase(buyer, beneficiary, weiAmount, tokens);

        vault.deposit.value(weiAmount)(buyer);
    }

     
    function validPurchase(uint256 _value) internal constant returns (bool) {
        bool nonZeroPurchase = _value != 0;
        bool withinPeriod = now >= startTime && now <= endTime;
        bool withinCap = weiRaised.add(_value) <= cap;
         
        bool withinAmount = msg.value >= minPresaleAmount;

        return nonZeroPurchase && withinPeriod && withinCap && withinAmount;
    }

     
    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised.add(minPresaleAmount) >= cap;
        bool timeIsUp = now > endTime;
        return timeIsUp || capReached;
    }

     
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

         
        if (goalReached()) {
            vault.close();
        }
        else {
            vault.enableRefunds();
        }

        token.endPreTokensale();

        isFinalized = true;

        Finalized();
    }

     
    function goalReached() public constant returns (bool) {
        return weiRaised >= goal;
    }

     
    function withdraw(uint256 amount) onlyOwner public {
        require(!isFinalized);
        require(goalReached());
        require(amount > 0);

        vault.withdraw(amount);
    }

     
    function convertAmountToTokens(uint256 amount) public constant returns (uint256) {
         
        uint256 tokens = amount.div(27).mul(100000);
         
        uint256 bonus = tokens.div(4);

        return tokens.add(bonus);
    }

     
    function kill() onlyOwner whenPaused {
        selfdestruct(owner);
    }
}