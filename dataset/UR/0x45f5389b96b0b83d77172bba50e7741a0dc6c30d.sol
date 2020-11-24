 

 

pragma solidity ^0.4.18;

 
 
 

 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
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

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
 
 
 
contract OASToken is ERC20Interface, Owned, SafeMath {
    string public name = "OASCHAIN";
    string public symbol = "OAS";
    uint8 public decimals = 18;
    uint public _totalSupply;
    uint public startDate;
    bool public isLocked;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    function OASToken(uint tokens) public {
        _totalSupply = tokens;
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        isLocked = false;
    }
    
    modifier isNotLocked {
        require(!isLocked);
        _;
    }
    
    function setIsLocked(bool _isLocked) public {
        isLocked = _isLocked;
    }


     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public isNotLocked returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public isNotLocked returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    function () external payable {
        revert();
    }

     
     
     
    function mint(address to, uint value) public onlyOwner returns (bool) {
        require(value > 0);
        _totalSupply = safeAdd(_totalSupply, value);
        balances[to] = safeAdd(balances[to], value);
        Transfer(0, to, value);
        return true;
    }

     
     
     
    function burn(address from, uint value) public onlyOwner returns (bool) {
        require(value > 0);
        require(balances[from] >= value);
        balances[from] = safeSub(balances[from], value);
        _totalSupply = safeSub(_totalSupply, value);
        Transfer(from, 0, value);
        return true;
    }

}