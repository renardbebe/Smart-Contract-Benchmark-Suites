 

pragma solidity ^0.4.24;
 
 
contract ERC20 {
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function approve(address _spender, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
}
 
contract Owned {
    address public owner;
     
    constructor() public {
        owner = msg.sender;
    }
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
     
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         
        return c;
    }
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }
    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }
    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        uint256 c = a - b;
        return c;
    }
}
contract HashRush is ERC20, Owned {
     
    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint256 public decimals;
     
    uint256 totalSupply_;
    uint256 multiplier;
     
    mapping (address => uint256) balance;
    mapping (address => mapping (address => uint256)) allowed;
     
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size.add(4)) revert();
        _;
    }
    constructor(string tokenName, string tokenSymbol, uint8 decimalUnits, uint256 decimalMultiplier) public {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        multiplier = decimalMultiplier;
    }
     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
     
    function balanceOf(address _owner) public view returns (uint256) {
        return balance[_owner];
    }
     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        require(_to != address(0));
        require(_value <= balance[msg.sender]);
        if ((balance[msg.sender] >= _value)
            && (balance[_to].add(_value) > balance[_to])
        ) {
            balance[msg.sender] = balance[msg.sender].sub(_value);
            balance[_to] = balance[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool) {
        require(_to != address(0));
        require(_value <= balance[_from]);
        require(_value <= allowed[_from][msg.sender]);
        if ((balance[_from] >= _value) && (allowed[_from][msg.sender] >= _value) && (balance[_to].add(_value) > balance[_to])) {
            balance[_to] = balance[_to].add(_value);
            balance[_from] = balance[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
}
contract HashRushICO is Owned, HashRush {
     
    using SafeMath for uint256;
     
    address public multiSigWallet;
    uint256 public amountRaised;
    uint256 public startTime;
    uint256 public stopTime;
    uint256 public fixedTotalSupply;
    uint256 public price;
    uint256 public minimumInvestment;
    uint256 public crowdsaleTarget;
     
    bool crowdsaleClosed = true;
    string tokenName = "HashRush";
    string tokenSymbol = "RUSH";
    uint256 multiplier = 100000000;
    uint8 decimalUnits = 8;
     
    constructor()
        HashRush(tokenName, tokenSymbol, decimalUnits, multiplier) public {
            multiSigWallet = msg.sender;
            fixedTotalSupply = 70000000;
            fixedTotalSupply = fixedTotalSupply.mul(multiplier);
    }
     
    function () public payable {
        require(!crowdsaleClosed
            && (now < stopTime)
            && (msg.value >= minimumInvestment)
            && (totalSupply_.add(msg.value.mul(price).mul(multiplier).div(1 ether)) <= fixedTotalSupply)
            && (amountRaised.add(msg.value.div(1 ether)) <= crowdsaleTarget)
        );
        address recipient = msg.sender;
        amountRaised = amountRaised.add(msg.value.div(1 ether));
        uint256 tokens = msg.value.mul(price).mul(multiplier).div(1 ether);
        totalSupply_ = totalSupply_.add(tokens);
    }
     
    function mintToken(address target, uint256 amount) onlyOwner public returns (bool) {
        require(amount > 0);
        require(totalSupply_.add(amount) <= fixedTotalSupply);
        uint256 addTokens = amount;
        balance[target] = balance[target].add(addTokens);
        totalSupply_ = totalSupply_.add(addTokens);
        emit Transfer(0, target, addTokens);
        return true;
    }
     
    function setPrice(uint256 newPriceperEther) onlyOwner public returns (uint256) {
        require(newPriceperEther > 0);
        price = newPriceperEther;
        return price;
    }
     
    function setMultiSigWallet(address wallet) onlyOwner public returns (bool) {
        multiSigWallet = wallet;
        return true;
    }
     
    function setMinimumInvestment(uint256 minimum) onlyOwner public returns (bool) {
        minimumInvestment = minimum;
        return true;
    }
     
    function setCrowdsaleTarget(uint256 target) onlyOwner public returns (bool) {
        crowdsaleTarget = target;
        return true;
    }
     
    function startSale(uint256 saleStart, uint256 saleStop, uint256 salePrice, address setBeneficiary, uint256 minInvestment, uint256 saleTarget) onlyOwner public returns (bool) {
        require(saleStop > now);
        startTime = saleStart;
        stopTime = saleStop;
        amountRaised = 0;
        crowdsaleClosed = false;
        setPrice(salePrice);
        setMultiSigWallet(setBeneficiary);
        setMinimumInvestment(minInvestment);
        setCrowdsaleTarget(saleTarget);
        return true;
    }
     
    function stopSale() onlyOwner public returns (bool) {
        stopTime = now;
        crowdsaleClosed = true;
        return true;
    }
}