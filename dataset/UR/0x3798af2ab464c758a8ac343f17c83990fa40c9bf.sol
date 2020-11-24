 

pragma solidity ^0.4.25;

 
 
 
 
 
 
 
 
 
 
 


 
 
 
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


 
 
 
 
contract ClaimsToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;
    uint public maxTotalSupply;
    uint public unitsPerTransaction;
    uint public tokensDistributed;
    uint public numDistributions;
    uint public numDistributionsRemaining;
    
    address public fundsWallet;  
    address public foundationWallet;
    address public claimPool;
    uint public initialFoundationSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    constructor() public {   

        fundsWallet      = 0x0000000000000000000000000000000000000000; 
        claimPool        = 0x0000000000000000000000000000000000000001;

        foundationWallet = 0x139E766c7c7e00Ed7214CeaD039C4b782AbD3c3e;
        
         
        balances[fundsWallet] = 12000000000000000000000000;  

        totalSupply           = 12000000000000000000000000;
        maxTotalSupply        = 36000000000000000000000000;
        unitsPerTransaction   = 2400000000000000000000;

        name = "Claims";                                 
        decimals = 18;                                              
        symbol = "CLM";  

        
         
        initialFoundationSupply = 1500000000000000000000000;
        
        balances[foundationWallet] = safeAdd(balances[foundationWallet], initialFoundationSupply);
        balances[fundsWallet] = safeSub(balances[fundsWallet], initialFoundationSupply);

        emit Transfer(fundsWallet, foundationWallet, initialFoundationSupply);
        
        tokensDistributed = initialFoundationSupply;   
        
         
        numDistributionsRemaining = (totalSupply - tokensDistributed) / unitsPerTransaction;   
        numDistributions = 1;       
    }


     
     
     
    function totalSupply() public constant returns (uint) {
        return totalSupply;
    }
    
     
     
     
    function maxTotalSupply() public constant returns (uint) {
        return maxTotalSupply;
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
    function increaseClaimPool() private returns (bool success) { 
        if (totalSupply < maxTotalSupply){
             
            balances[claimPool] = safeAdd(balances[claimPool], safeDiv(unitsPerTransaction, 10));
            totalSupply = safeAdd(totalSupply, safeDiv(unitsPerTransaction, 10));
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
    function mint() public returns (bool success) {

        uint maxReward = safeDiv(balances[msg.sender], 10);

        uint reward = maxReward;

        if(balances[claimPool] < reward){
            reward = balances[claimPool];
        }

        if (reward > 0){

            balances[claimPool] = safeSub(balances[claimPool], reward);

            balances[msg.sender] = safeAdd(balances[msg.sender], safeDiv(safeMul(reward, 9), 10));
            balances[foundationWallet] = safeAdd(balances[foundationWallet], safeDiv(reward, 10));


            emit Transfer(claimPool, msg.sender, safeDiv(safeMul(reward, 9), 10));
            emit Transfer(claimPool, foundationWallet, safeDiv(reward, 10));

            return true;

        } else {
             
            return false;
        }
    }


     
     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        
        balances[to] = safeAdd(balances[to], safeDiv(safeMul(tokens, 99),100));
        balances[claimPool] = safeAdd(balances[claimPool], safeDiv(tokens,100));
        
        if (tokens > 0){
            increaseClaimPool(); 
        
            emit Transfer(msg.sender, to, safeDiv(safeMul(tokens, 99), 100));
            emit Transfer(msg.sender, claimPool, safeDiv(tokens, 100));

        } else {
             
            mint();
        }

        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
  
        if (tokens > 0){
            increaseClaimPool();
        }
        
        emit Transfer(from, to, safeDiv(safeMul(tokens, 99), 100));
        emit Transfer(from, claimPool, safeDiv(tokens, 100));
        
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
    
         
        if(numDistributionsRemaining > 0 && balances[msg.sender] == 0 
          && balances[fundsWallet] >= unitsPerTransaction){

             
            uint tokens = unitsPerTransaction;
            
            balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
            balances[fundsWallet] = safeSub(balances[fundsWallet], tokens);

            tokensDistributed = safeAdd(tokensDistributed, tokens);
            numDistributions = safeAdd(numDistributions, 1);
            
            numDistributionsRemaining = safeSub(numDistributionsRemaining, 1);
            
            emit Transfer(fundsWallet, msg.sender, tokens);
        } else {
             
            mint();
        }
        
         
        msg.sender.transfer(msg.value);
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}