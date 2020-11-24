 

pragma solidity ^0.4.21;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract MatchBetting {
    using SafeMath for uint256;

     
    struct Team {
        string name;
        mapping(address => uint) bettingContribution;
        mapping(address => uint) ledgerBettingContribution;
        uint totalAmount;
        uint totalParticipants;
    }
     
    Team[2] public teams;
     
    bool public matchCompleted = false;
     
    bool public stopMatchBetting = false;
     
    uint public minimumBetAmount;
     
     
     
     
     
    uint public winIndex = 4;
     
    uint matchNumber;
     
    address public owner;
     
    address public jackpotAddress;

    address[] public betters;

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
     
     
    function MatchBetting(string teamA, string teamB, uint _minimumBetAmount, address sender, address _jackpotAddress, uint _matchNumber) public {
        Team memory newTeamA = Team({
            totalAmount : 0,
            name : teamA,
            totalParticipants : 0
            });

        Team memory newTeamB = Team({
            totalAmount : 0,
            name : teamB,
            totalParticipants : 0
            });

        teams[0] = newTeamA;
        teams[1] = newTeamB;
        minimumBetAmount = _minimumBetAmount;
        owner = sender;
        jackpotAddress = _jackpotAddress;
        matchNumber = _matchNumber;
    }

     
    function placeBet(uint index) public payable {
        require(msg.value >= minimumBetAmount);
        require(!stopMatchBetting);
        require(!matchCompleted);

        if(teams[0].bettingContribution[msg.sender] == 0 && teams[1].bettingContribution[msg.sender] == 0) {
            betters.push(msg.sender);
        }

        if (teams[index].bettingContribution[msg.sender] == 0) {
            teams[index].totalParticipants = teams[index].totalParticipants.add(1);
        }
        teams[index].bettingContribution[msg.sender] = teams[index].bettingContribution[msg.sender].add(msg.value);
        teams[index].ledgerBettingContribution[msg.sender] = teams[index].ledgerBettingContribution[msg.sender].add(msg.value);
        teams[index].totalAmount = teams[index].totalAmount.add(msg.value);
    }

     
    function setMatchOutcome(uint winnerIndex, string teamName) public onlyOwner {
        if (winnerIndex == 0 || winnerIndex == 1) {
             
            require(compareStrings(teams[winnerIndex].name, teamName));
            uint loosingIndex = (winnerIndex == 0) ? 1 : 0;
             
            if (teams[winnerIndex].totalAmount != 0 && teams[loosingIndex].totalAmount != 0) {
                uint jackpotShare = (teams[loosingIndex].totalAmount).div(5);
                jackpotAddress.transfer(jackpotShare);
            }
        }
        winIndex = winnerIndex;
        matchCompleted = true;
    }

     
    function setStopMatchBetting() public onlyOwner{
        stopMatchBetting = true;
    }

     
    function getEther() public {
        require(matchCompleted);

        if (winIndex == 2) {
            uint betOnTeamA = teams[0].bettingContribution[msg.sender];
            uint betOnTeamB = teams[1].bettingContribution[msg.sender];

            teams[0].bettingContribution[msg.sender] = 0;
            teams[1].bettingContribution[msg.sender] = 0;

            uint totalBetContribution = betOnTeamA.add(betOnTeamB);
            require(totalBetContribution != 0);

            msg.sender.transfer(totalBetContribution);
        } else {
            uint loosingIndex = (winIndex == 0) ? 1 : 0;
             

            uint betValue;
            if (teams[winIndex].totalAmount == 0) {
                betValue = teams[loosingIndex].bettingContribution[msg.sender];
                require(betValue != 0);

                teams[loosingIndex].bettingContribution[msg.sender] = 0;
                msg.sender.transfer(betValue);
            } else {
                betValue = teams[winIndex].bettingContribution[msg.sender];
                require(betValue != 0);

                teams[winIndex].bettingContribution[msg.sender] = 0;

                uint winTotalAmount = teams[winIndex].totalAmount;
                uint loosingTotalAmount = teams[loosingIndex].totalAmount;

                if (loosingTotalAmount == 0) {
                    msg.sender.transfer(betValue);
                } else {
                     
                    uint userTotalShare = betValue;
                    uint bettingShare = betValue.mul(80).div(100).mul(loosingTotalAmount).div(winTotalAmount);
                    userTotalShare = userTotalShare.add(bettingShare);

                    msg.sender.transfer(userTotalShare);
                }
            }
        }
    }

    function getBetters() public view returns (address[]) {
        return betters;
    }

     
    function getMatchInfo() public view returns (string, uint, uint, string, uint, uint, uint, bool, uint, uint, bool) {
        return (teams[0].name, teams[0].totalAmount, teams[0].totalParticipants, teams[1].name,
        teams[1].totalAmount, teams[1].totalParticipants, winIndex, matchCompleted, minimumBetAmount, matchNumber, stopMatchBetting);
    }

     
    function userBetContribution(address userAddress) public view returns (uint, uint) {
        return (teams[0].bettingContribution[userAddress], teams[1].bettingContribution[userAddress]);
    }

     
    function ledgerUserBetContribution(address userAddress) public view returns (uint, uint) {
        return (teams[0].ledgerBettingContribution[userAddress], teams[1].ledgerBettingContribution[userAddress]);
    }

     
    function compareStrings(string a, string b) private pure returns (bool){
        return keccak256(a) == keccak256(b);
    }
}

contract MatchBettingFactory is Ownable {
     
    address[] deployedMatches;
     
    address public jackpotAddress;

     
    function MatchBettingFactory(address _jackpotAddress) public{
        jackpotAddress = _jackpotAddress;
    }

     
    function createMatch(string teamA, string teamB, uint _minimumBetAmount, uint _matchNumber) public onlyOwner{
        address matchBetting = new MatchBetting(teamA, teamB, _minimumBetAmount, msg.sender, jackpotAddress, _matchNumber);
        deployedMatches.push(matchBetting);
    }

     
    function getDeployedMatches() public view returns (address[]) {
        return deployedMatches;
    }
}