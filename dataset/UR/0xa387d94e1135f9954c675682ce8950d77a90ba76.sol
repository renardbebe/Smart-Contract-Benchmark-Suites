 

pragma solidity ^0.4.21;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
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


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
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


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function msgSender() 
        public
        view
        returns (address)
    {
        return msg.sender;
    }

    function transfer(
        address _to, 
        uint256 _value
    ) 
        public 
        returns (bool) 
    {
        require(_to != address(0));
        require(_to != msg.sender);
        require(_value <= balances[msg.sender]);
        
        _preValidateTransfer(msg.sender, _to, _value);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function _preValidateTransfer(
        address _from, 
        address _to, 
        uint256 _value
    ) 
        internal 
    {

    }
}

 
contract StandardToken is ERC20, BasicToken, Ownable {

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

        _preValidateTransfer(_from, _to, _value);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].sub(_value);  
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true; 
    } 

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

 
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function decreseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 
contract MintableToken is StandardToken {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }
   
     
    function mint(address _to, uint256 _amount) onlyOwner   canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}


 
contract LockableToken is MintableToken {

    using SafeMath for uint256;

     
    struct Lock {
        uint256 amount;
        uint256 expiresAt;
    }

     
    mapping (address => Lock[]) public grantedLocks;

    function addLock(
        address _granted, 
        uint256 _amount, 
        uint256 _expiresAt
    ) 
        public 
        onlyOwner 
    {
        require(_amount > 0);
        require(_expiresAt > now);

        grantedLocks[_granted].push(Lock(_amount, _expiresAt));
    }

    function deleteLock(
        address _granted, 
        uint8 _index
    ) 
        public 
        onlyOwner 
    {
        Lock storage lock = grantedLocks[_granted][_index];

        delete grantedLocks[_granted][_index];
        for (uint i = _index; i < grantedLocks[_granted].length - 1; i++) {
            grantedLocks[_granted][i] = grantedLocks[_granted][i+1];
        }
        grantedLocks[_granted].length--;

        if (grantedLocks[_granted].length == 0)
            delete grantedLocks[_granted];
    }

    function transferWithLock(
        address _to, 
        uint256 _value,
        uint256[] _expiresAtList
    ) 
        public 
        onlyOwner
        returns (bool) 
    {
        require(_to != address(0));
        require(_to != msg.sender);
        require(_value <= balances[msg.sender]);

        uint256 count = _expiresAtList.length;
        if (count > 0) {
            uint256 devidedValue = _value.div(count);
            for (uint i = 0; i < count; i++) {
                addLock(_to, devidedValue, _expiresAtList[i]);  
            }
        }

        return transfer(_to, _value);
    }

     
    function _preValidateTransfer(
        address _from, 
        address _to, 
        uint256 _value
    ) 
        internal
    {
        super._preValidateTransfer(_from, _to, _value);
        
        uint256 lockedAmount = getLockedAmount(_from);
        uint256 balanceAmount = balanceOf(_from);

        require(balanceAmount.sub(lockedAmount) >= _value);
    }


    function getLockedAmount(
        address _granted
    ) 
        public
        view
        returns(uint256)
    {

        uint256 lockedAmount = 0;

        Lock[] storage locks = grantedLocks[_granted];
        for (uint i = 0; i < locks.length; i++) {
            if (now < locks[i].expiresAt) {
                lockedAmount = lockedAmount.add(locks[i].amount);
            }
        }
         
         

        return lockedAmount;
    }
    
}


contract BPXToken is LockableToken {

  string public constant name = "Bitcoin Pay";
  string public constant symbol = "BPX";
  uint32 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(decimals));

   
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }
}