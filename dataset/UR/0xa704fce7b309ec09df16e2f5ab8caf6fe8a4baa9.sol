 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


 
 
 
library SafeMath {
    
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        require(c / _a == _b, "Muliply overflow error.");
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, "Divide by zero error."); 
        uint256 c = _a / _b;
        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, "Subtraction overflow error.");
        uint256 c = _a - _b;
        return c;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, "Addition overflow error.");
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Mod overflow error");
        return a % b;
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
        require(msg.sender == owner, "Not contract owner.");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner, "Not new contract owner.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
 
 
contract AgriChainToken is ERC20Interface, Owned {
    
    using SafeMath for uint;

    uint256 constant public MAX_SUPPLY = 1000000000000000000000000000;  

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

     
    bool public isAllowingTransfers;

     
    mapping (address => bool) public administrators;

     
    modifier allowingTransfers() {
        require(isAllowingTransfers, "Contract currently not allowing transfers.");
        _;
    }

     
    modifier onlyAdmin() {
        require(administrators[msg.sender], "Not contract administrator.");
        _;
    }

     
    event Burn(address indexed burner, uint256 value); 

     
    event AllowTransfers ();
    event DisallowTransfers ();

     
     
     
    constructor(uint initialTokenSupply) public {
        symbol = "AGRI";
        name = "AgriChain Utility Token";
        decimals = 18;
        _totalSupply = initialTokenSupply * 10**uint(decimals);

        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public allowingTransfers returns (bool success) {
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

     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public allowingTransfers returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
    function () public payable {
        revert("Contract does not accept ETH.");
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyAdmin returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

     
     
     
     
    function mintTokens(uint256 _value) public onlyAdmin {
        require(_totalSupply.add(_value) <= MAX_SUPPLY, "Cannot mint greater than maximum supply.");
        balances[msg.sender] = balances[msg.sender].add(_value);
        _totalSupply = _totalSupply.add(_value);
        emit Transfer(0, msg.sender, _value);      
    }    

     
     
     
    function burn(uint256 _value) public onlyAdmin {
        require(_value <= balances[msg.sender], "Burn value exceeds balance.");
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(burner, _value);
    }

     
     
     
    function allowTransfers() public onlyAdmin {
        isAllowingTransfers = true;
        emit AllowTransfers();
    }

     
     
     
    function disallowTransfers() public onlyAdmin {
        isAllowingTransfers = false;
        emit DisallowTransfers();
    }

     
     
     
    function addAdministrator(address _admin) public onlyOwner {
        administrators[_admin] = true;
    }

     
     
     
    function removeAdministrator(address _admin) public onlyOwner {
        administrators[_admin] = false;
    }
}