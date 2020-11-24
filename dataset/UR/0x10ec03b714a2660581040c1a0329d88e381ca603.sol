 

pragma solidity ^0.4.2;

 

contract EthPledge {
    
    address public owner;
    
    function EthPledge() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    struct Campaign {
        address benefactor;  
        address charity;
        uint amountPledged;
        uint amountRaised;
        uint donationsReceived;
        uint multiplier;  
        bool active;
        bool successful;
        uint timeStarted;
        bytes32 descriptionPart1;  
        bytes32 descriptionPart2;
        bytes32 descriptionPart3;
        bytes32 descriptionPart4;
    }
    
    mapping (uint => Campaign) public campaign;
    
    mapping (address => uint[]) public campaignsStartedByUser;
    
    mapping (address => mapping(uint => uint)) public addressToCampaignIDToFundsDonated;
    
    mapping (address => uint[]) public campaignIDsDonatedToByUser;  
    
    struct Donation {
        address donator;
        uint amount;
        uint timeSent;
    }
    
    mapping (uint => mapping(uint => Donation)) public campaignIDtoDonationNumberToDonation;
    
    uint public totalCampaigns;
    
    uint public totalDonations;
    
    uint public totalETHraised;
    
    uint public minimumPledgeAmount = 10**14;  
    
    function createCampaign (address charity, uint multiplier, bytes32 descriptionPart1, bytes32 descriptionPart2, bytes32 descriptionPart3, bytes32 descriptionPart4) payable {
        require (msg.value >= minimumPledgeAmount);
        require (multiplier > 0);
        campaign[totalCampaigns].benefactor = msg.sender;
        campaign[totalCampaigns].charity = charity;
        campaign[totalCampaigns].multiplier = multiplier;
        campaign[totalCampaigns].timeStarted = now;
        campaign[totalCampaigns].amountPledged = msg.value;
        campaign[totalCampaigns].active = true;
        campaign[totalCampaigns].descriptionPart1 = descriptionPart1;
        campaign[totalCampaigns].descriptionPart2 = descriptionPart2;
        campaign[totalCampaigns].descriptionPart3 = descriptionPart3;
        campaign[totalCampaigns].descriptionPart4 = descriptionPart4;
        campaignsStartedByUser[msg.sender].push(totalCampaigns);
        totalETHraised += msg.value;
        totalCampaigns++;
    }
    
    function cancelCampaign (uint campaignID) {
        
         
        
        require (msg.sender == campaign[campaignID].benefactor);
        require (campaign[campaignID].active == true);
        campaign[campaignID].active = false;
        campaign[campaignID].successful = false;
        uint amountShort = campaign[campaignID].amountPledged - (campaign[campaignID].amountRaised * campaign[campaignID].multiplier);
        uint amountToSendToCharity = campaign[campaignID].amountPledged + campaign[campaignID].amountRaised - amountShort;
        campaign[campaignID].charity.transfer(amountToSendToCharity);
        campaign[campaignID].benefactor.transfer(amountShort);
    }
    
    function contributeToCampaign (uint campaignID) payable {
        require (msg.value > 0);
        require (campaign[campaignID].active == true);
        campaignIDsDonatedToByUser[msg.sender].push(campaignID);
        addressToCampaignIDToFundsDonated[msg.sender][campaignID] += msg.value;
        
        campaignIDtoDonationNumberToDonation[campaignID][campaign[campaignID].donationsReceived].donator = msg.sender;
        campaignIDtoDonationNumberToDonation[campaignID][campaign[campaignID].donationsReceived].amount = msg.value;
        campaignIDtoDonationNumberToDonation[campaignID][campaign[campaignID].donationsReceived].timeSent = now;
        
        campaign[campaignID].donationsReceived++;
        totalDonations++;
        totalETHraised += msg.value;
        campaign[campaignID].amountRaised += msg.value;
        if (campaign[campaignID].amountRaised >= (campaign[campaignID].amountPledged / campaign[campaignID].multiplier)) {
             
            campaign[campaignID].active = false;
            campaign[campaignID].successful = true;
            campaign[campaignID].charity.transfer(campaign[campaignID].amountRaised + campaign[campaignID].amountPledged);
        }
    }
    
    function adjustMinimumPledgeAmount (uint newMinimum) onlyOwner {
        require (newMinimum > 0);
        minimumPledgeAmount = newMinimum;
    }
    
     
    
    function returnHowMuchMoreETHNeeded (uint campaignID) view returns (uint) {
        return (campaign[campaignID].amountPledged / campaign[campaignID].multiplier - campaign[campaignID].amountRaised);
    }
    
    function generalInfo() view returns (uint, uint, uint) {
        return (totalCampaigns, totalDonations, totalETHraised);
    }
    
    function lookupDonation (uint campaignID, uint donationNumber) view returns (address, uint, uint) {
        return (campaignIDtoDonationNumberToDonation[campaignID][donationNumber].donator, campaignIDtoDonationNumberToDonation[campaignID][donationNumber].amount, campaignIDtoDonationNumberToDonation[campaignID][donationNumber].timeSent);
    }
    
     
    
    function lookupCampaignPart1 (uint campaignID) view returns (address, address, uint, uint, uint, bytes32, bytes32) {
        return (campaign[campaignID].benefactor, campaign[campaignID].charity, campaign[campaignID].amountPledged, campaign[campaignID].amountRaised,campaign[campaignID].donationsReceived, campaign[campaignID].descriptionPart1, campaign[campaignID].descriptionPart2);
    }
    
    function lookupCampaignPart2 (uint campaignID) view returns (uint, bool, bool, uint, bytes32, bytes32) {
        return (campaign[campaignID].multiplier, campaign[campaignID].active, campaign[campaignID].successful, campaign[campaignID].timeStarted, campaign[campaignID].descriptionPart3, campaign[campaignID].descriptionPart4);
    }
    
     
    
    function lookupUserDonationHistoryByCampaignID (address user) view returns (uint[]) {
        return (campaignIDsDonatedToByUser[user]);
    }
    
    function lookupAmountUserDonatedToCampaign (address user, uint campaignID) view returns (uint) {
        return (addressToCampaignIDToFundsDonated[user][campaignID]);
    }
    
}