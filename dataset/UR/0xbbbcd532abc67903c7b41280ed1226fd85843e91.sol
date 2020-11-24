 

 

pragma solidity ^0.4.25;

 
interface IController {
    function isController(address) external view returns (bool);
}

 
contract Controller is IController {
    event AddedController(address _sender, address _controller);
    event RemovedController(address _sender, address _controller);

    mapping (address => bool) private _isController;
    uint private _controllerCount;

     
     
    constructor(address _account) public {
        _addController(_account);
    }

     
    modifier onlyController() {
        require(isController(msg.sender), "sender is not a controller");
        _;
    }

     
     
    function addController(address _account) external onlyController {
        _addController(_account);
    }

     
     
    function removeController(address _account) external onlyController {
        _removeController(_account);
    }

     
    function isController(address _account) public view returns (bool) {
        return _isController[_account];
    }

     
    function controllerCount() public view returns (uint) {
        return _controllerCount;
    }

     
    function _addController(address _account) internal {
        require(!_isController[_account], "provided account is already a controller");
        _isController[_account] = true;
        _controllerCount++;
        emit AddedController(msg.sender, _account);
    }

     
    function _removeController(address _account) internal {
        require(_isController[_account], "provided account is not a controller");
        require(_controllerCount > 1, "cannot remove the last controller");
        _isController[_account] = false;
        _controllerCount--;
        emit RemovedController(msg.sender, _account);
    }
}