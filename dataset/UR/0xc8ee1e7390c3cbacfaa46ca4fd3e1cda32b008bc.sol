 

 

pragma solidity 0.4.25;

 
interface ITradingClasses {
     
    function getLimit(uint256 _id) external view returns (uint256);
}

 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

pragma solidity ^0.4.24;



 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

pragma solidity 0.4.25;



 

 
contract TradingClasses is ITradingClasses, Claimable {
    string public constant VERSION = "1.0.0";

    uint256[] public array;

    struct Info {
        uint256 limit;
        uint256 index;
    }

    mapping(uint256 => Info) public table;

    enum Action {None, Insert, Update, Remove}

    event ActionCompleted(uint256 _id, uint256 _limit, Action _action);

     
    function getLimit(uint256 _id) external view returns (uint256) {
        return table[_id].limit;
    }

     
    function setLimit(uint256 _id, uint256 _limit) external onlyOwner {
        Info storage info = table[_id];
        Action action = getAction(info.limit, _limit);
        if (action == Action.Insert) {
            info.index = array.length;
            info.limit = _limit;
            array.push(_id);
        }
        else if (action == Action.Update) {
            info.limit = _limit;
        }
        else if (action == Action.Remove) {
             
            uint256 last = array[array.length - 1];  
            table[last].index = info.index;
            array[info.index] = last;
            array.length -= 1;  
            delete table[_id];
        }
        emit ActionCompleted(_id, _limit, action);
    }

     
    function getArray() external view returns (uint256[] memory) {
        return array;
    }

     
    function getCount() external view returns (uint256) {
        return array.length;
    }

     
    function getAction(uint256 _prev, uint256 _next) private pure returns (Action) {
        if (_prev == 0 && _next != 0)
            return Action.Insert;
        if (_prev != 0 && _next == 0)
            return Action.Remove;
        if (_prev != _next)
            return Action.Update;
        return Action.None;
    }
}