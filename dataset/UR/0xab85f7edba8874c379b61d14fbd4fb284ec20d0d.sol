 

pragma solidity ^0.5.0;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
       
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        
        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

   
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Operable is Ownable {
  event OperatorAdded(address indexed account);
  event OperatorRemoved(address indexed account);

  mapping (address => bool) private _operators;

  constructor() public {
    _addOperator(msg.sender);
  }

  modifier onlyOperator() {
    require(isOperator(msg.sender));
    _;
  }

  function isOperator(address account)
    public
    view
    returns (bool) 
  {
    require(account != address(0));
    return _operators[account];
  }

  function addOperator(address account)
    public
    onlyOwner
  {
    _addOperator(account);
  }

  function removeOperator(address account)
    public
    onlyOwner
  {
    _removeOperator(account);
  }

  function _addOperator(address account)
    internal
  {
    require(account != address(0));
    _operators[account] = true;
    emit OperatorAdded(account);
  }

  function _removeOperator(address account)
    internal
  {
    require(account != address(0));
    _operators[account] = false;
    emit OperatorRemoved(account);
  }
}

contract TimestampNotary is Operable {
  struct Time {
    uint32 declared;
    uint32 recorded;
  }
  mapping (bytes32 => Time) _hashTime;

  event Timestamp(
    bytes32 indexed hash,
    uint32 declaredTime,
    uint32 recordedTime
  );

   
  function addTimestamp(bytes32 hash, uint32 declaredTime)
    public
    onlyOperator
    returns (bool)
  {
    _addTimestamp(hash, declaredTime);
    return true;
  }

   
  function _addTimestamp(bytes32 hash, uint32 declaredTime) internal {
    uint32 recordedTime = uint32(block.timestamp);
    _hashTime[hash] = Time(declaredTime, recordedTime);
    emit Timestamp(hash, declaredTime, recordedTime);
  }

   
  function verifyDeclaredTime(bytes32 hash)
    public
    view
    returns (uint32)
  {
    return _hashTime[hash].declared;
  }


  function verifyRecordedTime(bytes32 hash)
    public
    view
    returns (uint32)
  {
    return _hashTime[hash].recorded;
  }
}


contract LinkedTokenAbstract {
  function totalSupply() public view returns (uint256);
  function balanceOf(address account) public view returns (uint256);
}


contract LinkedToken is Ownable {
  address internal _token;
  event TokenChanged(address indexed token);
  

  function tokenAddress() public view returns (address) {
    return _token;
  }


  function setToken(address token) 
    public
    onlyOwner
    returns (bool)
  {
    _setToken(token);
    emit TokenChanged(token);
    return true;
  }


  function _setToken(address token) internal {
    require(token != address(0));
    _token = token;
  }
}


contract QUANTLCA is TimestampNotary, LinkedToken {
  string public constant name = 'QUANTL Certification Authority';

}