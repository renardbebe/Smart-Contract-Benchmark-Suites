 

pragma solidity 0.5.12;

contract AdvertisementTracker
{
    event CampaignLaunched(
        address owner,
        bytes32 bidId,
        string packageName,
        uint[3] countries,
        uint price,
        uint budget,
        uint startDate,
        uint endDate,
        string endPoint
    );

    event CampaignCancelled(
        address owner,
        bytes32 bidId
    );

    event BulkPoARegistered(
        address owner,
        bytes32 bidId,
        bytes rootHash,
        bytes signature,
        uint256 newHashes
    );

    constructor() public {
    }

    function createCampaign (
        bytes32 bidId,
        string memory packageName,
        uint[3] memory countries,
        uint price,
        uint budget,
        uint startDate,
        uint endDate,
        string memory endPoint)
    public
    {
        emit CampaignLaunched(
            msg.sender,
            bidId,
            packageName,
            countries,
            price,
            budget,
            startDate,
            endDate,
            endPoint);
    }

    function cancelCampaign (
        bytes32 bidId)
    public
    {
        emit CampaignCancelled(
            msg.sender, 
            bidId);
    }

    function bulkRegisterPoA (
        bytes32 bidId,
        bytes memory rootHash,
        bytes memory signature,
        uint256 newHashes)
    public
    {
        emit BulkPoARegistered(
            msg.sender,
            bidId,
            rootHash,
            signature,
            newHashes);
    }

}