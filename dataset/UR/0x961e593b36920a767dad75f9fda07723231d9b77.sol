 

pragma solidity ^0.4.11;

 
 
 
 

 
 
 
library SafeMath {

     
     
     
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

     
     
     
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
 
    function acceptOwnership() {
        if (msg.sender == newOwner) {
            OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
}


 
 
 
 
contract ERC20Token is Owned {
    using SafeMath for uint;

     
     
     
    uint256 _totalSupply = 0;

     
     
     
    mapping(address => uint256) balances;

     
     
     
    mapping(address => mapping (address => uint256)) allowed;

     
     
     
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

     
     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount                 
            && _amount > 0                                  
            && balances[_to] + _amount > balances[_to]      
        ) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
    function approve(
        address _spender,
        uint256 _amount
    ) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount                   
            && allowed[_from][msg.sender] >= _amount     
            && _amount > 0                               
            && balances[_to] + _amount > balances[_to]   
        ) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
    function allowance(
        address _owner, 
        address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender,
        uint256 _value);
}


contract AbabPreICOToken is ERC20Token {

     
     
     
    string public constant symbol   = "pAA";
    string public constant name     = "AbabPreICOToken";
    uint8  public constant decimals = 18;

    uint256 public STARTDATE;  
    uint256 public ENDDATE;    
    uint256 public BUYPRICE;   
    uint256 public CAP;

    function AbabPreICOToken() {
        STARTDATE = 1499951593;         
        ENDDATE   = 1500815593;         
        BUYPRICE  = 4000;               
        CAP       = 2500*1 ether;       
    }
	
    function ActualizePriceBeforeStart(uint256 _start, uint256 _end, uint256 _buyPrice, uint256 _cap) 
    onlyOwner returns (bool success) 
    {
        require(now < STARTDATE);
        STARTDATE = _start;
        ENDDATE   = _end;
        BUYPRICE  = _buyPrice;
        CAP       = _cap; 
        return true;
    }

    uint256 public totalEthers;

     
     
     
    function () payable {
         
        require(now >= STARTDATE);
         
        require(now <= ENDDATE);
         
        require(msg.value > 0);

         
        totalEthers = totalEthers.add(msg.value);
         
        require(totalEthers <= CAP);

        uint tokens = msg.value * BUYPRICE;

         
        require(tokens > 0);

         
        _totalSupply = _totalSupply.add(tokens);

         
        balances[msg.sender] = balances[msg.sender].add(tokens);

         
        Transfer(0x0, msg.sender, tokens);

         
        owner.transfer(msg.value);
    }

     
     
     
     
    function transfer(address _to, uint _amount) returns (bool success) {
         
        require(now > ENDDATE || totalEthers == CAP);
         
        return super.transfer(_to, _amount);
    }


     
     
     
     
     
    function transferFrom(address _from, address _to, uint _amount) 
        returns (bool success)
    {
         
        require(now > ENDDATE || totalEthers == CAP);
         
        return super.transferFrom(_from, _to, _amount);
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint amount)
      onlyOwner returns (bool success) 
    {
        return ERC20Token(tokenAddress).transfer(owner, amount);
    }
}