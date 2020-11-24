 

 

pragma solidity ^0.4.21;


 
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

 

pragma solidity ^0.4.21;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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

 

pragma solidity ^0.4.21;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.21;




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

pragma solidity ^0.4.21;



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.4.21;




 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 

pragma solidity 0.4.23;




 
 
 
 
 
 

contract Token is StandardToken, Ownable {
    using SafeMath for uint256;

    string public constant name = "Nynja";
    string public constant symbol = "NYN";
    uint256 public constant decimals = 18;

     
    uint256 public constant TOKEN_UNIT = 10 ** uint256(decimals);

     
    uint256 public constant MAX_TOKEN_SUPPLY = 5000000000 * TOKEN_UNIT;

     
    uint256 public constant MAX_TOKEN_SALES = 5;

     
    uint256 public constant MAX_BATCH_SIZE = 400;

    address public assigner;     
    address public locker;       

    mapping(address => bool) public locked;         

    uint256 public currentTokenSaleId = 0;            
    mapping(address => uint256) public tokenSaleId;   

    bool public tokenSaleOngoing = false;

    event TokenSaleStarting(uint indexed tokenSaleId);
    event TokenSaleEnding(uint indexed tokenSaleId);
    event Lock(address indexed addr);
    event Unlock(address indexed addr);
    event Assign(address indexed to, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event LockerTransferred(address indexed previousLocker, address indexed newLocker);
    event AssignerTransferred(address indexed previousAssigner, address indexed newAssigner);

     
     
     
    constructor(address _assigner, address _locker) public {
        require(_assigner != address(0));
        require(_locker != address(0));

        assigner = _assigner;
        locker = _locker;
    }

     
    modifier tokenSaleIsOngoing() {
        require(tokenSaleOngoing);
        _;
    }

     
    modifier tokenSaleIsNotOngoing() {
        require(!tokenSaleOngoing);
        _;
    }

     
    modifier onlyAssigner() {
        require(msg.sender == assigner);
        _;
    }

     
    modifier onlyLocker() {
        require(msg.sender == locker);
        _;
    }

     
     
     
     
    function tokenSaleStart() external onlyOwner tokenSaleIsNotOngoing returns(bool) {
        require(currentTokenSaleId < MAX_TOKEN_SALES);
        currentTokenSaleId++;
        tokenSaleOngoing = true;
        emit TokenSaleStarting(currentTokenSaleId);
        return true;
    }

     
     
    function tokenSaleEnd() external onlyOwner tokenSaleIsOngoing returns(bool) {
        emit TokenSaleEnding(currentTokenSaleId);
        tokenSaleOngoing = false;
        return true;
    }

     
     
    function isTokenSaleOngoing() external view returns(bool) {
        return tokenSaleOngoing;
    }

     
     
    function getCurrentTokenSaleId() external view returns(uint256) {
        return currentTokenSaleId;
    }

     
     
     
    function getAddressTokenSaleId(address _address) external view returns(uint256) {
        return tokenSaleId[_address];
    }

     
     
     
    function transferAssigner(address _newAssigner) external onlyOwner returns(bool) {
        require(_newAssigner != address(0));

        emit AssignerTransferred(assigner, _newAssigner);
        assigner = _newAssigner;
        return true;
    }

     
     
     
     
    function mint(address _to, uint256 _amount) public onlyAssigner tokenSaleIsOngoing returns(bool) {
        totalSupply_ = totalSupply_.add(_amount);
        require(totalSupply_ <= MAX_TOKEN_SUPPLY);

        if (tokenSaleId[_to] == 0) {
            tokenSaleId[_to] = currentTokenSaleId;
        }
        require(tokenSaleId[_to] == currentTokenSaleId);

        balances[_to] = balances[_to].add(_amount);

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
     
     
     
    function mintInBatches(address[] _to, uint256[] _amount) external onlyAssigner tokenSaleIsOngoing returns(bool) {
        require(_to.length > 0);
        require(_to.length == _amount.length);
        require(_to.length <= MAX_BATCH_SIZE);

        for (uint i = 0; i < _to.length; i++) {
            mint(_to[i], _amount[i]);
        }
        return true;
    }

     
     
     
     
     
     
     
    function assign(address _to, uint256 _amount) public onlyAssigner tokenSaleIsOngoing returns(bool) {
        require(currentTokenSaleId == 1);

         
         
         
        uint256 delta = 0;
        if (balances[_to] < _amount) {
             
            delta = _amount.sub(balances[_to]);
            totalSupply_ = totalSupply_.add(delta);
        } else {
             
            delta = balances[_to].sub(_amount);
            totalSupply_ = totalSupply_.sub(delta);
        }
        require(totalSupply_ <= MAX_TOKEN_SUPPLY);

        balances[_to] = _amount;
        tokenSaleId[_to] = currentTokenSaleId;

        emit Assign(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
     
     
     
    function assignInBatches(address[] _to, uint256[] _amount) external onlyAssigner tokenSaleIsOngoing returns(bool) {
        require(_to.length > 0);
        require(_to.length == _amount.length);
        require(_to.length <= MAX_BATCH_SIZE);

        for (uint i = 0; i < _to.length; i++) {
            assign(_to[i], _amount[i]);
        }
        return true;
    }

     
     
     
    function transferLocker(address _newLocker) external onlyOwner returns(bool) {
        require(_newLocker != address(0));

        emit LockerTransferred(locker, _newLocker);
        locker = _newLocker;
        return true;
    }

     
     
     
     
     
    function lockAddress(address _address) public onlyLocker tokenSaleIsOngoing returns(bool) {
        require(tokenSaleId[_address] == currentTokenSaleId);
        require(!locked[_address]);

        locked[_address] = true;
        emit Lock(_address);
        return true;
    }

     
     
     
     
    function unlockAddress(address _address) public onlyLocker returns(bool) {
        require(locked[_address]);

        locked[_address] = false;
        emit Unlock(_address);
        return true;
    }

     
     
     
    function lockInBatches(address[] _addresses) external onlyLocker returns(bool) {
        require(_addresses.length > 0);
        require(_addresses.length <= MAX_BATCH_SIZE);

        for (uint i = 0; i < _addresses.length; i++) {
            lockAddress(_addresses[i]);
        }
        return true;
    }

     
     
     
    function unlockInBatches(address[] _addresses) external onlyLocker returns(bool) {
        require(_addresses.length > 0);
        require(_addresses.length <= MAX_BATCH_SIZE);

        for (uint i = 0; i < _addresses.length; i++) {
            unlockAddress(_addresses[i]);
        }
        return true;
    }

     
     
     
    function isLocked(address _address) external view returns(bool) {
        return locked[_address];
    }

     
     
     
     
     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(!locked[msg.sender]);

        if (tokenSaleOngoing) {
            require(tokenSaleId[msg.sender] < currentTokenSaleId);
            require(tokenSaleId[_to] < currentTokenSaleId);
        }

        return super.transfer(_to, _value);
    }

     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(!locked[msg.sender]);
        require(!locked[_from]);

        if (tokenSaleOngoing) {
            require(tokenSaleId[msg.sender] < currentTokenSaleId);
            require(tokenSaleId[_from] < currentTokenSaleId);
            require(tokenSaleId[_to] < currentTokenSaleId);
        }

        return super.transferFrom(_from, _to, _value);
    }
}