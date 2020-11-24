 

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


 
 
 
contract TextToken is ERC20Interface, Owned, SafeMath {
    string public  name;
    string public symbol;
    uint8 public decimals;
    uint public _totalSupply;
    uint public _tokens;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

  	struct TokenLock {
      uint8 id;
      uint start;
      uint256 totalAmount;
      uint256 amountWithDrawn;
      uint duration;
      uint8 withdrawSteps;
    }

    TokenLock public futureLock = TokenLock({
        id: 1,
        start: now,
        totalAmount: 7000000000000000000000000000,
        amountWithDrawn: 0,
        duration: 10 minutes,
        withdrawSteps: 8
    });

    function TextToken() public {
        symbol = "TEXT";
        name = "DeathNode Token";
        decimals = 18;

        _totalSupply = 10000000000* 10**uint(decimals);

        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);

        lockTokens(futureLock);
    }

    function lockTokens(TokenLock lock) internal {
        balances[owner] = safeSub(balances[owner], lock.totalAmount);
        balances[address(0)] = safeAdd(balances[address(0)], lock.totalAmount);
        Transfer(owner, address(0), lock.totalAmount);
    }

    function withdrawLockedTokens() external onlyOwner {
        if(unlockTokens(futureLock)){
          futureLock.start = now;
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

            if(lock.id==1 && lock.amountWithDrawn < lock.totalAmount){
              futureLock.amountWithDrawn = safeAdd(futureLock.amountWithDrawn, _tokens);
            }

            balances[owner] = safeAdd(balances[owner], _tokens);
            balances[address(0)] = safeSub(balances[address(0)], _tokens);
            Transfer(address(0), owner, _tokens);

            return true;
        }
        return false;
    }

     
     
     
    function batchTransfer(address[] _recipients, uint _tokens) onlyOwner returns (bool) {
        require( _recipients.length > 0);
        uint total = 0;

        require(total <= balances[msg.sender]);

        uint64 _now = uint64(now);
        for(uint j = 0; j < _recipients.length; j++){

            balances[_recipients[j]] = safeAdd(balances[_recipients[j]], _tokens);
            balances[owner] = safeSub(balances[owner], _tokens);
            Transfer(owner, _recipients[j], _tokens);

        }

        return true;
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