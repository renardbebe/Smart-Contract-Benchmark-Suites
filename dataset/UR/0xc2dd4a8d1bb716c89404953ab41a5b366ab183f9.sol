 

pragma solidity ^0.4.24;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 
 
 
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

 
 
 
contract Bitway is ERC20 {
    
    using SafeMath for uint;

    string public name = "Bitway";
    string public symbol = "BTWX";
    uint public totalSupply = 0;
    uint8 public decimals = 18;
    uint public RATE = 1000;
    
    uint multiplier = 10 ** uint(decimals);
    uint million = 10 ** 6;
    uint millionTokens = 1 * million * multiplier;
    
    uint constant stageTotal = 5;
    uint stage = 0;
    uint [stageTotal] targetSupply = [
         1 * millionTokens,
         2 * millionTokens,
         5 * millionTokens,
         10 * millionTokens,
         21 * millionTokens
    ];
    
    address public owner;
    bool public completed = true;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() public {
    owner = msg.sender;
    supplyTokens(millionTokens);
    }
    
     
     
     
    function () public payable {
        createTokens();
    }
    
     
     
     
    function currentStage() public constant returns (uint) {
        return stage + 1;
    }
    
     
     
     
    function maxSupplyReached() public constant returns (bool) {
        return stage >= stageTotal;
    }
    
     
     
     
    function createTokens() public payable {
        require(!completed);
        supplyTokens(msg.value.mul((15 - stage) * RATE / 10)); 
        owner.transfer(msg.value);
    }
    
     
     
     
    function setComplete(bool _completed) public {
        require(msg.sender == owner);
        completed = _completed;
    }
    
     
     
     
    function totalSupply() public view returns (uint) {
        return totalSupply;
    }

     
     
     
    function balanceOf(address tokenOwner) public view returns (uint) {
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

     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
     
     
     
    function supplyTokens(uint tokens) private {
        require(!maxSupplyReached());
        balances[msg.sender] = balances[msg.sender].add(tokens);
        totalSupply = totalSupply.add(tokens);
        if (totalSupply >= targetSupply[stage]) {
            stage += 1;
        }
        emit Transfer(address(0), msg.sender, tokens);
    }

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}