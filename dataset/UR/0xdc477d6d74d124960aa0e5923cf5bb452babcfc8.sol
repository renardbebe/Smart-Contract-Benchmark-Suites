 

 

 

pragma solidity ^0.5.7;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.7;

 
contract IProperties {
     
    event OwnerChanged(address newOwner);

     
    event ManagerSet(address manager, bool status);

     
    event PropertyCreated(
        uint256 propertyId,
        uint256 allocationCapacity,
        string title,
        string location,
        uint256 marketValue,
        uint256 maxInvestedATperInvestor,
        uint256 totalAllowedATinvestments,
        address AT,
        uint256 dateAdded
    );

     
    event PropertyStatusUpdated(uint256 propertyId, uint256 status);

     
    event PropertyInvested(uint256 propertyId, uint256 tokens);

     
    event InvestmentContractStatusSet(address investmentContract, bool status);

     
    event PropertyUpdated(uint256 propertyId);

     
    function changeOwner(address newOwner) external;

     
    function setManager(address manager, bool status) external;

     
    function createProperty(
        uint256 allocationCapacity,
        string memory title,
        string memory location,
        uint256 marketValue,
        uint256 maxInvestedATperInvestor,
        uint256 totalAllowedATinvestments,
        address AT
    ) public returns (bool);

     
    function updatePropertyStatus(uint256 propertyId, uint256 status) external;

     
    function invest(address investor, uint256 propertyId, uint256 shares)
        public
        returns (bool);

     
    function setInvestmentContractStatus(
        address investmentContract,
        bool status
    ) external;

     
    function getProperty(uint256 propertyId)
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            uint8
        );

     
    function getPropertyInvestors(uint256 propertyId, uint256 from, uint256 to)
        public
        view
        returns (address[] memory);

     
    function getTotalAndHolderShares(uint256 propertyId, address holder)
        public
        view
        returns (uint256 totalShares, uint256 holderShares);
}

 

pragma solidity ^0.5.7;

 
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

 

pragma solidity ^0.5.7;


 
contract IDividendsWithETH {
     
    event StateChanged(uint256 state);

     
    event PropertiesSet(address property);

     
    event ManagerStatusUpdated(address manager, bool managerStatus);

     
    event DividendPaid(
        uint256 propertyId,
        uint256 dividendId,
        uint256 ethAmount
    );

     
    event DividendWithdrawn(
        uint256 propertyId,
        uint256 dividendId,
        address investor,
        uint256 amount
    );

     
    event ETHWithdrawn(address withdrawer, uint256 amount);

     
     
     
     
    function setManagerStatus(address manager, bool managerStatus)
        external
        returns (bool);

     
    function setProperty(IProperties _properties) external;

     
    function setState(uint256 state) external;

     
    function payDividend(uint256 propertyId) external payable;

     
    function withdrawDividend(uint256 dividendId) public returns (bool);

     
    function withdrawETHByManager(uint256 amount) external;

     
    function getAllDividendsList()
        public
        view
        returns (
            uint256[] memory propertyId,
            uint256[] memory totalDividendAmount,
            uint256[] memory totalInvestment,
            uint256[] memory dividendsAmountPaid
        );

    function getInvestorBalanceByDividendId(
        uint256 dividendId,
        address investor
    )
        public
        view
        returns (
            uint256 dividendBalanceAvailable,
            uint256 dividendBalanceWithdrawn
        );

}

 

pragma solidity ^0.5.7;





