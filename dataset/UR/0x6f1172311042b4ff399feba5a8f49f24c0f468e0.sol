 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 


 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
 
 
 
contract sethToken is ERC20Interface, Owned, SafeMath {
    string public symbol = "seth";
    string public TokenOwner = "Seth Simbulan";
    string public  name = "sethCoin";
    uint8 public decimals = 12;
    uint public _totalSupply = 1000000000000 * 10 ** uint256(decimals);

	uint256 public price = 10000;
	bool public started = true;
	address public ceo = 0x46c6CDc24606eF220c38c12AF8D129026072F829;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

	 
	uint256 public weiRaised;

     
     
     
    function sethToken() public {
        balances[ceo] = _totalSupply;
        Transfer(address(0), ceo, _totalSupply);
    }

	function startSale(){
		if (msg.sender != owner) throw;
		started = true;
	}

	function stopSale(){
		if(msg.sender != owner) throw;
		started = false;
	}

	function setPrice(uint256 _price){
		if(msg.sender != owner) throw;
		price = _price;
	}

	function changeWallet(address _wallet){
		if(msg.sender != owner) throw;
		ceo = _wallet;
	}

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function () public payable {
        require(validPurchase());

		uint256 weiAmount = msg.value;
		uint256 tokens;

		tokens = weiAmount * price / (10 ** 18) * (10 ** 12);

		weiRaised = safeAdd(weiRaised, weiAmount);

        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        balances[ceo] = safeSub(balances[ceo], tokens);

        Transfer(ceo, msg.sender, tokens);
        ceo.transfer(msg.value);
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

	function validPurchase() internal constant returns (bool) {
		bool withinPeriod = started;
		bool nonZeroPurchase = msg.value != 0;
		return withinPeriod && nonZeroPurchase;
	}
}