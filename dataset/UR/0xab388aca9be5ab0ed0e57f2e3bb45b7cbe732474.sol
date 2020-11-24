 

 

 

pragma solidity ^0.4.24;

 
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




 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 
   
  constructor () public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
interface IERC20 {
    function transfer(address _to, uint256 _value)  external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function totalSupply() constant returns (uint256 totalSupply);

    function balanceOf(address _owner) external constant returns (uint256 balance);

    function allowance(address _owner, address _spender) external constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract CrypsterToken is IERC20, Ownable, Pausable {
   
    using SafeMath for uint256;
    event Buy(address buyer, uint256 value);

    uint256 public _totalSupply = SafeMath.mul(1000000000, 1 ether);
    uint256 public _remainingSupply;
    
    string public constant symbol = "CRP";
    string public constant name = "Crypster Token";
    uint8 public constant decimals = 18;
   
    address internal wallet;
    
    uint public rate;
        
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
 
    constructor (address _wallet, uint _rate) public {
        wallet = _wallet;
        _remainingSupply = _totalSupply;
        rate = _rate;
        
    }   
    
     
    function () public payable whenNotPaused{
        buyTokens();
    }
    
    function buyTokens() public payable whenNotPaused {
        require(msg.value > 0);
        
        uint256 tokens = msg.value.mul(rate);
        
        require(tokens <= _remainingSupply);
        
        balances[msg.sender] =  balances[msg.sender].add(tokens);
        _remainingSupply = _remainingSupply.sub(tokens);
        wallet.transfer(msg.value);
        emit Buy(msg.sender, tokens);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _value &&
            balances[_from] >= _value && _value > 0 );  
        
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function transferFunds(address[] _to , uint256[] _value) public onlyOwner whenNotPaused {
    
        for (uint i = 0; i < _to.length; i++) {
        
        _value[i] = SafeMath.mul(_value[i], 1 ether);
    
        require(_remainingSupply >= _value[i],"aasasas");
    
        _remainingSupply = SafeMath.sub(_remainingSupply,_value[i]);

        balances[_to[i]] = balances[_to[i]].add(_value[i]);
        
        emit Transfer(msg.sender, _to[i], _value[i]);
        }
        
    }

    function setRate(uint _newRate) public onlyOwner {
        rate = _newRate;
    }
    
    function setWallet(address _newWallet) public onlyOwner  {
        wallet = _newWallet;
    }
    
    function totalSupply() public constant returns (uint256 totalSupply) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public  constant returns (uint256 remaining) {
        return allowed[_owner][_spender];

    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    

}