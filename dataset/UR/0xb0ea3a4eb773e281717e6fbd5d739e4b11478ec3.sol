 

pragma solidity ^0.4.24;


 
contract ERC20TokenInterface {

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}
 
contract Admined {  
    address public admin;  

     
    constructor() internal {
        admin = msg.sender;  
        emit AdminedEvent(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != address(0));
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

     
    event TransferAdminship(address newAdminister);
    event AdminedEvent(address administer);

}

contract LockableToken is Admined {

    event LockStatus(address _target, uint _timeStamp);

    mapping (address => uint) internal locked;  
    bool internal globalLock = true;

     
    function setLocked(address _target, uint _timeStamp) public onlyAdmin returns (bool) {
        locked[_target]=_timeStamp;
        emit LockStatus(_target, _timeStamp);
        return true;
    }

     
    function unLock(address _target) public onlyAdmin returns (bool) {
        locked[_target] = 0;
        return true;
    }

     
    function AllUnLock() public onlyAdmin returns (bool) {
        globalLock = false;
        return true;
    }

     
    function AllLock() public onlyAdmin returns (bool) {
        globalLock = true;
        return true;
    }

     
    function isGlobalLock() public view returns (bool) {
        return globalLock;
    }

     
    function isLocked(address _target) public view returns (bool) {
        if(locked[_target] > now){
            return true;
        } else {
            return false;
        }
    }
}

 
contract Pausable is LockableToken {
  event Pause();
  event Unpause();

  bool public paused = false;

  constructor() internal {
    emit Unpause();
  }

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
   function pause() onlyAdmin whenNotPaused public {
     paused = true;
     emit Pause();
   }

   
  function unpause() onlyAdmin whenPaused public {
    paused = false;
    emit Unpause();
  }
}
 
library SafeMath {

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20Token is ERC20TokenInterface,  Admined, Pausable {  
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  
    mapping (address => bool) frozen;  

     
    function balanceOf(address _owner) public constant returns (uint256 value) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) whenNotPaused public returns (bool success) {
        require(_to != address(0));  
        require(frozen[msg.sender]==false);
        if (globalLock == true) {
            require(locked[msg.sender] <= now, 'Tokens locked as single');
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool success) {
        require(_to != address(0));  
        require(frozen[_from]==false);
        if (globalLock == true) {
            require(locked[msg.sender] <= now, 'Tokens locked as single');
        }
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));  
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function setFrozen(address _target,bool _flag) onlyAdmin whenNotPaused public {
        frozen[_target]=_flag;
        emit FrozenStatus(_target,_flag);
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FrozenStatus(address _target,bool _flag);

}
 
contract Token {
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

 
contract AEXLToken is ERC20Token {

    string public name = 'AEXL';
    uint8 public decimals = 18;
    string public symbol = 'AEXL';
    string public version = '1';

     
    constructor() public {
        totalSupply = 49883398300 * 10 ** uint256(decimals);  
        balances[msg.sender] = totalSupply;
        emit Transfer(0, msg.sender, totalSupply);
    }

     
    function externalTokensRecovery(Token _address) onlyAdmin public {
        uint256 remainder = _address.balanceOf(this);  
        _address.transfer(msg.sender,remainder);  
    }

     
    function sendBatches(address[] _addrs, uint256[] tokensValue) onlyAdmin public {
      require(_addrs.length == tokensValue.length);
      for(uint256 i = 0; i < _addrs.length; i++) {
        require(transfer(_addrs[i], tokensValue[i]));
        require(setLocked(_addrs[i], 4708628725000));  
      }
    }

     
    function burn(uint256 _value) onlyAdmin whenNotPaused public {
      require(_value <= balances[msg.sender]);

      balances[msg.sender] = balances[msg.sender].sub(_value);
      totalSupply = totalSupply.sub(_value);

      emit Burn(msg.sender, _value);
      emit Transfer(msg.sender, address(0), _value);
    }

     
    function() public {
        revert();
    }

    event Burn(address indexed burner, uint256 value);
}