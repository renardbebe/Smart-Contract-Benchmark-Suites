 

pragma solidity ^0.5.8;

contract GoncaloColorTeam {
     
    address payable public beneficiary = 0x82338B1b27cfC0C27D79c3738B748f951Ab1a7A0;

    uint256 public amountContributedForBlueTeam;
    uint256 public amountContributedForRedTeam;
    
     
    function claimDonation() public {
        beneficiary.transfer(address(this).balance);
    }

    function contributeBlue() public payable {
        amountContributedForBlueTeam += msg.value;
    }

    function contributeRed() public payable {
        amountContributedForRedTeam += msg.value;
    }
    
    function() external payable {
        if(msg.value % 2 == 0) {
            amountContributedForRedTeam += msg.value;
        } else {
            amountContributedForBlueTeam += msg.value;
        }
    }
    
     
    function whoIsWinning() public view returns (uint256) {
        if(amountContributedForBlueTeam > amountContributedForRedTeam) {
            return 1;
        } else if (amountContributedForBlueTeam < amountContributedForRedTeam) {
            return 2;
        }
        
        return 0;
    }
}