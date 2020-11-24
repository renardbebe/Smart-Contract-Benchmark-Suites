 

pragma solidity ^0.4.17;

contract Election{
    
    address public manager;  
    
    bool public isActive;
    mapping(uint256 => address[]) public users;  
    mapping(address => uint256[]) public votes;  
    uint256 public totalUsers;  
    uint256 public totalVotes;  
    address[] public winners;  
    uint256 public winnerPrice;  
    uint256 public voteResult;  
    
    
     
    modifier mRequiredValue(){
        require(msg.value == .01 ether);
        _;
    }
    
     
    modifier mManagerOnly(){
        require(msg.sender == manager);
        _;
    }
    
     
    modifier mIsActive(){
        require(isActive);
        _;
    }
    
     
    function Election() public{
        manager = msg.sender;
        isActive = true;
    }
    
     
    function voteRequest(uint256 guess) public payable mIsActive mRequiredValue {
        require(guess > 0);
        require(guess <= 1000);
        address[] storage list = users[guess];
        list.push(msg.sender);
        votes[msg.sender].push(guess);
        totalUsers++;
        totalVotes += guess;
    }
    
     
    function getUserVotes() public view returns(uint256[]){
        return votes[msg.sender];
    }

     
    function getSummary() public returns(uint256, uint256, uint256) {
        return(
            totalVotes,
            totalUsers,
            this.balance
        );
    }
    
     
    function pause() public mManagerOnly {
        isActive = !isActive;
    }
    
     
    function finalizeContract(uint256 winningNumber) public mManagerOnly {
        voteResult = winningNumber;
        address[] memory list = users[winningNumber];
        address[] memory secondaryList;
        uint256 winnersCount = list.length;

        if(winnersCount == 0){
             
            bool loop = true;
            uint256 index = 1;
            while(loop == true){
                list = users[winningNumber-index];
                secondaryList = users[winningNumber+index];
                winnersCount = list.length + secondaryList.length;

                if(winnersCount > 0){
                    loop = false;
                }
                else{
                    index++;
                }
            }
        }
        
        uint256 managerFee = (this.balance/100)*5;  
        uint256 reward = (this.balance - managerFee) / winnersCount;  
        winnerPrice = reward;
        
         
        winners = list;
         
        for (uint256 i = 0; i < list.length; i++) {
            list[i].transfer(reward);
        }
                
         
        for (uint256 j = 0; j < secondaryList.length; j++) {
             
            secondaryList[j].transfer(reward);
            winners.push(secondaryList[j]);  
        }
        
         
        manager.transfer(this.balance);
        
        
    }
    
}