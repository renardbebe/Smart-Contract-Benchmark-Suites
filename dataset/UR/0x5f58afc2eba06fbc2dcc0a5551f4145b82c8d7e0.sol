 

pragma solidity ^0.5.10;

import "./ownable.sol";
import "./transferrable.sol";

 
interface IController {
    function isController(address) external view returns (bool);
    function isAdmin(address) external view returns (bool);
}


 
 
 
 
 
contract Controller is IController, Ownable, Transferrable {

    event AddedController(address _sender, address _controller);
    event RemovedController(address _sender, address _controller);

    event AddedAdmin(address _sender, address _admin);
    event RemovedAdmin(address _sender, address _admin);

    event Claimed(address _to, address _asset, uint _amount);

    event Stopped(address _sender);
    event Started(address _sender);

    mapping (address => bool) private _isAdmin;
    uint private _adminCount;

    mapping (address => bool) private _isController;
    uint private _controllerCount;

    bool private _stopped;

     
     
    constructor(address payable _ownerAddress_) Ownable(_ownerAddress_, false) public {}

     
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "sender is not an admin");
        _;
    }

     
    modifier onlyAdminOrOwner() {
        require(_isOwner(msg.sender) || isAdmin(msg.sender), "sender is not an admin");
        _;
    }

     
    modifier notStopped() {
        require(!isStopped(), "controller is stopped");
        _;
    }

     
     
    function addAdmin(address _account) external onlyOwner notStopped {
        _addAdmin(_account);
    }

     
     
    function removeAdmin(address _account) external onlyOwner {
        _removeAdmin(_account);
    }

     
    function adminCount() external view returns (uint) {
        return _adminCount;
    }

     
     
    function addController(address _account) external onlyAdminOrOwner notStopped {
        _addController(_account);
    }

     
     
    function removeController(address _account) external onlyAdminOrOwner {
        _removeController(_account);
    }

     
     
    function controllerCount() external view returns (uint) {
        return _controllerCount;
    }

     
     
    function isAdmin(address _account) public view notStopped returns (bool) {
        return _isAdmin[_account];
    }

     
     
    function isController(address _account) public view notStopped returns (bool) {
        return _isController[_account];
    }

     
     
    function isStopped() public view returns (bool) {
        return _stopped;
    }

     
    function _addAdmin(address _account) private {
        require(!_isAdmin[_account], "provided account is already an admin");
        require(!_isController[_account], "provided account is already a controller");
        require(!_isOwner(_account), "provided account is already the owner");
        require(_account != address(0), "provided account is the zero address");
        _isAdmin[_account] = true;
        _adminCount++;
        emit AddedAdmin(msg.sender, _account);
    }

     
    function _removeAdmin(address _account) private {
        require(_isAdmin[_account], "provided account is not an admin");
        _isAdmin[_account] = false;
        _adminCount--;
        emit RemovedAdmin(msg.sender, _account);
    }

     
    function _addController(address _account) private {
        require(!_isAdmin[_account], "provided account is already an admin");
        require(!_isController[_account], "provided account is already a controller");
        require(!_isOwner(_account), "provided account is already the owner");
        require(_account != address(0), "provided account is the zero address");
        _isController[_account] = true;
        _controllerCount++;
        emit AddedController(msg.sender, _account);
    }

     
    function _removeController(address _account) private {
        require(_isController[_account], "provided account is not a controller");
        _isController[_account] = false;
        _controllerCount--;
        emit RemovedController(msg.sender, _account);
    }

     
    function stop() external onlyAdminOrOwner {
        _stopped = true;
        emit Stopped(msg.sender);
    }

     
    function start() external onlyOwner {
        _stopped = false;
        emit Started(msg.sender);
    }

     
    function claim(address payable _to, address _asset, uint _amount) external onlyAdmin notStopped {
        _safeTransfer(_to, _asset, _amount);
        emit Claimed(_to, _asset, _amount);
    }
}
