 

 

pragma solidity ^0.4.23;

 
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
        emit Transfer(msg.sender, _to, _value);
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
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

}


 
contract CappedToken is MintableToken {

    uint256 public cap;

    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply_.add(_amount) <= cap);

        return super.mint(_to, _amount);
    }

}


contract DividendPayoutToken is CappedToken {

     
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

}

contract IcsToken is DividendPayoutToken {

    string public constant name = "Interexchange Crypstock System";

    string public constant symbol = "ICS";

    uint8 public constant decimals = 18;

     
    constructor() public
    CappedToken(5e8 * 1e18) {}

}

contract HicsToken is DividendPayoutToken {

    string public constant name = "Interexchange Crypstock System Heritage Token";

    string public constant symbol = "HICS";

    uint8 public constant decimals = 18;

     
    constructor() public
    CappedToken(5e7 * 1e18) {}

}


 
contract ReentrancyGuard {

     
    bool private reentrancyLock = false;

     
    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}

contract PreSale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

     
    ERC20 public t4tToken;

     
    IcsToken public icsToken;
    HicsToken public hicsToken;

     
    uint64 public startTime;
    uint64 public endTime;
    uint64 public endPeriodA;
    uint64 public endPeriodB;
    uint64 public endPeriodC;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public rateT4T;

    uint256 public minimumInvest;  

    uint256 public hicsTokenPrice;   

     
    uint256 public capHicsToken;   

    uint256 public softCap;  

     
    mapping(address => uint) public balances;   

     
    mapping(address => uint) balancesForRefund;   

     
    mapping(address => uint) balancesForRefundT4T;   

     
    uint256 public weiRaised;

     
    uint256 public t4tRaised;

     
    uint256 public totalTokensEmitted;   

     
    uint256 public totalRaised;   

     
    event IcsTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 tokens);
    event HicsTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 tokens);

     
    constructor(
        address _wallet,
        address _icsToken,
        address _hicsToken,
        address _erc20Token) public
    {
        require(_wallet != address(0));
        require(_icsToken != address(0));
        require(_hicsToken != address(0));
        require(_erc20Token != address(0));

         
        startTime = 1528675200;   
        endPeriodA = 1529107200;  
        endPeriodB = 1529798400;  
        endPeriodC = 1530489600;  
        endTime = 1531353600;     

         
        bool validPeriod = now < startTime && startTime < endPeriodA 
                        && endPeriodA < endPeriodB && endPeriodB < endPeriodC 
                        && endPeriodC < endTime;
        require(validPeriod);

        wallet = _wallet;
        icsToken = IcsToken(_icsToken);
        hicsToken = HicsToken(_hicsToken);

         
        t4tToken = ERC20(_erc20Token);

         
        rateT4T = 4;

         
        minimumInvest = 4 * 1e18;   

         
        hicsTokenPrice = 2e4 * 1e18;   

         
         
        rate = 2720;   

         
        softCap = 4e6 * 1e18;   

        capHicsToken = 15e6 * 1e18;   
    }

     
    modifier saleIsOn() {
        bool withinPeriod = now >= startTime && now <= endTime;
        require(withinPeriod);
        _;
    }

     
    modifier refundAllowed() {
        require(totalRaised < softCap && now > endTime);
        _;
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

     
    function refund() public refundAllowed nonReentrant {
        uint256 valueToReturn = balancesForRefund[msg.sender];

         
        balancesForRefund[msg.sender] = 0;
        weiRaised = weiRaised.sub(valueToReturn);

        msg.sender.transfer(valueToReturn);
    }

     
    function refundT4T() public refundAllowed nonReentrant {
        uint256 valueToReturn = balancesForRefundT4T[msg.sender];

         
        balancesForRefundT4T[msg.sender] = 0;
        t4tRaised = t4tRaised.sub(valueToReturn);

        t4tToken.transfer(msg.sender, valueToReturn);
    }

     
    function _getBonusPercent() internal view returns(uint256) {

        if (now < endPeriodA) {
            return 40;
        }
        if (now < endPeriodB) {
            return 25;
        }
        if (now < endPeriodC) {
            return 20;
        }

        return 15;
    }

     
     
    function _getTokenNumberWithBonus(uint256 _value) internal view returns (uint256) {
        return _value.add(_value.mul(_getBonusPercent()).div(100));
    }

     
     
    function _forwardFunds(uint256 _value) internal {
        wallet.transfer(_value);
    }

     
     
    function _forwardT4T(uint256 _value) internal {
        t4tToken.transfer(wallet, _value);
    }

     
    function withdrawalEth() public onlyOwner {
        require(totalRaised >= softCap);

         
        _forwardFunds(address(this).balance);
    }

     
    function withdrawalT4T() public onlyOwner {
        require(totalRaised >= softCap);

         
        _forwardT4T(t4tToken.balanceOf(address(this)));
    }

     
    function finishPreSale() public onlyOwner {
        require(totalRaised >= softCap);
        require(now > endTime);

         
        _forwardFunds(address(this).balance);

         
        _forwardT4T(t4tToken.balanceOf(address(this)));

         
        icsToken.transferOwnership(owner);
        hicsToken.transferOwnership(owner);
    }

     
    function changeTokensOwner() public onlyOwner {
        require(now > endTime);

         
        icsToken.transferOwnership(owner);
        hicsToken.transferOwnership(owner);
    }

     
     
    function _changeRate(uint256 _rate) internal {
        require(_rate != 0);
        rate = _rate;
    }

     
    function _buyIcsTokens(address _beneficiary, uint256 _value) internal {
        uint256 tokensWithBonus = _getTokenNumberWithBonus(_value);

        icsToken.mint(_beneficiary, tokensWithBonus);

        emit IcsTokenPurchase(msg.sender, _beneficiary, tokensWithBonus);
    }

     
    function _buyHicsTokens(address _beneficiary, uint256 _value) internal {
        uint256 tokensWithBonus = _getTokenNumberWithBonus(_value);

        hicsToken.mint(_beneficiary, tokensWithBonus);

        emit HicsTokenPurchase(msg.sender, _beneficiary, tokensWithBonus);
    }

     
     
     
    function _buyTokens(address _beneficiary, uint256 _value) internal {
         
        uint256 valueHics = _value.div(5);   

        if (_value >= hicsTokenPrice
        && hicsToken.totalSupply().add(_getTokenNumberWithBonus(valueHics)) < capHicsToken) {
             
            _buyIcsTokens(_beneficiary, _value - valueHics);
            _buyHicsTokens(_beneficiary, valueHics);
        } else {
             
            _buyIcsTokens(_beneficiary, _value);
        }

         
        uint256 tokensWithBonus = _getTokenNumberWithBonus(_value);
        totalTokensEmitted = totalTokensEmitted.add(tokensWithBonus);
        balances[_beneficiary] = balances[_beneficiary].add(tokensWithBonus);

        totalRaised = totalRaised.add(_value);
    }

     
     
    function buyTokensT4T(address _beneficiary) public saleIsOn {
        require(_beneficiary != address(0));

        uint256 valueT4T = t4tToken.allowance(_beneficiary, address(this));

         
        uint256 value = valueT4T.mul(rateT4T);
        require(value >= minimumInvest);

         
        require(t4tToken.transferFrom(_beneficiary, address(this), valueT4T));

        _buyTokens(_beneficiary, value);

         
        t4tRaised = t4tRaised.add(valueT4T);
        balancesForRefundT4T[_beneficiary] = balancesForRefundT4T[_beneficiary].add(valueT4T);
    }

     
     
     
    function manualBuy(address _to, uint256 _value) public saleIsOn onlyOwner {
        require(_to != address(0));
        require(_value >= minimumInvest);

        _buyTokens(_to, _value);
    }

     
     
     
    function buyTokensWithUpdateRate(address _beneficiary, uint256 _rate) public saleIsOn onlyOwner payable {
        _changeRate(_rate);
        buyTokens(_beneficiary);
    }

     
     
    function buyTokens(address _beneficiary) saleIsOn public payable {
        require(_beneficiary != address(0));

        uint256 weiAmount = msg.value;
        uint256 value = weiAmount.mul(rate);
        require(value >= minimumInvest);

        _buyTokens(_beneficiary, value);

         
        weiRaised = weiRaised.add(weiAmount);
        balancesForRefund[_beneficiary] = balancesForRefund[_beneficiary].add(weiAmount);
    }

    function() external payable {
        buyTokens(msg.sender);
    }
}