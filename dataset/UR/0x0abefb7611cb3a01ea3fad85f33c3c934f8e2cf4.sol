 

 
pragma solidity ^0.4.11;

library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Guarded {

    modifier isValidAmount(uint256 _amount) { 
        require(_amount > 0); 
        _; 
    }

     
    modifier isValidAddress(address _address) {
        require(_address != 0x0 && _address != address(this));
        _;
    }

}

contract Ownable {
    address public owner;

     
    function Ownable() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract Claimable is Ownable {
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() onlyPendingOwner {
        owner = pendingOwner;
        pendingOwner = 0x0;
    }
}

contract ERC20 {
    
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract ERC20Token is ERC20 {
    using SafeMath for uint256;

    string public standard = 'Cryptoken 0.1.1';

    string public name = '';             
    string public symbol = '';           
    uint8 public decimals = 0;           

     
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

     
     
    function ERC20Token(string _name, string _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    function balanceOf(address _owner) 
        public constant 
        returns (uint256 balance) 
    {
        return balances[_owner];
    }    

     
     
    function transfer(address _to, uint256 _value) 
        public returns (bool success) 
    {
         
        require(_to != address(this));

         
         
         
         

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
         
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value)         
        public returns (bool success) 
    {    
         
        require(_to != 0x0 && _from != 0x0);
        require(_from != _to && _to != address(this));

         
         
         
         
         

         
        allowed[_from][_to] = allowed[_from][_to].sub(_value);        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

         
        Transfer(_from, _to, _value);
        return true;
    }

     
     
    function approve(address _spender, uint256 _value)          
        public returns (bool success) 
    {
         
        require(_spender != 0x0 && _spender != address(this));            

         
         
        require(allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
    function allowance(address _owner, address _spender)          
        public constant returns (uint remaining) 
    {
         
        require(_spender != 0x0 && _owner != 0x0);
        require(_owner != _spender && _spender != address(this));            

         
        return allowed[_owner][_spender];
    }

}

contract FaradCryptoken is ERC20Token, Guarded, Claimable {

    uint256 public SUPPLY = 1600000000 ether;    

     
    function FaradCryptoken() 
        ERC20Token('FARAD', 'FRD', 18) 
    {
        totalSupply = SUPPLY;
        balances[msg.sender] = SUPPLY;
    }

}