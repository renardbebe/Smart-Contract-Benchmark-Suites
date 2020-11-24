 

pragma solidity ^0.4.24;

 

 

pragma solidity ^0.4.24;

 
contract Ownable {

   
  address private _owner;

   
  event OwnershipTransferred(address previousOwner, address newOwner);

   
  constructor() public {
    setOwner(msg.sender);
  }

   
  function owner() public view returns (address) {
    return _owner;
  }

   
  function setOwner(address newOwner) internal {
    _owner = newOwner;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner());
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner(), newOwner);
    setOwner(newOwner);
  }
}

 

 

pragma solidity ^0.4.24;


 
contract Controller is Ownable {
     
    mapping(address => address) internal controllers;

    event ControllerConfigured(
        address indexed _controller,
        address indexed _worker
    );
    event ControllerRemoved(address indexed _controller);

     
    modifier onlyController() {
        require(controllers[msg.sender] != address(0), 
            "The value of controllers[msg.sender] must be non-zero");
        _;
    }

     
    function getWorker(
        address _controller
    )
        external
        view
        returns (address)
    {
        return controllers[_controller];
    }

     

     
    function configureController(
        address _controller,
        address _worker
    )
        public 
        onlyOwner 
    {
        require(_controller != address(0), 
            "Controller must be a non-zero address");
        require(_worker != address(0), "Worker must be a non-zero address");
        controllers[_controller] = _worker;
        emit ControllerConfigured(_controller, _worker);
    }

     
    function removeController(
        address _controller
    )
        public 
        onlyOwner 
    {
        require(_controller != address(0), 
            "Controller must be a non-zero address");
        require(controllers[_controller] != address(0), 
            "Worker must be a non-zero address");
        controllers[_controller] = address(0);
        emit ControllerRemoved(_controller);
    }
}

 

 

pragma solidity ^0.4.24;

 
interface MinterManagementInterface {
    function isMinter(address _account) external view returns (bool);
    function minterAllowance(address _minter) external view returns (uint256);

    function configureMinter(
        address _minter,
        uint256 _minterAllowedAmount
    )
        external
        returns (bool);

    function removeMinter(address _minter) external returns (bool);
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

 

 

pragma solidity ^0.4.24;




 
contract MintController is Controller {
    using SafeMath for uint256;

     
    MinterManagementInterface internal minterManager;

    event MinterManagerSet(
        address indexed _oldMinterManager,
        address indexed _newMinterManager
    );
    event MinterConfigured(
        address indexed _msgSender,
        address indexed _minter,
        uint256 _allowance
    );
    event MinterRemoved(
        address indexed _msgSender,
        address indexed _minter
    );
    event MinterAllowanceIncremented(
        address indexed _msgSender,
        address indexed _minter,
        uint256 _increment,
        uint256 _newAllowance
    );

    event MinterAllowanceDecremented(
        address indexed msgSender,
        address indexed minter,
        uint256 decrement,
        uint256 newAllowance
    );

     
    constructor(address _minterManager) public {
        minterManager = MinterManagementInterface(_minterManager);
    }

     
    function getMinterManager(
    )
        external
        view
        returns (MinterManagementInterface)
    {
        return minterManager;
    }

     

     
    function setMinterManager(
        address _newMinterManager
    )
        public
        onlyOwner
    {
        emit MinterManagerSet(address(minterManager), _newMinterManager);
        minterManager = MinterManagementInterface(_newMinterManager);
    }

     

     
    function removeMinter() public onlyController returns (bool) {
        address minter = controllers[msg.sender];
        emit MinterRemoved(msg.sender, minter);
        return minterManager.removeMinter(minter);
    }

     
    function configureMinter(
        uint256 _newAllowance
    )
        public
        onlyController
        returns (bool)
    {
        address minter = controllers[msg.sender];
        emit MinterConfigured(msg.sender, minter, _newAllowance);
        return internal_setMinterAllowance(minter, _newAllowance);
    }

     
    function incrementMinterAllowance(
        uint256 _allowanceIncrement
    )
        public
        onlyController
        returns (bool)
    {
        require(_allowanceIncrement > 0, 
            "Allowance increment must be greater than 0");
        address minter = controllers[msg.sender];
        require(minterManager.isMinter(minter), 
            "Can only increment allowance for minters in minterManager");

        uint256 currentAllowance = minterManager.minterAllowance(minter);
        uint256 newAllowance = currentAllowance.add(_allowanceIncrement);

        emit MinterAllowanceIncremented(
            msg.sender,
            minter,
            _allowanceIncrement,
            newAllowance
        );

        return internal_setMinterAllowance(minter, newAllowance);
    }

     
    function decrementMinterAllowance(
        uint256 _allowanceDecrement
    )
        public
        onlyController
        returns (bool)
    {
        require(_allowanceDecrement > 0, 
            "Allowance decrement must be greater than 0");
        address minter = controllers[msg.sender];
        require(minterManager.isMinter(minter), 
            "Can only decrement allowance for minters in minterManager");

        uint256 currentAllowance = minterManager.minterAllowance(minter);
        uint256 actualAllowanceDecrement = (
            currentAllowance > _allowanceDecrement ? 
            _allowanceDecrement : currentAllowance
        );
        uint256 newAllowance = currentAllowance.sub(actualAllowanceDecrement);

        emit MinterAllowanceDecremented(
            msg.sender,
            minter,
            actualAllowanceDecrement,
            newAllowance
        );

        return internal_setMinterAllowance(minter, newAllowance);
    }

     

     
    function internal_setMinterAllowance(
        address _minter,
        uint256 _newAllowance
    )
        internal
        returns (bool)
    {
        return minterManager.configureMinter(_minter, _newAllowance);
    }
}

 

 

pragma solidity ^0.4.24;


 
contract MasterMinter is MintController {

    constructor(address _minterManager) MintController(_minterManager) public {
    }
}