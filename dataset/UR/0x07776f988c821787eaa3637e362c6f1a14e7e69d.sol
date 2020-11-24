 

pragma solidity ^0.5.1;

contract Token{

     
     

    string public constant symbol = 'HKD-TIG';
    string public constant name = 'HKD Tigereum';
    uint8 public constant decimals = 2;
    uint public constant _totalSupply = 100000000 * 10**uint(decimals);
    address public owner;
    string public webAddress;

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping(address => uint256)) allowed;

    constructor() public {
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        webAddress = "https://hellotig.com";
    }

    function totalSupply() public pure returns (uint) {
        return _totalSupply;
    }

     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
    function transfer(address to, uint tokens) public returns (bool success) {
        require( balances[msg.sender] >= tokens && tokens > 0 );
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require( allowed[from][msg.sender] >= tokens && balances[from] >= tokens && tokens > 0 );
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

     
    function approve(address sender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][sender] = tokens;
        emit Approval(msg.sender, sender, tokens);
        return true;
    }

     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _to, uint256 _amount);
}