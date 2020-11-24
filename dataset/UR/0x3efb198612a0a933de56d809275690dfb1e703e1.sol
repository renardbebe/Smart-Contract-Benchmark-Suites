 

pragma solidity ^0.4.17;

 
 
 
 
 
 
 

 
 
 
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


 
 
 
contract ERCX20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
 
contract EdelRostenCoin is ERCX20Interface {
    
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address public owner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    function EdelRostenCoin() public {
        symbol = "ERCX";
        name = "Edel Rosten Coin";
        decimals = 18;
        _totalSupply = 122000000 * 10**uint(decimals);
        owner = 0xDeE7D782Fa2645070e3c15CabF8324A0ccceAC78;
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }
    
    function() public payable {
        revert();
    }
    
     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        if(balances[msg.sender] >= tokens && tokens > 0 && to!=address(0)) {
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            Transfer(msg.sender, to, tokens);
            return true;
        } else { return false; }
    }


     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        if(tokens > 0 && spender != address(0)) {
            allowed[msg.sender][spender] = tokens;
            Approval(msg.sender, spender, tokens);
            return true;
        } else { return false; }
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        if (balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens > 0) {
            balances[from] = balances[from].sub(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            balances[to] = balances[to].add(tokens);
            Transfer(from, to, tokens);
            return true;
        } else { return false; }
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

}