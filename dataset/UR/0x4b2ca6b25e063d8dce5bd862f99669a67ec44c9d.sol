 

pragma solidity 0.4.19;

contract ERC20Interface {
    function totalSupply() constant public returns (uint256 total);

    function balanceOf(address _who) constant public returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BitandPay is ERC20Interface {
    using SafeMath for uint256;

    string public name = "BitandPay";
    string public symbol = "BNP";
    uint256 public totalSupply = 250000000;

    uint8 public decimals = 0;  

    address public owner;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 public startTime = 1513296000;  
    uint256 public endTime = 1518739199;  
     

    uint256 public price = 1428571428571400 wei;  

    uint256 public weiRaised;

    bool public paused = false;

    uint256 reclaimAmount;

     
    uint256 public cap = 1000000 ether;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function BitandPay() public {
        owner = msg.sender;
        balances[owner] = 250000000;
        Transfer(0x0, owner, 250000000);
    }

    function totalSupply() constant public returns (uint256 total) {
        return totalSupply;
    }

    function balanceOf(address _who) constant public  returns (uint256 balance) {
        return balances[_who];
    }

    function transfer(address _to, uint256 _value) whenNotPaused public returns (bool success) {
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool success) {
        require(_to != address(0));

        var _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) whenNotPaused public returns (bool success) {
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseApproval (address _spender, uint _addedValue) whenNotPaused public
    returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) whenNotPaused public
    returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    event Mint(address indexed to, uint256 amount);

    function mint(address _to, uint256 _amount) onlyOwner public returns (bool success) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    function () payable public {
        buyTokens(msg.sender);
    }

    function buyTokens(address purchaser) payable whenNotPaused public {
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(price);
        require(balances[this] > tokens);

         
        weiRaised = weiRaised.add(weiAmount);

        balances[purchaser] = balances[purchaser].add(tokens);   
        balances[this] = balances[this].sub(tokens);             
        Transfer(this, purchaser, tokens);                       
        TokenPurchase(purchaser, weiAmount, tokens);
    }

    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool withinCap = weiRaised.add(msg.value) <= cap;
        return withinPeriod && nonZeroPurchase && withinCap;
    }

    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= cap;
        return now > endTime || capReached;
    }

    function changeCap(uint256 _cap) onlyOwner public {
        require(_cap > 0);
        cap = _cap;
    }

    event Price(uint256 value);

    function changePrice(uint256 _price) onlyOwner public {
        price = _price;
        Price(price);
    }

    event Pause();

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    event Unpause();

    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }

    function destroy() onlyOwner public {
        selfdestruct(owner);
    }

    function destroyAndSend(address _recipient) onlyOwner public {
        selfdestruct(_recipient);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwnership(address newOwner) onlyOwner public {
       	owner = newOwner;
        OwnershipTransferred(owner, newOwner);
    }

    function reclaimToken(ERC20Interface token) external onlyOwner {
        reclaimAmount = token.balanceOf(this);
        token.transfer(owner, reclaimAmount);
        reclaimAmount = 0;
    }

    function withdrawToOwner(uint256 _amount) onlyOwner public {
        require(this.balance >= _amount);
        owner.transfer(_amount);
    }

    function withdrawToAdress(address _to, uint256 _amount) onlyOwner public {
        require(_to != address(0));
        require(this.balance >= _amount);
        _to.transfer(_amount);
    }
}

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