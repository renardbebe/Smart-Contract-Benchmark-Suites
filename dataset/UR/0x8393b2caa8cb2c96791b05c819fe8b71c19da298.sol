 

pragma solidity 0.5.11;


 
interface ISale {
    function updateRate(uint256 newRate) external;
    function withdraw() external;
    function withdraw(address payable to) external;
    function transferOwnership(address _owner) external;
    function futureRate() external view returns (uint256, uint256);
}


 
contract Updater {

    ISale public sale;
    address public updater;
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ChangedUpdater(address indexed previousUpdater, address indexed newUpdater);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyUpdater() {
        require(msg.sender == updater, "This function is callable only by updater");
        _;
    }

    constructor(ISale _sale, address _updater) public {
        require(address(_sale) != address(0), "Invalid _sale address");
        require(_updater != address(0), "Invalid _updater address");

        sale = _sale;
        updater = _updater;
        owner = msg.sender;

        emit OwnershipTransferred(address(0), msg.sender);
    }

     
    function withdraw() external onlyOwner {
        sale.withdraw(msg.sender);
    }

     
    function withdraw(address payable to) external onlyOwner {
        sale.withdraw(to);
    }

     
    function transferSaleOwnership(address newSaleOwner) external onlyOwner {
        require(newSaleOwner != address(0));

        sale.transferOwnership(newSaleOwner);
    }

     
    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0));

        emit OwnershipTransferred(owner, _owner);

        owner = _owner;
    }

     
    function changeUpdater(address _updater) external onlyOwner {
        require(_updater != address(0), "Invalid _updater address");

        emit ChangedUpdater(updater, _updater);

        updater = _updater;
    }

     
    function updateRateByOwner(uint256 newRate) external onlyOwner {
        sale.updateRate(newRate);
    }

     
    function updateRateByUpdater(uint256 newRate) external onlyUpdater {
        (uint256 rate, uint256 timePriorToApply) = sale.futureRate();
        require(timePriorToApply == 0, "New rate hasn't been applied yet");
        uint256 newRateMultiplied = newRate * 100;
        require(newRateMultiplied / 100 == newRate, "Integer overflow");
         
         
         
        require(newRate * 99 <= rate * 100, "New rate is too high");

        sale.updateRate(newRate);
    }
}