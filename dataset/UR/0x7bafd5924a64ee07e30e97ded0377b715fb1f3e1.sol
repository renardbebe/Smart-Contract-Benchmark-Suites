 

pragma solidity ^0.4.26;
    
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

contract ERC20Basic {
    uint public decimals;
    string public    name;
    string public   symbol;
    mapping(address => uint) public balances;
    mapping (address => mapping (address => uint)) public allowed;
    
    address[] users;
    
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}
 


contract AIMT is ERC20{
    using SafeMath for uint;
    

    address public platformAdmin;
    
    
    mapping(address=>uint256) public tokenRateArray;
    mapping(address=>uint256) public tokenRateSignArray;
    mapping(address=>bool) public tokenExchangeLock;
    
    uint256 public startTime=1575216000;
    uint256 public endTime=1581696000;
    
    mapping (address => bool) public frozenAccount; 
    mapping (address => uint256) public frozenTimestamp; 
    
    
    

    
    modifier onlyOwner() {
        require(msg.sender == platformAdmin);
        _;
    }

    constructor(string _tokenName, string _tokenSymbol,uint256 _decimals,uint _initialSupply) public {
        platformAdmin = msg.sender;
        _totalSupply = _initialSupply * 10 ** uint256(_decimals); 
        decimals=_decimals;
        name = _tokenName;
        symbol = _tokenSymbol;
        balances[msg.sender]=_totalSupply;
    }
    

   
    
     function totalSupply() public constant returns (uint){
         return _totalSupply;
     }
     
      function balanceOf(address _owner) constant returns (uint256 balance) {
            return balances[_owner];
    }
  
        function approve(address _spender, uint _value) {
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
        }
        
   
        function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
          return allowed[_owner][_spender];
        }
        
        
       function transfer(address _to, uint _value) public {
            require(balances[msg.sender] >= _value);
            require(balances[_to].add(_value) > balances[_to]);
            balances[msg.sender]=balances[msg.sender].sub(_value);
            balances[_to]=balances[_to].add(_value);
            users.push(_to);
            Transfer(msg.sender, _to, _value);
        }
   
        function transferFrom(address _from, address _to, uint256 _value) public  {
            require(balances[_from] >= _value);
            require(allowed[_from][msg.sender] >= _value);
            require(balances[_to] + _value > balances[_to]);
          
            balances[_to]=balances[_to].add(_value);
            balances[_from]=balances[_from].sub(_value);
            allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
        }
        
    
    function changeAdmin(address _newAdmin) public onlyOwner returns (bool)  {
        require(_newAdmin != address(0));
        platformAdmin = _newAdmin;
        return true;
    }

   



    function lockAddr(address _target,bool _freeze) public onlyOwner returns (bool) {
        require(_target != address(0));
        frozenAccount[_target] = _freeze;
        return true;
    }


    function multiLockAddr(address[] _targets,bool[] _freezes) public onlyOwner returns (bool) {
        require(_targets.length == _freezes.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i++) {
            address _target = _targets[i];
            require(_target != address(0));
            bool _freeze = _freezes[i];
            frozenAccount[_target] = _freeze;
        }
        return true;
    }


    function getFrozenAccount(address _target)public view returns (bool) {
        require(_target != address(0));
        return frozenAccount[_target];
    }
}