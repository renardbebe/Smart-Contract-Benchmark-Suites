 

pragma solidity >=0.4.22 <0.6.0;

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

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Only the owner of the contract can use this function");
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

contract iZiCoin is ERC20Interface, Owned {
        
    using SafeMath for uint;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
   
    uint _totalSupply;
    
    string public symbol;
    string public  name;
    uint8 public decimals;

    event Desapproval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    constructor() public {
        symbol = "IZC";
        name = "iZiCoin";
        decimals = 8;
        _totalSupply = 100000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    function totalSupply() public view returns (uint){
        return _totalSupply.sub(balances[address(0)]);
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance){
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
        return allowed[tokenOwner][spender];        
    }
    
    function transfer(address to, uint tokens) public returns (bool success){
        require(balances[msg.sender] >= tokens,"Insufficient balance");
        require(tokens > 0,"Can't send a negative amount of tokens");
        require(to != address(0x0),"Can't send to a null address");
        executeTransfer(msg.sender,to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function approve(address spender, uint tokens) public returns (bool success){
        require(balances[msg.sender] >= tokens,"Insufficient amount of tokens");
        require(spender != address(0x0),"Can't approve a null address");
        require(spender != msg.sender,"Can't approve tokens to the same address");
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(tokens);
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function desapprove(address spender, uint tokens) public returns (bool success){
        require(tokens <= allowed[msg.sender][spender],"Can't desapprove more than the approved ");
        require(spender != address(0x0),"Can't desapprove a null address");
        allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(tokens);
        emit Desapproval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        require(balances[from] >= tokens,"Insufficient balance");
        require(allowed[from][msg.sender] >= tokens,"Insufficient allowance");
        require(tokens > 0,"Can't send a negative amount of tokens");
        require(to != address(0x0),"Can't send to a null address");
        require(from != address(0x0),"Can't send from a null address");
        executeTransfer(from, to, tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function executeTransfer(address from,address to, uint tokens) private{
        require(to != msg.sender,"Can't send tokens to the same address");
        uint previousBalances = balances[from] + balances[to];
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        assert((balances[from] + balances[to] == previousBalances));
    }
  
    function () external payable {
        revert();
    }

}