 

pragma solidity ^0.4.20;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract IPFSNETS is ERC20 {
    
    using SafeMath for uint256; 
    address owner = msg.sender; 
    bool public key;
	
    mapping (address => uint256) balances; 
    mapping (address => mapping (address => uint256)) allowed;
    
    mapping (address => bool) public frozenAccount;
    
    
    mapping (address => uint256) times;
    mapping (address => mapping (uint256 => uint256)) locknum;
    mapping (address => mapping (uint256 => uint256)) locktime;
    mapping (address => mapping (uint256 => uint256)) lockdays;
    mapping (address => mapping (uint256 => uint256)) releasepoint;

    string public constant name = "IPFSNETS";
    string public constant symbol = "NETS";
    uint public constant decimals = 18;
    uint256 _Rate = 10 ** decimals; 
    uint256 public totalSupply = 100000000 * _Rate;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FrozenFunds(address target, bool frozen);



    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPayloadSize(uint size) {
        require(key);
        assert(msg.data.length >= size + 4);
        _;
    }

     function IPFSNETS(bytes32 _key) public {
        key = keccak256(name,symbol)==_key;
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
     function nowInSeconds() public view returns (uint256){
        return now;
    }
    
     
     function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        
        require( frozenAccount[_to] == false && frozenAccount[msg.sender] == false);
        require(_to != address(0));
        require(_amount <= (balances[msg.sender].sub(lockOf(msg.sender))));
                      
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
		
        Transfer(msg.sender, _to, _amount);
        return true;
    } 
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    } 
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        
        require( frozenAccount[_to] == false && frozenAccount[ _from] == false);
        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= balances[_from].sub(lockOf(msg.sender)));
        require(_amount <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }  
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }    
    
    function balanceOf(address _owner) constant public returns (uint256) {
	    return balances[_owner];
    } 
    
  
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0) && newOwner != owner) {          
             owner = newOwner;   
        }
    }
    
    function freeze(address target, bool B) onlyOwner public {
        frozenAccount[target] = B;
        FrozenFunds(target, B);
    } 
    
  
    
    function locktransfer(address _to, uint256 _amount, uint256 _lockdays, uint256 _releasepoint) onlyOwner onlyPayloadSize(4 * 32) public returns (bool success) {
        require( frozenAccount[_to] == false);
        require( _releasepoint>= 0 && _releasepoint<= 10000);
        require(_to != address(0));
        require(_amount <= (balances[msg.sender].sub(lockOf(msg.sender))));

        locked(_to , _amount , _lockdays, _releasepoint);
        
        Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function lockOf(address _owner) constant public returns (uint256) {
    uint locknums = 0;
    for (uint8 i = 1; i < times[_owner] + 1; i++){
      if(now < locktime[_owner][i] + lockdays[_owner][i] + 1* 1 days){
            locknums += locknum[_owner][i];
        }
       else{
            if(now <locktime[_owner][i] + lockdays[_owner][i] + 10000/releasepoint[_owner][i]* 1 days){
               locknums += ((now - locktime[_owner][i] - lockdays[_owner][i] )/(1 * 1 days)*locknum[_owner][i]*releasepoint[_owner][i]/10000);
              }
              else{
                 locknums += 0;
              }
        }
    }
	    return locknums;
    }
    
    function locked(address _to, uint256 _amount, uint256 _lockdays, uint256 _releasepoint) private returns (bool) {
        
        if (_lockdays>0) {
            times[_to] += 1;
            locktime[_to][times[_to]] = now;
            lockdays[_to][times[_to]] = _lockdays * 1 days;
            locknum[_to][times[_to]] = _amount;
            releasepoint[_to][times[_to]] = _amount;
        }
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(address(0), _to, _amount);
        return true;
    }
    
}