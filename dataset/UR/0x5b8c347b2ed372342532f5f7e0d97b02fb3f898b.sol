 

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

contract Ultron is ERC20 {
    
    using SafeMath for uint256; 
    address owner = msg.sender; 
	
    mapping (address => uint256) balances; 
    mapping (address => mapping (address => uint256)) allowed;

    mapping (address => uint256) times;

    mapping (address => mapping (uint256 => uint256)) lockdata;
    mapping (address => mapping (uint256 => uint256)) locktime;
    mapping (address => mapping (uint256 => uint256)) lockday;
    
    

    string public constant name = "Ultron";
    string public constant symbol = "UTN";
    uint public constant decimals = 3;
    uint256 _Rate = 10 ** decimals; 
    uint256 public totalSupply = 10000000000 * _Rate;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);



    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

     function Ultron() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
     function nowInSeconds() public view returns (uint256){
        return now;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0) && newOwner != owner) {          
             owner = newOwner;   
        }
    }

    function locked(address _to, uint256 _month, uint256 _amount) private {
		uint lockmon;

        lockmon = _month * 30 * 1 days;
		times[_to] += 1;
        locktime[_to][times[_to]] = now;
        lockday[_to][times[_to]] = lockmon;
        lockdata[_to][times[_to]] = _amount;
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
    }


    function balanceOf(address _owner) constant public returns (uint256) {
	    return balances[_owner];
    }

    function lockOf(address _owner) constant public returns (uint256) {
    uint locknum = 0;
    for (uint8 i = 1; i < times[_owner] + 1; i++){
       if(now < locktime[_owner][i] + 30* 1 days){
            locknum += lockdata[_owner][i];
        }
       else{
            if(now < locktime[_owner][i] + lockday[_owner][i] + 1* 1 days){
				uint lockmon = lockday[_owner][i].div(30 * 1 days);
				uint locknow = (now - locktime[_owner][i]).div(30 * 1 days);
                locknum += ((lockmon-locknow).mul(lockdata[_owner][i])).div(lockmon);
              }
              else{
                 locknum += 0;
              }
        }
    }


	    return locknum;
    }

    function locktransfer(address _to, uint256 _month,uint256 _point) onlyOwner onlyPayloadSize(2 * 32) public returns (bool success) {
        require( _point>= 0 && _point<= 10000);
        uint256 amount; 
        amount = (totalSupply.div(10000)).mul( _point);
        
        require(_to != address(0));
        require(amount <= (balances[msg.sender].sub(lockOf(msg.sender))));
                      
        locked(_to, _month, amount);
        
        Transfer(msg.sender, _to, amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= (balances[msg.sender].sub(lockOf(msg.sender))));
                      
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
		
        Transfer(msg.sender, _to, _amount);
        return true;
    }
  
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

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

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }

    function withdraw() onlyOwner public {
        uint256 etherBalance = this.balance;
        address theowner = msg.sender;
        theowner.transfer(etherBalance);
    }
}