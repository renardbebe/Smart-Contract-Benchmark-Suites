 

pragma solidity ^0.4.6;

 
 
contract Owned {
     
     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }

    address public owner;

     
    function Owned() { owner = msg.sender;}

     
     
     
    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}


contract GivethDirectory is Owned {

    enum CampaignStatus {Preparing, Active, Obsoleted, Deleted}

    struct Campaign {
        string name;
        string description;
        string url;
        address token;
        address vault;
        address milestoneTracker;
        string extra;
        CampaignStatus status;
    }

    Campaign[] campaigns;

    function addCampaign(
        string name,
        string description,
        string url,
        address token,
        address vault,
        address milestoneTracker,
        string extra
    ) onlyOwner returns(uint idCampaign) {

        idCampaign = campaigns.length++;
        Campaign c = campaigns[idCampaign];
        c.name = name;
        c.description = description;
        c.url = url;
        c.token = token;
        c.vault = vault;
        c.milestoneTracker = milestoneTracker;
        c.extra = extra;
    }

    function updateCampaign(
        uint idCampaign,
        string name,
        string description,
        string url,
        address token,
        address vault,
        address milestoneTracker,
        string extra
    ) onlyOwner {
        if (idCampaign >= campaigns.length) throw;
        Campaign c = campaigns[idCampaign];
        c.name = name;
        c.description = description;
        c.url = url;
        c.token = token;
        c.vault = vault;
        c.milestoneTracker = milestoneTracker;
        c.extra = extra;
    }

    function changeStatus(uint idCampaign, CampaignStatus newStatus) onlyOwner {
        if (idCampaign >= campaigns.length) throw;
        Campaign c = campaigns[idCampaign];
        c.status = newStatus;
    }

    function getCampaign(uint idCampaign) constant returns (
        string name,
        string description,
        string url,
        address token,
        address vault,
        address milestoneTracker,
        string extra,
        CampaignStatus status
    ) {
        if (idCampaign >= campaigns.length) throw;
        Campaign c = campaigns[idCampaign];
        name = c.name;
        description = c.description;
        url = c.url;
        token = c.token;
        vault = c.vault;
        milestoneTracker = c.milestoneTracker;
        extra = c.extra;
        status = c.status;
    }

    function numberOfCampaigns() constant returns (uint) {
        return campaigns.length;
    }

}