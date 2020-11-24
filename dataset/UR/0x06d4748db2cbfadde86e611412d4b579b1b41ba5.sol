 

pragma solidity ^0.5.10;

 

 

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

 
 
 

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

 
 
 

contract Owned {

    address payable public owner;
    address payable public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        
        owner = newOwner;
        newOwner = address(0);

        emit OwnershipTransferred(owner, newOwner);
    }
}

 
 
 

contract GoaToken is ERC20Interface, Owned {

    using SafeMath for uint;

    string constant public symbol       = "GOA";
    string constant public name         = "Goa Token";
    uint constant public decimals       = 18;
    uint constant public MAX_SUPPLY     = 1000000 * 10 ** decimals;
    uint constant public ETH_PER_TOKEN  = 0.0000002 ether;
    
    uint _totalSupply;  

    mapping(address => uint) balances;  
    mapping(address => mapping(address => uint)) allowed;
    
    event Minted(address indexed newHolder, uint eth, uint tokens);

     
    constructor() public {
    }

     
     

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

     
     

    function balanceOf(address tokenOwner) public view returns (uint balance) {
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

     
     
     
     

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);

        return true;
    }

     
     
     
     

    function mint(uint fullToken) public payable {
        uint _token = fullToken.mul(10 ** decimals);
        uint _newSupply = _totalSupply.add(_token);
        require(_newSupply <= MAX_SUPPLY, "supply cannot go over 1M");

        uint _ethCost = computeCost(fullToken);
        require(msg.value == _ethCost, "wrong ETH amount for tokens");
        
        owner.transfer(msg.value);
        _totalSupply = _newSupply;
        balances[msg.sender] = balances[msg.sender].add(_token);
        
        emit Minted(msg.sender, msg.value, fullToken);
    }
    
     
     
    
    function computeSum(uint256 a, uint256 b) public pure returns(uint256) {
        uint256 _sumA = a.mul(a.add(1)).div(2);
        uint256 _sumB = b.mul(b.add(1)).div(2);
        return _sumB.sub(_sumA);
    }
    
     
     
    
    function computeCost(uint256 fullToken) public view returns(uint256) {
        uint256 _intSupply = _totalSupply.div(10 ** decimals);
        uint256 _current = fullToken.add(_intSupply);
        uint256 _sum = computeSum(_intSupply, _current);
        return ETH_PER_TOKEN.mul(_sum);
    }
        
     
     

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}