 

pragma solidity ^0.4.18;

 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
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


 
 
 
contract Centaure is ERC20Interface, Owned, SafeMath {
    string public  name;
    string public symbol;
    uint8 public decimals;
    uint public _totalSupply;
    uint public _tokens;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

  	struct TokenLock { uint8 id; uint start; uint256 totalAmount;  uint256 amountWithDrawn; uint duration; uint8 withdrawSteps; }

    TokenLock public futureDevLock = TokenLock({
        id: 1,
        start: now,
        totalAmount: 7500000000000000000000000,
        amountWithDrawn: 0,
        duration: 180 days,
        withdrawSteps: 3
    });

    TokenLock public advisorsLock = TokenLock({
        id: 2,
        start: now,
        totalAmount: 2500000000000000000000000,
        amountWithDrawn: 0,
        duration: 180 days,
        withdrawSteps: 1
    });

    TokenLock public teamLock = TokenLock({
        id: 3,
        start: now,
        totalAmount: 6000000000000000000000000,
        amountWithDrawn: 0,
        duration: 180 days,
        withdrawSteps: 6
    });

    function Centaure() public {
        symbol = "CEN";
        name = "Centaure Token";
        decimals = 18;

        _totalSupply = 50000000* 10**uint(decimals);

        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);

        lockTokens(futureDevLock);
        lockTokens(advisorsLock);
        lockTokens(teamLock);
    }

    function lockTokens(TokenLock lock) internal {
        balances[owner] = safeSub(balances[owner], lock.totalAmount);
        balances[address(0)] = safeAdd(balances[address(0)], lock.totalAmount);
        Transfer(owner, address(0), lock.totalAmount);
    }

    function withdrawLockedTokens() external onlyOwner {
        if(unlockTokens(futureDevLock)){
          futureDevLock.start = now;
        }
        if(unlockTokens(advisorsLock)){
          advisorsLock.start = now;
        }
        if(unlockTokens(teamLock)){
          teamLock.start = now;
        }
    }

	function unlockTokens(TokenLock lock) internal returns (bool) {
        uint lockReleaseTime = lock.start + lock.duration;

        if(lockReleaseTime < now && lock.amountWithDrawn < lock.totalAmount) {
            if(lock.withdrawSteps > 1){
                _tokens = safeDiv(lock.totalAmount, lock.withdrawSteps);
            }else{
                _tokens = safeSub(lock.totalAmount, lock.amountWithDrawn);
            }

            balances[owner] = safeAdd(balances[owner], _tokens);
            balances[address(0)] = safeSub(balances[address(0)], _tokens);
            Transfer(address(0), owner, _tokens);

            if(lock.id==1 && lock.amountWithDrawn < lock.totalAmount){
              futureDevLock.amountWithDrawn = safeAdd(futureDevLock.amountWithDrawn, _tokens);
            }
            if(lock.id==2 && lock.amountWithDrawn < lock.totalAmount){
              advisorsLock.amountWithDrawn = safeAdd(advisorsLock.amountWithDrawn, _tokens);
            }
            if(lock.id==3 && lock.amountWithDrawn < lock.totalAmount) {
              teamLock.amountWithDrawn = safeAdd(teamLock.amountWithDrawn, _tokens);
              teamLock.withdrawSteps = 1;
            }
            return true;
        }
        return false;
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
        revert();
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}