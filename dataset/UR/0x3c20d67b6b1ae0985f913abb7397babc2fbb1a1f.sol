 

pragma solidity ^0.4.23;


 
 
 
 
 
 
 
 
 
 
 

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
     
     
     
contract ICEDIUM is ERC20Interface{
    string public name = "ICEDIUM";
    string public symbol = "ICD";
    uint8 public decimals = 18;
     
    uint public supply; 
    address public founder;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;
     
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
     
     
     
    constructor() public{
        supply = 300000000000000000000000000;
        founder = msg.sender;
        balances[founder] = supply;
    }
     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns(uint){
        return allowed[tokenOwner][spender];
    }
     
     
     
     
    function approve(address spender, uint tokens) public returns(bool){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns(bool){
        require(allowed[from][msg.sender] >= tokens);
        require(balances[from] >= tokens);

        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][msg.sender] -= tokens;

        emit Transfer(from, to, tokens);

        return true;
    }
     
     
     
    function totalSupply() public view returns (uint){
        return supply;
    }
     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance){
        return balances[tokenOwner];
    }
     
     
     
    function transfer(address to, uint tokens) public returns (bool success){
        require(balances[msg.sender] >= tokens && tokens > 0);
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    } 
     
     
     
    function () public payable {
        revert();
    }
}