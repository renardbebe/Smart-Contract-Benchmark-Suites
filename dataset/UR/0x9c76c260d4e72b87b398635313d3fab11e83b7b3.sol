 

pragma solidity ^0.4.13;

interface CompetitionInterface {

     

    event Register(uint withId, address fund, address manager);
    event ClaimReward(address registrant, address fund, uint shares);

     

    function termsAndConditionsAreSigned(address byManager, uint8 v, bytes32 r, bytes32 s) view returns (bool);
    function isWhitelisted(address x) view returns (bool);
    function isCompetitionActive() view returns (bool);

     

    function getMelonAsset() view returns (address);
    function getRegistrantId(address x) view returns (uint);
    function getRegistrantFund(address x) view returns (address);
    function getCompetitionStatusOfRegistrants() view returns (address[], address[], bool[]);
    function getTimeTillEnd() view returns (uint);
    function getEtherValue(uint amount) view returns (uint);
    function calculatePayout(uint payin) view returns (uint);

     

    function registerForCompetition(address fund, uint8 v, bytes32 r, bytes32 s) payable;
    function batchAddToWhitelist(uint maxBuyinQuantity, address[] whitelistants);
    function withdrawMln(address to, uint amount);
    function claimReward();

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

contract CompetitionCompliance is ComplianceInterface, DBC, Owned {

    address public competitionAddress;

     

     
     
    function CompetitionCompliance(address ofCompetition) public {
        competitionAddress = ofCompetition;
    }

     

     
     
     
     
     
    function isInvestmentPermitted(
        address ofParticipant,
        uint256 giveQuantity,
        uint256 shareQuantity
    )
        view
        returns (bool)
    {
        return competitionAddress == ofParticipant;
    }

     
     
     
     
     
    function isRedemptionPermitted(
        address ofParticipant,
        uint256 shareQuantity,
        uint256 receiveQuantity
    )
        view
        returns (bool)
    {
        return competitionAddress == ofParticipant;
    }

     
     
     
    function isCompetitionAllowed(
        address x
    )
        view
        returns (bool)
    {
        return CompetitionInterface(competitionAddress).isWhitelisted(x) && CompetitionInterface(competitionAddress).isCompetitionActive();
    }


     

     
     
    function changeCompetitionAddress(
        address ofCompetition
    )
        pre_cond(isOwner())
    {
        competitionAddress = ofCompetition;
    }

}