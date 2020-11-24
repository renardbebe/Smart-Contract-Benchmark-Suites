 

pragma solidity 0.4.21;

 
 
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
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


 
 
 
contract Owned {
    address public owner;
    
    function Owned() public{
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

 
 
 
contract Whitelist is Owned {
    mapping (address => WElement) public whitelist;
    mapping (address => RWElement) public regulatorWhitelist;
    
    event LogAddressEnabled(address indexed who);
    event LogAddressDisabled(address indexed who);
    event LogRegulatorEnabled(address indexed who);
    event LogRegulatorDisabled(address indexed who);
    
    struct WElement{
        bool enable;
        address regulator;
    }
    
    struct RWElement{
        bool enable;
        string name;
    }
    
    modifier onlyWhitelisted() {
        whitelisted(msg.sender);
        _;
    }
    
    modifier onlyRegulator() {
        require(regulatorWhitelist[msg.sender].enable);
        _;
    }
    
    function whitelisted(address who) view internal{
        require(whitelist[who].enable);
        require(regulatorWhitelist[whitelist[who].regulator].enable);
    }
    
    function enableRegulator(address who, string _name) onlyOwner public returns (bool success){
        require(who!=address(0));
        require(who!=address(this));
        regulatorWhitelist[who].enable = true;
        regulatorWhitelist[who].name = _name;
        emit LogRegulatorEnabled(who);
        return true;
    }
    
    function disableRegulator(address who) onlyOwner public returns (bool success){
        require(who!=owner);
        regulatorWhitelist[who].enable = false;
        emit LogRegulatorDisabled(who);
        return true;
    }
    
     
    function enableAddress(address who) onlyRegulator public returns (bool success){
        require(who!=address(0));
        require(who!=address(this));
        whitelist[who].enable = true;
        whitelist[who].regulator = msg.sender;
        emit LogAddressEnabled(who);
        return true;
    }
     
    function disableAddress(address who) onlyRegulator public returns (bool success){
        require(who!=owner);
        require(whitelist[who].regulator != address(0));
        whitelist[who].enable = false;
        emit LogAddressDisabled(who);
        return true;
    }
}

contract Marcellocoin is ERC20Interface, Whitelist{
    using SafeMath for uint256;
    
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
     
     
     

    function Marcellocoin() public {
        symbol = "MARCI";
        name = "Marcellocoin is the future";
        decimals = 10;
        _totalSupply = 500000000 * 10**uint256(decimals);
        balances[owner] = _totalSupply;
        
        enableRegulator(owner, "Marcellocoin Owner");
        enableAddress(owner);
        emit Transfer(address(0), owner, _totalSupply);
    }
    
     
     
     
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }
    
     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint256 tokens) onlyWhitelisted public returns (bool success){
        whitelisted(to);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
    function approve(address spender, uint256 tokens) onlyWhitelisted public returns (bool success) {
        whitelisted(spender);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint256 tokens) onlyWhitelisted public returns (bool success) {
        whitelisted(from);
        whitelisted(to);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
     
     
     
    function () public payable {
        revert();
    }

}