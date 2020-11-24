 

pragma solidity ^0.4.18;


 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}



 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}


 
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function RefundVault(address _wallet) public {
        require(_wallet != 0x0);
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) public onlyOwner  payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() public onlyOwner {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() public onlyOwner {
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

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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


contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}


contract ApplauseCashToken is StandardToken, PausableToken {
    string public constant name = "ApplauseCash";
    string public constant symbol = "APLC";
    uint8 public constant decimals = 4;
    uint256 public INITIAL_SUPPLY = 300000000 * 10000;

    function ApplauseCashToken() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
}



 

contract ApplauseCashCrowdsale is Ownable {

    using SafeMath for uint256;

    struct Bonus {
        uint duration;
        uint percent;
    }

     
    uint256 public softcap;

     
    RefundVault public vault;

     
    bool public isFinalized;

     
    ApplauseCashToken public token = new ApplauseCashToken();

     
    uint256 public preIcoStartTime;
    uint256 public preIcoEndTime;

     
    uint256 public icoStartTime;
    uint256 public icoEndTime;

     
    uint256 public preIcoHardcap;
    uint256 public icoHardcap;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public tokensInvested;

    Bonus[] public preIcoBonuses;
    Bonus[] public icoBonuses;

     
    uint256 public preIcoMinimumWei;
    uint256 public icoMinimumWei;

     
    uint256 public defaultPercent;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function ApplauseCashCrowdsale(
        uint256 _preIcoStartTime,
        uint256 _preIcoEndTime,
        uint256 _preIcoHardcap,
        uint256 _icoStartTime,
        uint256 _icoEndTime,
        uint256 _icoHardcap,
        uint256 _softcap,
        uint256 _rate,
        address _wallet
    ) public {

         

         
        require(_preIcoStartTime >= now);

         
        require(_icoStartTime >= now);

         
        require(_preIcoEndTime < _icoStartTime);

         
        require(_preIcoStartTime < _preIcoEndTime);

         
        require(_icoStartTime < _icoEndTime);

        require(_rate > 0);
        require(_preIcoHardcap > 0);
        require(_icoHardcap > 0);
        require(_wallet != 0x0);

        preIcoMinimumWei = 20000000000000000;   
        icoMinimumWei = 20000000000000000;  
        defaultPercent = 0;

        preIcoBonuses.push(Bonus({duration: 1 hours, percent: 90}));
        preIcoBonuses.push(Bonus({duration: 6 days + 5 hours, percent: 50}));

        icoBonuses.push(Bonus({duration: 1 hours, percent: 45}));
        icoBonuses.push(Bonus({duration: 7 days + 15 hours, percent: 40}));
        icoBonuses.push(Bonus({duration: 6 days, percent: 30}));
        icoBonuses.push(Bonus({duration: 6 days, percent: 20}));
        icoBonuses.push(Bonus({duration: 7 days, percent: 10}));

        preIcoStartTime = _preIcoStartTime;
        preIcoEndTime = _preIcoEndTime;
        preIcoHardcap = _preIcoHardcap;
        icoStartTime = _icoStartTime;
        icoEndTime = _icoEndTime;
        icoHardcap = _icoHardcap;
        softcap = _softcap;
        rate = _rate;
        wallet = _wallet;

        isFinalized = false;

        vault = new RefundVault(wallet);
    }

     
    function () public payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {

        require(beneficiary != 0x0);
        require(msg.value != 0);
        require(!isFinalized);

        uint256 weiAmount = msg.value;

        validateWithinPeriods();

         
         
         
         
        uint256 tokens = weiAmount.mul(rate).div(100000000000000);

        uint256 percent = getBonusPercent(now);

         
        uint256 bonusedTokens = applyBonus(tokens, percent);

        validateWithinCaps(bonusedTokens, weiAmount);

         
        tokensInvested = tokensInvested.add(bonusedTokens);
        token.transfer(beneficiary, bonusedTokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, bonusedTokens);

        forwardFunds();
    }
    
     
    function transferTokens(address beneficiary, uint256 tokens) public onlyOwner {
        token.transfer(beneficiary, tokens);
    }

     
    function setPreIcoParameters(
        uint256 _preIcoStartTime,
        uint256 _preIcoEndTime,
        uint256 _preIcoHardcap,
        uint256 _preIcoMinimumWei
    ) public onlyOwner {
        require(!isFinalized);
        require(_preIcoStartTime < _preIcoEndTime);
        require(_preIcoHardcap > 0);
        preIcoStartTime = _preIcoStartTime;
        preIcoEndTime = _preIcoEndTime;
        preIcoHardcap = _preIcoHardcap;
        preIcoMinimumWei = _preIcoMinimumWei;
    }

     
    function setIcoParameters(
        uint256 _icoStartTime,
        uint256 _icoEndTime,
        uint256 _icoHardcap,
        uint256 _icoMinimumWei
    ) public onlyOwner {

        require(!isFinalized);
        require(_icoStartTime < _icoEndTime);
        require(_icoHardcap > 0);
        icoStartTime = _icoStartTime;
        icoEndTime = _icoEndTime;
        icoHardcap = _icoHardcap;
        icoMinimumWei = _icoMinimumWei;
    }

     
    function setWallet(address _wallet) public onlyOwner {
        require(!isFinalized);
        require(_wallet != 0x0);
        wallet = _wallet;
    }

       
    function setRate(uint256 _rate) public onlyOwner {
        require(!isFinalized);
        require(_rate > 0);
        rate = _rate;
    }

         
    function setSoftcap(uint256 _softcap) public onlyOwner {
        require(!isFinalized);
        require(_softcap > 0);
        softcap = _softcap;
    }


     
    function pauseToken() external onlyOwner {
        require(!isFinalized);
        token.pause();
    }

     
    function unpauseToken() external onlyOwner {
        token.unpause();
    }

     
    function transferTokenOwnership(address newOwner) external onlyOwner {
        token.transferOwnership(newOwner);
    }

     
    function icoHasEnded() external constant returns (bool) {
        return now > icoEndTime;
    }

     
    function preIcoHasEnded() external constant returns (bool) {
        return now > preIcoEndTime;
    }

     
    function forwardFunds() internal {
         
        vault.deposit.value(msg.value)(msg.sender);
    }

     
     
    function getBonusPercent(uint256 currentTime) public constant returns (uint256 percent) {
       
        uint i = 0;
        bool isPreIco = currentTime >= preIcoStartTime && currentTime <= preIcoEndTime;
        uint256 offset = 0;
        if (isPreIco) {
            uint256 preIcoDiffInSeconds = currentTime.sub(preIcoStartTime);
            for (i = 0; i < preIcoBonuses.length; i++) {
                if (preIcoDiffInSeconds <= preIcoBonuses[i].duration + offset) {
                    return preIcoBonuses[i].percent;
                }
                offset = offset.add(preIcoBonuses[i].duration);
            }
        } else {
            uint256 icoDiffInSeconds = currentTime.sub(icoStartTime);
            for (i = 0; i < icoBonuses.length; i++) {
                if (icoDiffInSeconds <= icoBonuses[i].duration + offset) {
                    return icoBonuses[i].percent;
                }
                offset = offset.add(icoBonuses[i].duration);
            }
        }
        return defaultPercent;
    }

    function applyBonus(uint256 tokens, uint256 percent) internal pure returns  (uint256 bonusedTokens) {
        uint256 tokensToAdd = tokens.mul(percent).div(100);
        return tokens.add(tokensToAdd);
    }

    function validateWithinPeriods() internal constant {
         
        require((now >= preIcoStartTime && now <= preIcoEndTime) || (now >= icoStartTime && now <= icoEndTime));
    }

    function validateWithinCaps(uint256 tokensAmount, uint256 weiAmount) internal constant {
        uint256 expectedTokensInvested = tokensInvested.add(tokensAmount);

         
        if (now >= preIcoStartTime && now <= preIcoEndTime) {
            require(weiAmount >= preIcoMinimumWei);
            require(expectedTokensInvested <= preIcoHardcap);
        }

         
        if (now >= icoStartTime && now <= icoEndTime) {
            require(expectedTokensInvested <= icoHardcap);
        }
    }

     
    function claimRefund() public {
        require(isFinalized);
        require(!softcapReached());
        vault.refund(msg.sender);
    }

    function softcapReached() public constant returns (bool) {
        return tokensInvested >= softcap;
    }

     
    function finaliseCrowdsale() external onlyOwner returns (bool) {
        require(!isFinalized);
        if (softcapReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }

        isFinalized = true;
        return true;
    }

}


contract Deployer is Ownable {

    ApplauseCashCrowdsale public applauseCashCrowdsale;
    uint256 public constant TOKEN_DECIMALS_MULTIPLIER = 10000;
    address public multisig = 0xaB188aCBB8a401277DC2D83C242677ca3C96fF05;

    function deploy() public onlyOwner {
        applauseCashCrowdsale = new ApplauseCashCrowdsale(
            1516280400,  
            1516856400,  
            3000000 * TOKEN_DECIMALS_MULTIPLIER,  
            1517490000,   
            1519880400,  
            144000000 * TOKEN_DECIMALS_MULTIPLIER,   
            50000 * TOKEN_DECIMALS_MULTIPLIER,  
            500,  
            multisig  
        );
    }

    function setOwner() public onlyOwner {
        applauseCashCrowdsale.transferOwnership(owner);
    }


}