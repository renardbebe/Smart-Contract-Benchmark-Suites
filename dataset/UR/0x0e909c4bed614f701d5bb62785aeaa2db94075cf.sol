 

 

pragma solidity 0.5.8;


contract Ownable {
  address public owner;


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

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract UserContract {
    address public owner;
    mapping (address => bool) public controllers;

    constructor(
        address _owner,
        address[] memory _controllerList)
        public
    {
        owner = _owner;

        for(uint256 i=0; i < _controllerList.length; i++) {
            controllers[_controllerList[i]] = true;
        }
    }

    function transferAsset(
        address asset,
        address payable to,
        uint256 amount)
        public
        returns (uint256 transferAmount)
    {
        require(controllers[msg.sender] || msg.sender == owner);

        bool success;
        if (asset == address(0)) {
            transferAmount = amount == 0 ?
                address(this).balance :
                amount;
            (success, ) = to.call.value(transferAmount)("");
            require(success);
        } else {
            bytes memory data;
            if (amount == 0) {
                (,data) = asset.call(
                    abi.encodeWithSignature(
                        "balanceOf(address)",
                        address(this)
                    )
                );
                assembly {
                    transferAmount := mload(add(data, 32))
                }
            } else {
                transferAmount = amount;
            }
            (success,) = asset.call(
                abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    to,
                    transferAmount
                )
            );
            require(success);
        }
    }

    function setControllers(
        address[] memory _controllerList,
        bool[] memory _toggle)
        public
    {
        require(msg.sender == owner && _controllerList.length == _toggle.length);

        for (uint256 i=0; i < _controllerList.length; i++) {
            controllers[_controllerList[i]] = _toggle[i];
        }
    }
}

contract UserContractRegistry is Ownable {

    mapping (address => bool) public controllers;
    mapping (address => UserContract) public userContracts;

    function setControllers(
        address[] memory controller,
        bool[] memory toggle)
        public
        onlyOwner
    {
        require(controller.length == toggle.length, "count mismatch");

        for (uint256 i=0; i < controller.length; i++) {
            controllers[controller[i]] = toggle[i];
        }
    }

    function setContract(
        address user,
        UserContract userContract)
        public
    {
        require(controllers[msg.sender], "unauthorized");
        userContracts[user] = userContract;
    }
}