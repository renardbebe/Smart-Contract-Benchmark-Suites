 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 
 
 


 
 
 
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
     
    event Burn(address indexed from, uint256 value);
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
         
        owner = 0x59411912Be94A0B94B81550552b9f3355488790e;
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
 
 
 
contract EXVToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    constructor() public {
        symbol = "EXV";
        name = "EXV Exvillage Money";
        decimals = 18;
        _totalSupply = 2400000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != address(0x0));
         
        require(balanceOf(_from) >= _value);
         
        require(balanceOf(_to) + _value >= balanceOf(_to));
         
        uint previousBalances = balanceOf(_from) + balanceOf(_to);
         
        balances[_from] = balances[_from].sub(_value);
         
        balances[_to] = balances[_to].add(_value);
         
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf(_from) + balanceOf(_to) == previousBalances);
    }
    
     
     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
     


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance(_from, msg.sender));      
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf(msg.sender) >= _value);    
        balances[msg.sender] -= _value;             
        _totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }



     
     
     
     
       
     


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}