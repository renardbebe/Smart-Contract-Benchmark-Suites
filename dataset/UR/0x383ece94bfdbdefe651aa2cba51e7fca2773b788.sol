 

pragma solidity ^0.4.18;

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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
         
         
         
        return a / b;
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


 
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


     
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


 
contract MintableToken is StandardToken, Ownable {

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

}


 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    function _burn(address _burner, uint256 _value) internal {
        require(_value <= balances[_burner]);
         
         

        balances[_burner] = balances[_burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(_burner, _value);
        Transfer(_burner, address(0), _value);
    }

}


contract DividendPayoutToken is BurnableToken, MintableToken {

     
    mapping(address => uint256) public dividendPayments;
     
    uint256 public totalDividendPayments;

     
    function increaseDividendPayments(address _investor, uint256 _amount) onlyOwner public {
        dividendPayments[_investor] = dividendPayments[_investor].add(_amount);
        totalDividendPayments = totalDividendPayments.add(_amount);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
         
        uint256 oldBalanceFrom = balances[msg.sender];

         
        bool isTransferred = super.transfer(_to, _value);

        uint256 transferredClaims = dividendPayments[msg.sender].mul(_value).div(oldBalanceFrom);
        dividendPayments[msg.sender] = dividendPayments[msg.sender].sub(transferredClaims);
        dividendPayments[_to] = dividendPayments[_to].add(transferredClaims);

        return isTransferred;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
         
        uint256 oldBalanceFrom = balances[_from];

         
        bool isTransferred = super.transferFrom(_from, _to, _value);

        uint256 transferredClaims = dividendPayments[_from].mul(_value).div(oldBalanceFrom);
        dividendPayments[_from] = dividendPayments[_from].sub(transferredClaims);
        dividendPayments[_to] = dividendPayments[_to].add(transferredClaims);

        return isTransferred;
    }

    function burn() public {
        address burner = msg.sender;

         
        uint256 oldBalance = balances[burner];

        super._burn(burner, oldBalance);

        uint256 burnedClaims = dividendPayments[burner];
        dividendPayments[burner] = dividendPayments[burner].sub(burnedClaims);
        totalDividendPayments = totalDividendPayments.sub(burnedClaims);

        SaleInterface(owner).refund(burner);
    }

}

contract RicoToken is DividendPayoutToken {

    string public constant name = "Rico";

    string public constant symbol = "Rico";

    uint8 public constant decimals = 18;

}


 
contract SaleInterface {

    function refund(address _to) public;

}


contract ReentrancyGuard {

     
    bool private reentrancy_lock = false;

     
    modifier nonReentrant() {
        require(!reentrancy_lock);
        reentrancy_lock = true;
        _;
        reentrancy_lock = false;
    }

}

contract PreSale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

     
    RicoToken public token;
    address tokenContractAddress;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;

     
    uint256 public rate;

    uint256 public minimumInvest;  

    uint256 public softCap;  
    uint256 public hardCap;  

     
    mapping(address => uint) public balances;

     
    uint256 public weiRaised;

     
    uint256 bonusPercent;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function PreSale(
        uint256 _startTime,
        uint256 _period,
        address _wallet,
        address _token,
        uint256 _minimumInvest) public
    {
        require(_period != 0);
        require(_token != address(0));

        startTime = _startTime;
        endTime = startTime + _period * 1 days;

        wallet = _wallet;
        token = RicoToken(_token);
        tokenContractAddress = _token;

         
        minimumInvest = _minimumInvest;

         
        rate = 6667;

        softCap = 150 * 1 ether;
        hardCap = 1500 * 1 ether;
        bonusPercent = 50;
    }

     
    modifier saleIsOn() {
        bool withinPeriod = now >= startTime && now <= endTime;
        require(withinPeriod);
        _;
    }

    modifier isUnderHardCap() {
        require(weiRaised < hardCap);
        _;
    }

    modifier refundAllowed() {
        require(weiRaised < softCap && now > endTime);
        _;
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

     
    function refund(address _to) public refundAllowed {
        require(msg.sender == tokenContractAddress);

        uint256 valueToReturn = balances[_to];

         
        balances[_to] = 0;
        weiRaised = weiRaised.sub(valueToReturn);

        _to.transfer(valueToReturn);
    }

     
     
    function getTokenAmount(uint256 _value) internal view returns (uint256) {
        return _value.mul(rate);
    }

     
    function forwardFunds(uint256 _value) internal {
        wallet.transfer(_value);
    }

     
    function finishPreSale() public onlyOwner {
        require(weiRaised >= softCap);
        require(weiRaised >= hardCap || now > endTime);

        if (now < endTime) {
            endTime = now;
        }

        forwardFunds(this.balance);
        token.transferOwnership(owner);
    }

     
    function changeTokenOwner() public onlyOwner {
        require(now > endTime && weiRaised < softCap);
        token.transferOwnership(owner);
    }

     
    function buyTokens(address _beneficiary) saleIsOn isUnderHardCap nonReentrant public payable {
        require(_beneficiary != address(0));
        require(msg.value >= minimumInvest);

        uint256 weiAmount = msg.value;
        uint256 tokens = getTokenAmount(weiAmount);
        tokens = tokens.add(tokens.mul(bonusPercent).div(100));

        token.mint(_beneficiary, tokens);

         
        weiRaised = weiRaised.add(weiAmount);
        balances[_beneficiary] = balances[_beneficiary].add(weiAmount);

        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    }

    function() external payable {
        buyTokens(msg.sender);
    }
}