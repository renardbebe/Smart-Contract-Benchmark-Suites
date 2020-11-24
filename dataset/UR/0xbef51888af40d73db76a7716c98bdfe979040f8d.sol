 

pragma solidity ^0.4.21;

 
 
 
 
 
 
 
 
 


 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        assert(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        assert(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        assert(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        assert(b > 0);
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
    function receiveApproval(address from, uint tokens, address token, bytes data) public;
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
 
 
 
contract ZanCoin is ERC20Interface, Owned {
    using SafeMath for uint;
    
     
     
     
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    
     
     
     
    bool public isInPreSaleState;
    bool public isInRoundOneState;
    bool public isInRoundTwoState;
    bool public isInFinalState;
    uint public stateStartDate;
    uint public stateEndDate;
    uint public saleCap;
    uint public exchangeRate;
    
    uint public burnedTokensCount;

    event SwitchCrowdSaleStage(string stage, uint exchangeRate);
    event BurnTokens(address indexed burner, uint amount);
    event PurchaseZanTokens(address indexed contributor, uint eth_sent, uint zan_received);

     
     
     
    function ZanCoin() public {
        symbol = "ZAN";
        name = "ZAN Coin";
        decimals = 18;
        _totalSupply = 17148385 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        
        isInPreSaleState = false;
        isInRoundOneState = false;
        isInRoundTwoState = false;
        isInFinalState = false;
        burnedTokensCount = 0;
    }


     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


     
     
     
    function () public payable {
        uint eth_sent = msg.value;
        uint tokens_amount = eth_sent.mul(exchangeRate);
        
        require(eth_sent > 0);
        require(exchangeRate > 0);
        require(stateStartDate < now && now < stateEndDate);
        require(balances[owner] >= tokens_amount);
        require(_totalSupply - (balances[owner] - tokens_amount) <= saleCap);
        
         
        require(!isInFinalState);
        require(isInPreSaleState || isInRoundOneState || isInRoundTwoState);
        
        balances[owner] = balances[owner].sub(tokens_amount);
        balances[msg.sender] = balances[msg.sender].add(tokens_amount);
        emit PurchaseZanTokens(msg.sender, eth_sent, tokens_amount);
    }
    
     
     
     
    function switchCrowdSaleStage() external onlyOwner {
        require(!isInFinalState && !isInRoundTwoState);
        
        if (!isInPreSaleState) {
            isInPreSaleState = true;
            exchangeRate = 1500;
            saleCap = (3 * 10**6) * (uint(10) ** decimals);
            emit SwitchCrowdSaleStage("PreSale", exchangeRate);
        }
        else if (!isInRoundOneState) {
            isInRoundOneState = true;
            exchangeRate = 1200;
            saleCap = saleCap + ((4 * 10**6) * (uint(10) ** decimals));
            emit SwitchCrowdSaleStage("RoundOne", exchangeRate);
        }
        else if (!isInRoundTwoState) {
            isInRoundTwoState = true;
            exchangeRate = 900;
            saleCap = saleCap + ((5 * 10**6) * (uint(10) ** decimals));
            emit SwitchCrowdSaleStage("RoundTwo", exchangeRate);
        }
        
        stateStartDate = now + 5 minutes;
        stateEndDate = stateStartDate + 7 days;
    }
    
     
     
     
     
    function completeCrowdSale() external onlyOwner {
        require(!isInFinalState);
        require(isInPreSaleState && isInRoundOneState && isInRoundTwoState);
        
        owner.transfer(address(this).balance);
        exchangeRate = 0;
        isInFinalState = true;
        emit SwitchCrowdSaleStage("Complete", exchangeRate);
    }

     
     
     
    function burn(uint amount) public {
        require(amount > 0);
        require(amount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        burnedTokensCount = burnedTokensCount + amount;
        emit BurnTokens(msg.sender, amount);
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}