contract DividendsWithETH is IDividendsWithETH, Ownable {
    using SafeMath for uint256;

    enum State {INACTIVE, ACTIVE}  

    struct Dividend {
        uint256 propertyId;  
        uint256 totalDividendAmount;  
        uint256 totalInvestment;  
        uint256 dividendsAmountPaid;  
        mapping(address => uint256) amountWithdrawnByInvestor;
    }

    mapping(uint256 => Dividend) public dividends;  

    mapping(address => bool) public managers;  

    State stateOfDividendsWithETH;  
    uint256 dividendIdCount = 0;  

    IProperties public properties;  

     
    constructor() public {
         
        stateOfDividendsWithETH = State.ACTIVE;

        emit StateChanged(uint256(stateOfDividendsWithETH));
    }

     
    modifier onlyManager() {
        require(isOwner() || managers[msg.sender], "Only owner/manager can call this function.");
        _;
    }

     
     
     
     
    function setManagerStatus(address manager, bool managerStatus)
        external
        onlyOwner
        returns (bool)
    {
        require(
            manager != address(0),
            "Provided mannager address is not valid."
        );
        require(
            managers[manager] != managerStatus,
            "This status of manager is already set."
        );

        managers[manager] = managerStatus;

        emit ManagerStatusUpdated(manager, managerStatus);

        return true;
    }

     
    function setProperty(IProperties _properties) external onlyOwner {
        require(
            address(_properties) != address(0),
            "properties address must be a valid address."
        );
        properties = _properties;

        emit PropertiesSet(address(properties));
    }

     
    modifier isStateActive() {
        require(
            stateOfDividendsWithETH == State.ACTIVE,
            "contract state is INACTIVE."
        );
        _;
    }

     
    function setState(uint256 state) external onlyOwner {
        require(state == 0 || state == 1, "Provided state is invalid.");
        require(
            state != uint256(stateOfDividendsWithETH),
            "Provided state is already set."
        );

        stateOfDividendsWithETH = State(state);

        emit StateChanged(uint256(stateOfDividendsWithETH));
    }

     
    function payDividend(uint256 propertyId)
        external
        payable
        onlyManager
        isStateActive
    {
        require(propertyId > 0, "propertyId should be greater than zero.");
        require(msg.value > 0, "msg.value should be greater than 0");

        uint256 dividendAmount = msg.value;
        bool exists = false;
        for (uint256 i = 1; i <= dividendIdCount; i++) {
            Dividend memory dividend = dividends[i];
            if (dividend.propertyId == propertyId) {
                 
                dividend.totalDividendAmount = dividend.totalDividendAmount.add(dividendAmount);
                dividends[i] = dividend;
                break;
            }
        }

        if (!exists) {
             
            (, , , , , , uint256 totalPropertyInvestment, , , ) = properties
                .getProperty(propertyId);
            Dividend memory newDividend = Dividend(
                propertyId,
                dividendAmount,
                totalPropertyInvestment,
                uint256(0)
            );
            dividendIdCount = dividendIdCount.add(1);

            dividends[dividendIdCount] = newDividend;
        }

        emit DividendPaid(propertyId, dividendIdCount, dividendAmount);

    }

     
    function withdrawDividend(uint256 dividendId)
        public
        isStateActive
        returns (bool)
    {
        require(dividendId > 0, "dividendId should be greater than zero");

        Dividend storage dividend = dividends[dividendId];

        require(
            dividend.propertyId != 0,
            "dividend with the given property ID does not exists"
        );

         
        (, uint256 investmentByUser) = properties.getTotalAndHolderShares(
            dividend.propertyId,
            msg.sender
        );

         
        uint256 userDividendAmount = calculateDividend(
            dividend.totalInvestment,
            dividend.totalDividendAmount,
            investmentByUser
        );

        require(
            dividend.amountWithdrawnByInvestor[msg.sender] < userDividendAmount,
            "No dividend amount available for withdrawal"
        );

        uint256 dividendAmount = userDividendAmount.sub(
            dividend.amountWithdrawnByInvestor[msg.sender]
        );

        require(
            dividendAmount <= address(this).balance,
            "The dividendWithETH contract does not have enough ETH balance to pay dividend."
        );

        dividend.amountWithdrawnByInvestor[msg.sender] = dividend
            .amountWithdrawnByInvestor[msg.sender]
            .add(dividendAmount);
        dividend.dividendsAmountPaid = dividend.dividendsAmountPaid.add(
            dividendAmount
        );

         
        msg.sender.transfer(dividendAmount);

        emit DividendWithdrawn(
            dividend.propertyId,
            dividendId,
            msg.sender,
            dividendAmount
        );

        return true;
    }

     
    function withdrawETHByManager(uint256 amount) external onlyManager {
        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "Contract has no ETH in it.");

        if (amount == 0) {
            msg.sender.transfer(contractBalance);
            emit ETHWithdrawn(msg.sender, contractBalance);
        } else {
            require(
                amount <= contractBalance,
                "Contract has less balance than the amount specified."
            );
            msg.sender.transfer(amount);
            emit ETHWithdrawn(msg.sender, amount);
        }
    }

     
    function getAllDividendsList()
        public
        view
        returns (
            uint256[] memory propertyId,
            uint256[] memory totalDividendAmount,
            uint256[] memory totalInvestment,
            uint256[] memory dividendsAmountPaid
        )
    {
        propertyId = new uint256[](dividendIdCount);
        totalDividendAmount = new uint256[](dividendIdCount);
        totalInvestment = new uint256[](dividendIdCount);
        dividendsAmountPaid = new uint256[](dividendIdCount);

        for (uint256 i = 1; i <= dividendIdCount; i++) {
            Dividend memory dividend = dividends[i];

            propertyId[i - 1] = dividend.propertyId;
            totalDividendAmount[i - 1] = dividend.totalDividendAmount;
            totalInvestment[i - 1] = dividend.totalInvestment;
            dividendsAmountPaid[i - 1] = dividend.dividendsAmountPaid;
        }

    }

    function getDividendsByPropertyId(uint256 propertyId)
        public
        view
        returns (
            uint256[] memory dividendId,
            uint256[] memory totalDividendAmount,
            uint256[] memory totalInvestment,
            uint256[] memory dividendsAmountPaid
        )
    {
        require(propertyId > 0, "propertyId should be greater than zero.");

        dividendId = new uint256[](dividendIdCount);
        totalDividendAmount = new uint256[](dividendIdCount);
        totalInvestment = new uint256[](dividendIdCount);
        dividendsAmountPaid = new uint256[](dividendIdCount);

        uint256 counter = 0;

        for (uint256 i = 1; i <= dividendIdCount; i++) {
            Dividend memory dividend = dividends[i];

            if (dividend.propertyId == propertyId) {
                dividendId[counter] = i;
                totalDividendAmount[counter] = dividend.totalDividendAmount;
                totalInvestment[counter] = dividend.totalInvestment;
                dividendsAmountPaid[counter] = dividend.dividendsAmountPaid;
                counter++;
            }
        }

    }

    function getDividendByPropertyId(uint256 propertyId)
        public
        view
        returns (
            uint256 dividendId,
            uint256 totalDividendAmount,
            uint256 totalInvestment,
            uint256 dividendsAmountPaid
        )
    {
        require(propertyId > 0, "propertyId should be greater than zero.");

        dividendId = 0;
        totalDividendAmount = 0;
        totalInvestment = 0;
        dividendsAmountPaid = 0;

        for (uint256 i = 1; i <= dividendIdCount; i++) {
            Dividend memory dividend = dividends[i];

            if (dividend.propertyId == propertyId) {
                dividendId = i;
                totalDividendAmount = dividend.totalDividendAmount;
                totalInvestment = dividend.totalInvestment;
                dividendsAmountPaid = dividend.dividendsAmountPaid;
            }
        }
    }

    function getInvestorBalanceByDividendId(
        uint256 dividendId,
        address investor
    )
        public
        view
        returns (
            uint256 dividendBalanceAvailable,
            uint256 dividendBalanceWithdrawn
        )
    {
        require(dividendId > 0, "dividendId cannot be zero");

        Dividend storage dividend = dividends[dividendId];

         
        (, uint256 investmentByUser) = properties.getTotalAndHolderShares(
            dividend.propertyId,
            investor
        );

         
        uint256 totalDividendBalance = calculateDividend(
            dividend.totalInvestment,
            dividend.totalDividendAmount,
            investmentByUser
        );

        dividendBalanceAvailable = totalDividendBalance.sub(
            dividend.amountWithdrawnByInvestor[investor]
        );
        dividendBalanceWithdrawn = dividend.amountWithdrawnByInvestor[investor];
    }

     
    function() external payable {
        require(msg.data.length == 0, "Error in calling the function");
    }

     
    function calculateDividend(
        uint256 totalInvestments,
        uint256 totalDividend,
        uint256 userInvestment
    ) private pure returns (uint256) {
        return
            userInvestment
                .mul(1000000000000000000)
                .div(totalInvestments)
                .mul(totalDividend)
                .div(1000000000000000000);
    }

}