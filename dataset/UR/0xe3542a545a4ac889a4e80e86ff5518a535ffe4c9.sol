 

pragma solidity ^0.4.21;

 

 


contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract TokenHolder {
    address public tokenAddress;
    uint public holdAmount;
    ERC20 public Token;
    mapping (address => uint256) public heldTokens;
    mapping (address => uint) public heldTimeline;
    event Deposit(address from, uint256 amount);
    event Withdraw(address from, uint256 amount);

    function TokenHolder(address token) public {
        tokenAddress = token;
        Token = ERC20(token);
        holdAmount = 1;
    }

    function() payable {
        revert();
    }

     
    function approvedAmount(address _from) public constant returns (uint256) {
        return Token.allowance(_from, this);
    }

     
    function userBalance(address _owner) public constant returns (uint256) {
        return heldTokens[_owner];
    }

     
    function userHeldTill(address _owner) public constant returns (uint) {
        return heldTimeline[_owner];
    }

     
    function totalBalance() public constant returns (uint) {
        return Token.balanceOf(this);
    }

     
    function depositTokens(uint256 amount) external {
        require(Token.allowance(msg.sender, this) >= amount);
        Token.transferFrom(msg.sender, this, amount);
        heldTokens[msg.sender] += amount;
        heldTimeline[msg.sender] = block.number + holdAmount;
        Deposit(msg.sender, amount);
    }

     
    function withdrawTokens(uint256 amount) external {
        uint256 held = heldTokens[msg.sender];
        uint heldBlock = heldTimeline[msg.sender];
        require(held >= 0 && held >= amount);
        require(block.number >= heldBlock);
        heldTokens[msg.sender] -= amount;
        heldTimeline[msg.sender] = 0;
        Withdraw(msg.sender, amount);
        Token.transfer(msg.sender, amount);
    }
    
}