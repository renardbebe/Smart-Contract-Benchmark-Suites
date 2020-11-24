 

pragma solidity ^0.4.16;

 
contract Ownable {
    
    address public owner;

     
    function Ownable() public {
        owner = msg.sender;
    }
    
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}

 
contract TenTimesToken is Ownable {
    
    uint256 public totalSupply;
    mapping(address => uint256) startBalances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) startBlocks;
    
    string public constant name = "Ten Times";
    string public constant symbol = "TENT";
    uint32 public constant decimals = 10;

    function TenTimesToken() public {
        totalSupply = 1000000 * 10**uint256(decimals);
        startBalances[owner] = totalSupply;
        startBlocks[owner] = block.number;
        Transfer(address(0), owner, totalSupply);
    }

     
    function fracExp(uint256 k, uint256 q, uint256 n, uint256 p) pure public returns (uint256) {
        uint256 s = 0;
        uint256 N = 1;
        uint256 B = 1;
        for (uint256 i = 0; i < p; ++i) {
            s += k * N / B / (q**i);
            N = N * (n-i);
            B = B * (i+1);
        }
        return s;
    }


     
    function compoundInterest(address tokenOwner) view public returns (uint256) {
        require(startBlocks[tokenOwner] > 0);
        uint256 start = startBlocks[tokenOwner];
        uint256 current = block.number;
        uint256 blockCount = current - start;
        uint256 balance = startBalances[tokenOwner];
        return fracExp(balance, 867598, blockCount, 8) - balance;
    }


     
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return startBalances[tokenOwner] + compoundInterest(tokenOwner);
    }

    
     
    function updateBalance(address tokenOwner) private {
        if (startBlocks[tokenOwner] == 0) {
            startBlocks[tokenOwner] = block.number;
        }
        uint256 ci = compoundInterest(tokenOwner);
        startBalances[tokenOwner] = startBalances[tokenOwner] + ci;
        totalSupply = totalSupply + ci;
        startBlocks[tokenOwner] = block.number;
    }
    

     
    function transfer(address to, uint256 tokens) public returns (bool) {
        updateBalance(msg.sender);
        updateBalance(to);
        require(tokens <= startBalances[msg.sender]);

        startBalances[msg.sender] = startBalances[msg.sender] - tokens;
        startBalances[to] = startBalances[to] + tokens;
        Transfer(msg.sender, to, tokens);
        return true;
    }


     
    function transferFrom(address from, address to, uint256 tokens) public returns (bool) {
        updateBalance(from);
        updateBalance(to);
        require(tokens <= startBalances[from]);

        startBalances[from] = startBalances[from] - tokens;
        allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
        startBalances[to] = startBalances[to] + tokens;
        Transfer(from, to, tokens);
        return true;
    }

     
    function approve(address spender, uint256 tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
   
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    event Approval(address indexed owner, address indexed spender, uint256 tokens);

}