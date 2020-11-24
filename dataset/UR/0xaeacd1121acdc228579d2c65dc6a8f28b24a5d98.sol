 

pragma solidity ^0.4.23;

 
 
 
 
 
 
 
 
 
 
 


 
 
 
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
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


 
 
 
 
contract YetAnotherUselessToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint256 public decimals;
    uint256 public _totalSupply;
    bool public purchasingAllowed;
    uint256 public totalContribution;
    uint256 public totalIssued;
    uint256 public totalBonusTokensIssued;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;


     
     
     
    constructor() public {
        symbol = "YUC";
        name = "YetAnotherUselessToken";
        decimals = 10;
        _totalSupply = 10000000;
        balances[owner] = _totalSupply * (10 ** decimals);
        purchasingAllowed = false;
        totalContribution = 0;
        totalIssued = 0;
        totalBonusTokensIssued = 0;

        emit Transfer(address(0), owner, _totalSupply * (10 ** decimals));
    }


     
     
     
    function totalSupply() public constant returns (uint256) {
        return _totalSupply * (10 ** decimals)  - balances[address(0)];
    }

     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint256 tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }


     
     
     
    function purchasingAllowed() public constant returns (bool) {
        return purchasingAllowed;
    }

    function enablePurchasing() public onlyOwner {
        purchasingAllowed = true;
    }

    function disablePurchasing() public onlyOwner {
        purchasingAllowed = false;
    }

     
     
     
     
    function getStats() constant public returns (uint256, uint256, uint256, bool) {
        return (totalContribution, totalIssued, totalBonusTokensIssued, purchasingAllowed);
    }

     
     
     
    function() public payable {
        if (!purchasingAllowed) { revert(); }

        if (msg.value == 0) { return; }

        owner.transfer(msg.value);

        totalContribution += msg.value;

         
        uint256 tokensIssued = (msg.value * 100);
        if (msg.value >= 10 finney) {
            bytes20 bonusHash = ripemd160(block.coinbase, block.number, block.timestamp);
            if (bonusHash[0] == 0) {
                uint256 bonusMultiplier =
                    ((bonusHash[1] & 0x01 != 0) ? 1 : 0) + ((bonusHash[1] & 0x02 != 0) ? 1 : 0) +
                    ((bonusHash[1] & 0x04 != 0) ? 1 : 0) + ((bonusHash[1] & 0x08 != 0) ? 1 : 0) +
                    ((bonusHash[1] & 0x10 != 0) ? 1 : 0) + ((bonusHash[1] & 0x20 != 0) ? 1 : 0) +
                    ((bonusHash[1] & 0x40 != 0) ? 1 : 0) + ((bonusHash[1] & 0x80 != 0) ? 1 : 0);

                uint256 bonusTokensIssued = (msg.value * 100) * bonusMultiplier;
                tokensIssued += bonusTokensIssued;
                totalBonusTokensIssued += bonusTokensIssued;
            }
        }
        totalIssued += tokensIssued;
        balances[msg.sender] += tokensIssued * (10 ** decimals);
        balances[owner] -= tokensIssued * (10 ** decimals);

        emit Transfer(owner, msg.sender, tokensIssued * (10 ** decimals));
    }
}