 

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

contract IERC20 {

    function totalSupply() public constant returns (uint256);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public;
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) public;
    function allowance(address owner, address spender) public constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract BriskCoin is IERC20 {

    using SafeMath for uint256;

     
    string public name = "BriskCoin";
    string public symbol = "BSK";
    uint public decimals = 18;

    uint public _totalSupply = 100000000000e18;

    uint public _icoSupply = 70000000000e18;  

    uint public _futureSupply = 30000000000e18;  

     
    mapping (address => uint256) balances;

     
    mapping (address => mapping(address => uint256)) allowed;

    uint256 public startTime;

     
    address public owner;

     
    uint public PRICE = 400000;

    uint public maxCap = 70000000000e18 ether;  

     
    uint256 public fundRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
     
     
    function BriskCoin() public payable {
        startTime = now;
        owner = msg.sender;

        balances[owner] = _totalSupply; 
    }

     
     
    function () public payable {
        tokensale(msg.sender);
    }

     
     
     
    function tokensale(address recipient) public payable {
        require(recipient != 0x0);

        uint256 weiAmount = msg.value;
        uint tokens = weiAmount.mul(getPrice());

        require(_icoSupply >= tokens);

        balances[owner] = balances[owner].sub(tokens);
        balances[recipient] = balances[recipient].add(tokens);

        _icoSupply = _icoSupply.sub(tokens);

        TokenPurchase(msg.sender, recipient, weiAmount, tokens);
		if ( tokens == 0 ) {
		recipient.transfer(msg.value);
		} else {
		owner.transfer(msg.value);
}    }

     
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

     
     
     
    function balanceOf(address who) public constant returns (uint256) {
        return balances[who];
    }

     
    function sendFutureSupplyToken(address to, uint256 value) public onlyOwner {
        require (
            to != 0x0 && value > 0 && _futureSupply >= value
        );

        balances[owner] = balances[owner].sub(value);
        balances[to] = balances[to].add(value);
        _futureSupply = _futureSupply.sub(value);
        Transfer(owner, to, value);
    }

     
     
     
     
    function transfer(address to, uint256 value) public {
        require (
            balances[msg.sender] >= value && value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public {
        require (
            allowed[from][msg.sender] >= value && balances[from] >= value && value > 0
        );
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
    }

     
     
     
     
     
    function approve(address spender, uint256 value) public {
        require (
            balances[msg.sender] >= value && value > 0
        );
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
    }

     
     
     
     
    function allowance(address _owner, address spender) public constant returns (uint256) {
        return allowed[_owner][spender];
    }

     
     
    function getPrice() public constant returns (uint result) {
        if ( now >= startTime  && now <= startTime + 6 days) {
    	    return PRICE.mul(2);
    	} else if ( now >= startTime + 16 days  && now <= startTime + 31 days) {
    	    return PRICE.mul(35).div(20);
    	} else if ( now >= startTime + 41 days  && now <= startTime + 51 days) {
    	    return PRICE.mul(5).div(4);
    	} else if ( now >= startTime + 61 days && now <= startTime + 66 days) {
    	    return PRICE;
    	} else {
    	    return 0;
    	}
    }

}