 

pragma solidity 0.5.1;

 
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
    _;
    }

}

contract Claimable is Ownable {
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

 
contract Synvote is Claimable {

    string  public constant  VERSION='2018.02';
    uint256 public constant  MINETHVOTE = 1*(10**17);
    

     
     
     
    enum StageName {preList, inProgress, voteFinished,rewardWithdrawn}
    struct PrjProperties{
        address prjAddress;
        uint256 voteCount;
        uint256 prjWeiRaised;
    }

     
     
     
    StageName public currentStage;
    mapping(bytes32 => PrjProperties) public projects; 
    string public currentWinner;
    uint64  public voteFinishDate;
     
     
     
     

     
     
     
    event VoteStarted(uint64 _when);
    event NewBet(address _who, uint256 _wei, string _prj);
    event VoteFinished(address _who, uint64 _when);
   
    
    function() external { }
    
     
     
     
     
     
    function addProjectToVote(string calldata _prjName, address _prjAddress) 
    external 
    payable 
    onlyOwner
    {
        require(currentStage == StageName.preList, "Can't add item after vote has starting!");
        require(_prjAddress != address(0),"Address must be valid!");
        bytes32 hash = keccak256(bytes(_prjName));
        require( projects[hash].prjAddress == address(0), 
            "It seems like this item allready exist!"
        );
        projects[hash] = PrjProperties({
                prjAddress: _prjAddress,
                voteCount: 0,
                prjWeiRaised: 0
            });
    }
    
     
     
     
    function startVote(uint64 _votefinish) external onlyOwner {
        require(currentStage == StageName.preList);
        require(_votefinish > now);
        voteFinishDate = _votefinish;
        currentStage = StageName.inProgress;
        emit VoteStarted(uint64(now));
    }

     
     
     
    function vote(string calldata _prjName) external payable {
        require(currentStage == StageName.inProgress,
            "Vote disable now!"
        
        );
        require(msg.value >= MINETHVOTE, "Please send more ether!");
        bytes32 hash = keccak256(bytes(_prjName));
        PrjProperties memory currentBet = projects[hash]; 
        require(currentBet.prjAddress != address(0), 
            "It seems like there is no item with that name"
        );
        projects[hash].voteCount = currentBet.voteCount + 1;
        projects[hash].prjWeiRaised = currentBet.prjWeiRaised + msg.value;
        emit NewBet(msg.sender, msg.value, _prjName);
         
        if  (currentBet.voteCount + 1 > projects[keccak256(bytes(currentWinner))].voteCount)
            currentWinner = _prjName;
         
        if  (now >= voteFinishDate)
            currentStage = StageName.voteFinished;
            emit VoteFinished(msg.sender, uint64(now));
        
    }

     
     
    function withdrawWinner() external {
        require(currentStage == StageName.voteFinished, 
            "Withdraw disable yet/allready!"
        );
        require(msg.sender == projects[keccak256(bytes(currentWinner))].prjAddress,
            "Only winner can Withdraw reward"
        );
        currentStage = StageName.rewardWithdrawn;
        msg.sender.transfer(address(this).balance);
    }
    
     
     
     
     
    function calculateSha3(string memory _hashinput) public pure returns (bytes32){
        return keccak256(bytes(_hashinput)); 
    }
   
    
     
    function kill() external onlyOwner {
        require(currentStage == StageName.rewardWithdrawn, 
            "Withdraw reward first!!!"
        );
        selfdestruct(msg.sender);
    }
    
         
}