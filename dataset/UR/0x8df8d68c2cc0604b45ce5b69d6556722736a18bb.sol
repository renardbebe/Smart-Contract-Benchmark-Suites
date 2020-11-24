 

pragma solidity 0.4.25;

 
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

contract Ownable {
    mapping(address => bool) owners;
    mapping(address => bool) managers;

    event OwnerAdded(address indexed newOwner);
    event OwnerDeleted(address indexed owner);
    event ManagerAdded(address indexed newOwner);
    event ManagerDeleted(address indexed owner);

     
    constructor() public {
        owners[msg.sender] = true;
    }

     
    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    modifier onlyManager() {
        require(isManager(msg.sender));
        _;
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owners[_newOwner] = true;
        emit OwnerAdded(_newOwner);
    }

    function delOwner(address _owner) external onlyOwner {
        require(owners[_owner]);
        owners[_owner] = false;
        emit OwnerDeleted(_owner);
    }


    function addManager(address _manager) external onlyOwner {
        require(_manager != address(0));
        managers[_manager] = true;
        emit ManagerAdded(_manager);
    }

    function delManager(address _manager) external onlyOwner {
        require(managers[_manager]);
        managers[_manager] = false;
        emit ManagerDeleted(_manager);
    }

    function isOwner(address _owner) public view returns (bool) {
        return owners[_owner];
    }

    function isManager(address _manager) public view returns (bool) {
        return managers[_manager];
    }
}






 
contract Escrow is Ownable {
    using SafeMath for uint256;

    struct Stage {
        uint releaseTime;
        uint percent;
        bool transferred;
    }

    mapping (uint => Stage) public stages;
    uint public stageCount;

    uint public stopDay;
    uint public startBalance = 0;


    constructor(uint _stopDay) public {
        stopDay = _stopDay;
    }

    function() payable public {

    }

     
    function addStage(uint _releaseTime, uint _percent) onlyOwner public {
        require(_percent >= 100);
        require(_releaseTime > stages[stageCount].releaseTime);
        stageCount++;
        stages[stageCount].releaseTime = _releaseTime;
        stages[stageCount].percent = _percent;
    }


    function getETH(uint _stage, address _to) onlyManager external {
        require(stages[_stage].releaseTime < now);
        require(!stages[_stage].transferred);
        require(_to != address(0));

        if (startBalance == 0) {
            startBalance = address(this).balance;
        }

        uint val = valueFromPercent(startBalance, stages[_stage].percent);
        stages[_stage].transferred = true;
        _to.transfer(val);
    }


    function getAllETH(address _to) onlyManager external {
        require(stopDay < now);
        require(address(this).balance > 0);
        require(_to != address(0));

        _to.transfer(address(this).balance);
    }


    function transferETH(address _to) onlyOwner external {
        require(address(this).balance > 0);
        require(_to != address(0));
        _to.transfer(address(this).balance);
    }


     
    function valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }

    function setStopDay(uint _stopDay) onlyOwner external {
        stopDay = _stopDay;
    }
}