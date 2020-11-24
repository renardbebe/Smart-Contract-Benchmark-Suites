 

pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

contract nota { 
    
address owner;

bool votefinish;

    struct Voter {
        bool voted;
        bool whitelist;
    }
struct candidate {
        string name;
        uint256 voteCount;
    }

mapping(address => Voter) voter;
mapping(string => candidate) candidates;
 
uint256 setupcheck = 1;
string[] candiname;
function setup (address[] memory _addresses, uint256 countofaddress, string[] memory _candidate, uint256 countofcandidate) public {
    if(setupcheck == 1){
     
    owner = msg.sender;
    for(uint i=0; i<countofaddress; i++){
        voter[_addresses[i]].voted = false;
        voter[_addresses[i]].whitelist = true;
    }
    for(uint i=0; i<countofcandidate; i++){
         
        candidates[_candidate[i]] = candidate(_candidate[i], 0);
         
         
    }
        setupcheck = 0;
    }
}

modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
function isRegistered() public view returns (bool registered) {
    if(voter[msg.sender].whitelist == true)
        registered = true;
    else
        registered = false;
    return registered;
}

function vote(string memory votetocandidate) public {
    if(votefinish != true && isRegistered() == true && voter[msg.sender].voted == false){
    candidates[votetocandidate].voteCount ++;
    voter[msg.sender].voted = true;
    }
    else{

    }
}
function checkvote() public view returns (bool) {
    return voter[msg.sender].voted;
}
function endvote() public onlyOwner{
votefinish = true;
}

function getdata() public view returns (uint256, uint256, uint256, uint256, uint256){
return (candidates["James Lee"].voteCount , candidates["Mark Kim"].voteCount , candidates["Jun Park"].voteCount , candidates["Yuna Lim"].voteCount , candidates["Olivia Ha"].voteCount  );
}
}