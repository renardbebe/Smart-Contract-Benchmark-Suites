 

pragma solidity ^0.4.11;


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract Ownable {
    address public owner;


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


 
contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }

    modifier onlyInEmergency {
        require(halted);
        _;
    }

     
    function halt() external onlyOwner {
        halted = true;
    }

     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}


 
contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) constant returns (uint256);

    function transfer(address to, uint256 value) returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);

    function transferFrom(address from, address to, uint256 value) returns (bool);

    function approve(address spender, uint256 value) returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


 
contract VeraCoin is StandardToken {

    string public name = "VeraCoin";

    string public symbol = "Vera";

    uint256 public decimals = 18;

    uint256 public INITIAL_SUPPLY = 15700000 * 1 ether;

     
    function VeraCoin() {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
}


contract VeraCoinPreSale is Haltable {
    using SafeMath for uint;

    string public name = "VeraCoin PreSale";

    VeraCoin public token;

    address public beneficiary;

    uint256 public hardCap;

    uint256 public softCap;

    uint256 public collected;

    uint256 public price;

    uint256 public tokensSold = 0;

    uint256 public weiRaised = 0;

    uint256 public investorCount = 0;

    uint256 public weiRefunded = 0;

    uint256 public startTime;

    uint256 public endTime;

    bool public softCapReached = false;

    bool public crowdsaleFinished = false;

    mapping (address => bool) refunded;

    event GoalReached(uint256 amountRaised);

    event SoftCapReached(uint256 softCap);

    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);

    event Refunded(address indexed holder, uint256 amount);

    modifier onlyAfter(uint256 time) {
        require(now >= time);
        _;
    }

    modifier onlyBefore(uint256 time) {
        require(now <= time);
        _;
    }

    function VeraCoinPreSale(
    uint256 _hardCapUSD,
    uint256 _softCapUSD,
    address _token,
    address _beneficiary,
    uint256 _totalTokens,
    uint256 _priceETH,

    uint256 _startTime,
    uint256 _duration
    ) {
        hardCap = _hardCapUSD * 1 ether / _priceETH;
        softCap = _softCapUSD * 1 ether / _priceETH;
        price = _totalTokens * 1 ether / hardCap;

        token = VeraCoin(_token);
        beneficiary = _beneficiary;

        startTime = _startTime;
        endTime = _startTime + _duration * 1 hours;
    }

    function() payable stopInEmergency {
        require(msg.value >= 0.01 * 1 ether);
        doPurchase(msg.sender);
    }

    function refund() external onlyAfter(endTime) {
        require(!softCapReached);
        require(!refunded[msg.sender]);

        uint256 balance = token.balanceOf(msg.sender);
        require(balance > 0);

        uint256 refund = balance / price;
        if (refund > this.balance) {
            refund = this.balance;
        }

        require(msg.sender.send(refund));
        refunded[msg.sender] = true;
        weiRefunded = weiRefunded.add(refund);
        Refunded(msg.sender, refund);
    }

    function withdraw() onlyOwner {
        require(softCapReached);
        require(beneficiary.send(collected));
        token.transfer(beneficiary, token.balanceOf(this));
        crowdsaleFinished = true;
    }

    function doPurchase(address _owner) private onlyAfter(startTime) onlyBefore(endTime) {
        require(!crowdsaleFinished);
        require(collected.add(msg.value) <= hardCap);

        if (!softCapReached && collected < softCap && collected.add(msg.value) >= softCap) {
            softCapReached = true;
            SoftCapReached(softCap);
        }

        uint256 tokens = msg.value * price;

        if (token.balanceOf(msg.sender) == 0) investorCount++;

        collected = collected.add(msg.value);

        token.transfer(msg.sender, tokens);

        weiRaised = weiRaised.add(msg.value);
        tokensSold = tokensSold.add(tokens);

        NewContribution(_owner, tokens, msg.value);

        if (collected == hardCap) {
            GoalReached(hardCap);
        }
    }
}