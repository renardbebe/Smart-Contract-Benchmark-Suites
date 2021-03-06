 

pragma solidity ^0.4.18;


 

 
 
 
 
 
 
 
 



 

 

 

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

    function Owned() public {

        owner = msg.sender;

    }


    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }

}

contract Tokenlock is Owned {
    
    uint lockStartTime = 0;    
    uint lockEndTime = 0;      
    uint8 isLocked = 0;        

    event Freezed(uint starttime, uint endtime);
    event UnFreezed();

    modifier validLock {
        require(isLocked == 0 || (now < lockStartTime || now > lockEndTime));
        _;
    }
    
    function freezeTime(uint _startTime, uint _endTime) public onlyOwner {
        isLocked = 1;
        lockStartTime = _startTime;
        lockEndTime = _endTime;
        
        emit Freezed(lockStartTime, lockEndTime);
    }
    
    function freeze() public onlyOwner {
        isLocked = 1;
        lockStartTime = 0;
        lockEndTime = 90000000000;
        
        emit Freezed(lockStartTime, lockEndTime);
    }

    function unfreeze() public onlyOwner {
        isLocked = 0;
        lockStartTime = 0;
        lockEndTime = 0;
        
        emit UnFreezed();
    }
}


 

 

 

 

contract Spendcoin is ERC20Interface, Tokenlock {

    using SafeMath for uint;


    string public symbol;

    string public  name;

    uint8 public decimals;

    uint public _totalSupply;


    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;



     

     

     

    function Spendcoin() public {

        symbol = "SPND";

        name = "Spendcoin";

        decimals = 18;

        _totalSupply = 2000000000 * 10**uint(decimals);

        balances[owner] = _totalSupply;

        emit Transfer(address(0), owner, _totalSupply);

    }



     

     

     

    function totalSupply() public constant returns (uint) {

        return _totalSupply  - balances[address(0)];

    }



     

     

     

    function balanceOf(address tokenOwner) public constant returns (uint balance) {

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



     

     

     

     

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {

        return allowed[tokenOwner][spender];

    }


     

     

     

    function () public payable {


    }


     
     
     
    function withdraw() public onlyOwner returns (bool result) {
        address tokenaddress = this;
        return owner.send(tokenaddress.balance);
    }
    
     

     

     

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

        return ERC20Interface(tokenAddress).transfer(owner, tokens);

    }

}