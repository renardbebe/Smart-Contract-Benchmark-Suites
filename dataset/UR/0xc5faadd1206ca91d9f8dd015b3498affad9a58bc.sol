 

pragma solidity ^0.4.18;

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
        public
        returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
contract AdminManager {
    event ChangeOwner(address _oldOwner, address _newOwner);
    event SetAdmin(address _address, bool _isAdmin);
     
    address public owner;
     
    mapping(address=>bool) public admins;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyAdmins() {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

     
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit ChangeOwner(owner, _newOwner);
        owner = _newOwner;
    }

     
    function setAdmin(address _address, bool _isAdmin) public onlyOwner {
        emit SetAdmin(_address, _isAdmin);
        if(!_isAdmin){
            delete admins[_address];
        }else{
            admins[_address] = true;
        }
    }
}

 
contract PausableToken is StandardToken, AdminManager {
    event SetPause(bool isPause);
    bool public paused = true;

     
    modifier whenNotPaused() {
        if(paused) {
            require(msg.sender == owner || admins[msg.sender]);
        }
        _;
    }

     
    function setPause(bool _isPause) onlyAdmins public {
        require(paused != _isPause);
        paused = _isPause;
        emit SetPause(_isPause);
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

 
contract LockableToken is PausableToken {

     
    struct LockData {
        uint256 balance;
        uint256 releaseTimeS;
    }

    event SetLock(address _address, uint256 _lockValue, uint256 _releaseTimeS);

    mapping (address => LockData) public locks;

     
    modifier whenNotLocked(address _from, uint256 _value) {
        require( activeBalanceOf(_from) >= _value );
        _;
    }

     
    function activeBalanceOf(address _owner) public view returns (uint256) {
        if( uint256(now) < locks[_owner].releaseTimeS ) {
            return balances[_owner].sub(locks[_owner].balance);
        }
        return balances[_owner];
    }
    
     
    function setLock(address _address, uint256 _lockValue, uint256 _releaseTimeS) onlyAdmins public {
        require( uint256(now) > locks[_address].releaseTimeS );
        locks[_address].balance = _lockValue;
        locks[_address].releaseTimeS = _releaseTimeS;
        emit SetLock(_address, _lockValue, _releaseTimeS);
    }

    function transfer(address _to, uint256 _value) public whenNotLocked(msg.sender, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotLocked(_from, _value) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}


contract EnjoyGameToken is LockableToken {
    event Burn(address indexed _burner, uint256 _value);

    string  public  constant name = "EnjoyGameToken";
    string  public  constant symbol = "EGT";
    uint8   public  constant decimals = 6;

     
    constructor() public {
         
        totalSupply = 10**16;
         
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);   
    }

     
    function transferAndLock(address _to, uint256 _value, uint256 _releaseTimeS) public returns (bool) {
         
        setLock(_to,_value,_releaseTimeS);

        if( !transfer(_to, _value) ){
             
            revert();
        }
        return true;
    }
}