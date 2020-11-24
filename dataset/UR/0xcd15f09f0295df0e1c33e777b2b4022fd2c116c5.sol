 

 

 

pragma solidity ^0.5.8;


 

 

 

 

 

 


 



 

 

 

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

    event OwnershipTransferred(address indexed _from, address indexed _to);


    constructor() public {

        owner = msg.sender;

    }


    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }


    function transferOwnership(address newOwner) public onlyOwner {

        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);

    }

}

 

 

 
contract Tokenlock is Owned {
    
    uint8 isLocked = 0;        

    event Freezed();
    event UnFreezed();

    modifier validLock {
        require(isLocked == 0);
        _;
    }
    
    function freeze() public onlyOwner {
        isLocked = 1;
        
        emit Freezed();
    }

    function unfreeze() public onlyOwner {
        isLocked = 0;
        
        emit UnFreezed();
    }
}

 

 

 
contract UserLock is Owned {
    
    mapping(address => bool) blacklist;
        
    event LockUser(address indexed who);
    event UnlockUser(address indexed who);

    modifier permissionCheck {
        require(!blacklist[msg.sender]);
        _;
    }
    
    function lockUser(address who) public onlyOwner {
        blacklist[who] = true;
        
        emit LockUser(who);
    }

    function unlockUser(address who) public onlyOwner {
        blacklist[who] = false;
        
        emit UnlockUser(who);
    }
}


 

 

 

 

contract GENCOCORP is ERC20Interface, Tokenlock, UserLock {

    using SafeMath for uint;

    string public symbol;

    string public  name;

    uint8 public decimals;

    uint _totalSupply;


    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;



     

     

     

    constructor() public {

        symbol = "GNCC";

        name = "www.gencocorp.com";

        decimals = 18;

        _totalSupply = 100000000 * 10**uint(decimals);

        balances[owner] = _totalSupply;

        emit Transfer(address(0), owner, _totalSupply);
    }



     

     

     

    function totalSupply() public view returns (uint) {

        return _totalSupply.sub(balances[address(0)]);

    }



     

     

     

    function balanceOf(address tokenOwner) public view returns (uint balance) {

        return balances[tokenOwner];

    }



     

     

     

     

     

    function transfer(address to, uint tokens) public validLock permissionCheck returns (bool success) {

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;

    }



     

     

     

     

     

     

    function approve(address spender, uint tokens) public validLock permissionCheck returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;

    }



     

     

     

     

     

     

     

     

     

    function transferFrom(address from, address to, uint tokens) public validLock permissionCheck returns (bool success) {

        balances[from] = balances[from].sub(tokens);

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        emit Transfer(from, to, tokens);

        return true;

    }



     

     

     

     

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {

        return allowed[tokenOwner][spender];

    }


      
      
      
     
      
     
      
     
      
      
     
      
    function burn(uint256 value) public validLock permissionCheck returns (bool success) {
        require(msg.sender != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

     
     
     
     
    function issue(uint amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);

        balances[owner] += amount;
        _totalSupply += amount;
        emit Issue(amount);
    }
     
    event Issue(uint amount);
}