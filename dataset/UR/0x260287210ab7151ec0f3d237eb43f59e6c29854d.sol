 

pragma solidity ^0.5.0;

 
 
 
 


 
 
contract ERC20Interface {
     
    function totalSupply() view public returns (uint256);

     
    function balanceOf(address _owner) view public returns (uint256);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) view public returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract KemfeCoin is ERC20Interface {
   
    using SafeMath for uint256;
    string public constant symbol = "KFC";
    string public constant name = "KFC";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 500000000000000000000000000;
 
     struct LockAccount{
        uint status;
    }

     mapping (address => LockAccount) lockAccount;
     address[] public AllLockAccounts;
    
    
     
    address public owner;

     
    mapping (address => uint256) balances;

     
    mapping (address => mapping (address => uint256)) allowed;

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    constructor() public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }
    

    function totalSupply() view public returns (uint256) {
        return _totalSupply;
    }
    
    
       function setLockAccount(address _addr) public{
        require(msg.sender == owner);
       
        lockAccount[_addr].status = 1;
        AllLockAccounts.push(_addr) -1;
    }
    
      function getLockAccounts() view public returns (address[] memory){
        return AllLockAccounts;
    }
      function unLockAccount(address _addr) public {
        require(msg.sender == owner);
       lockAccount[_addr].status = 0;
       
    }
    
    function isLock (address _addr) view private returns(bool){
        uint lS = lockAccount[_addr].status;
        
        if(lS == 1){
            return true;
        }
        
        return false;
    }

   
     function getLockAccount(address _addr) view public returns (uint){
        return lockAccount[_addr].status;
    }

     
    function balanceOf(address _owner) view public returns (uint256) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (balances[msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            emit Transfer(msg.sender, _to, _amount);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(
    address _from,
    address _to,
    uint256 _amount
    ) public returns (bool) {
        if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            emit Transfer(_from, _to, _amount);
            return true;
        }
        else {
            return false;
        }
    }


     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}