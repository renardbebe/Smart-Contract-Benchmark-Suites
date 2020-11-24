 

pragma solidity ^0.4.13;

interface FundInterface {

     

    event PortfolioContent(address[] assets, uint[] holdings, uint[] prices);
    event RequestUpdated(uint id);
    event Redeemed(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);
    event FeesConverted(uint atTimestamp, uint shareQuantityConverted, uint unclaimed);
    event CalculationUpdate(uint atTimestamp, uint managementFee, uint performanceFee, uint nav, uint sharePrice, uint totalSupply);
    event ErrorMessage(string errorMessage);

     
     
    function requestInvestment(uint giveQuantity, uint shareQuantity, address investmentAsset) external;
    function executeRequest(uint requestId) external;
    function cancelRequest(uint requestId) external;
    function redeemAllOwnedAssets(uint shareQuantity) external returns (bool);
     
    function enableInvestment(address[] ofAssets) external;
    function disableInvestment(address[] ofAssets) external;
    function shutDown() external;

     
    function emergencyRedeem(uint shareQuantity, address[] requestedAssets) public returns (bool success);
    function calcSharePriceAndAllocateFees() public returns (uint);


     
     
    function getModules() view returns (address, address, address);
    function getLastRequestId() view returns (uint);
    function getManager() view returns (address);

     
    function performCalculations() view returns (uint, uint, uint, uint, uint, uint, uint);
    function calcSharePrice() view returns (uint);
}

interface ComplianceInterface {

     

     
     
     
     
     
    function isInvestmentPermitted(
        address ofParticipant,
        uint256 giveQuantity,
        uint256 shareQuantity
    ) view returns (bool);

     
     
     
     
     
    function isRedemptionPermitted(
        address ofParticipant,
        uint256 shareQuantity,
        uint256 receiveQuantity
    ) view returns (bool);
}

contract DBC {

     

    modifier pre_cond(bool condition) {
        require(condition);
        _;
    }

    modifier post_cond(bool condition) {
        _;
        assert(condition);
    }

    modifier invariant(bool condition) {
        require(condition);
        _;
        assert(condition);
    }
}

contract Owned is DBC {

     

    address public owner;

     

    function Owned() { owner = msg.sender; }

    function changeOwner(address ofNewOwner) pre_cond(isOwner()) { owner = ofNewOwner; }

     

    function isOwner() internal returns (bool) { return msg.sender == owner; }

}

contract BugBountyCompliance is ComplianceInterface, DBC, Owned {

    mapping (address => bool) isWhitelisted;

     

     
     
     
     
     
    function isInvestmentPermitted(
        address ofParticipant,
        uint256 giveQuantity,
        uint256 shareQuantity
    )
        view
        returns (bool)
    {
        return FundInterface(msg.sender).getManager() == ofParticipant;
    }

     
     
     
     
     
    function isRedemptionPermitted(
        address ofParticipant,
        uint256 shareQuantity,
        uint256 receiveQuantity
    )
        view
        returns (bool)
    {
        return true;     
    }

     
     
     
    function isCompetitionAllowed(address user)
        view
        returns (bool)
    {
        return isWhitelisted[user];
    }


     

    function addToWhitelist(address user)
        pre_cond(isOwner())
    {
        isWhitelisted[user] = true;
    }

    function removeFromWhitelist(address user)
        pre_cond(isOwner())
    {
        isWhitelisted[user] = false;
    }
}