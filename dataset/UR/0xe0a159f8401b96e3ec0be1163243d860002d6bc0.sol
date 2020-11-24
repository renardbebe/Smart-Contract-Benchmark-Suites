 

pragma solidity ^0.4.17;

 
contract VotingChallenge {
    uint public challengeDuration;
    uint public challengePrize;
    uint public creatorPrize;
    uint public cryptoVersusPrize;
    uint public challengeStarted;
    uint public candidatesNumber;
    address public creator;
    uint16 public creatorFee;        
    address public cryptoVersusWallet;
    uint16 public cryptoVersusFee;   
    uint public winner;
    bool public isVotingPeriod;
    bool public beforeVoting;
    uint[] public votes;
    mapping( address => mapping (uint => uint)) public userVotesDistribution;
    uint private lastPayment;

     
    modifier inVotingPeriod() {
        require(isVotingPeriod);
        _;
    }

    modifier afterVotingPeriod() {
        require(!isVotingPeriod);
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

     
    event ChallengeBegins(address _creator, uint16 _creatorFee, uint _candidatesNumber, uint _challengeDuration);
    event NewVotesFor(address _participant, uint _candidate, uint _votes);
    event TransferVotes(address _from, address _to, uint _candidateIndex, uint _votes);
    event EndOfChallenge(uint _winner, uint _winnerVotes, uint _challengePrize);
    event RewardWasPaid(address _participant, uint _amount);
    event CreatorRewardWasPaid(address _creator, uint _amount);
    event CryptoVersusRewardWasPaid(address _cryptoVersusWallet, uint _amount);

     
    constructor(uint _challengeDuration, uint _candidatesNumber, uint16 _creatorFee) public {
        challengeDuration = _challengeDuration;
        candidatesNumber = _candidatesNumber;
        votes.length = candidatesNumber + 1;  
        creator = msg.sender;
        cryptoVersusWallet = 0xa0bedE75cfeEF0266f8A31b47074F5f9fBE1df80;
        creatorFee = _creatorFee;
        cryptoVersusFee = 25;
        beforeVoting = true;

         
        if(creatorFee > 1000) {
            creatorFee = 1000;
            cryptoVersusFee = 0;
            return;
        }
        if(cryptoVersusFee > 1000) {
            cryptoVersusFee = 1000;
            creatorFee = 0;
            return;
        }
        if(creatorFee + cryptoVersusFee > 1000) {
            cryptoVersusFee = 1000 - creatorFee;
        }
    }

     
    function getTime() public view returns (uint) {
        return now;
    }

    function getAllVotes() public view returns (uint[]) {
        return votes;
    }

     
    function startChallenge() public onlyCreator {
        require(beforeVoting);
        isVotingPeriod = true;
        beforeVoting = false;
        challengeStarted = now;

        emit ChallengeBegins(creator, creatorFee, candidatesNumber, challengeDuration);
    }

     
    function changeCreator(address newCreator) public onlyCreator {
        creator = newCreator;
    }

     
    function changeWallet(address newWallet) public {
        require(msg.sender == cryptoVersusWallet);
        cryptoVersusWallet = newWallet;
    }

     
    function voteForCandidate(uint candidate) public payable inVotingPeriod {
        require(candidate <= candidatesNumber);
        require(candidate > 0);
        require(msg.value > 0);

        lastPayment = msg.value;
        if(checkEndOfChallenge()) {
            msg.sender.transfer(lastPayment);
            return;
        }
        lastPayment = 0;

         
        votes[candidate] += msg.value;

         
        userVotesDistribution[msg.sender][candidate] += msg.value;

         
        emit NewVotesFor(msg.sender, candidate, msg.value);
    }

     
    function transferVotes (address to, uint candidate) public inVotingPeriod {
        require(userVotesDistribution[msg.sender][candidate] > 0);
        uint votesToTransfer = userVotesDistribution[msg.sender][candidate];
        userVotesDistribution[msg.sender][candidate] = 0;
        userVotesDistribution[to][candidate] += votesToTransfer;

         
        emit TransferVotes(msg.sender, to, candidate, votesToTransfer);
    }

     
     
    function checkEndOfChallenge() public inVotingPeriod returns (bool) {
        if (challengeStarted + challengeDuration > now)
            return false;
        uint theWinner;
        uint winnerVotes;
        uint actualBalance = address(this).balance - lastPayment;

        for (uint i = 1; i <= candidatesNumber; i++) {
            if (votes[i] > winnerVotes) {
                winnerVotes = votes[i];
                theWinner = i;
            }
        }
        winner = theWinner;
        creatorPrize = (actualBalance * creatorFee) / 1000;
        cryptoVersusPrize = (actualBalance * cryptoVersusFee) / 1000;
        challengePrize = actualBalance - creatorPrize - cryptoVersusPrize;
        isVotingPeriod = false;

         
        emit EndOfChallenge(winner, winnerVotes, challengePrize);
        return true;
    }

     
    function getReward() public afterVotingPeriod {
        require(userVotesDistribution[msg.sender][winner] > 0);

         
        uint userVotesForWinner = userVotesDistribution[msg.sender][winner];
        userVotesDistribution[msg.sender][winner] = 0;
        uint reward = (challengePrize * userVotesForWinner) / votes[winner];
        msg.sender.transfer(reward);

         
        emit RewardWasPaid(msg.sender, reward);
    }

     
    function sendReward(address to) public afterVotingPeriod {
        require(userVotesDistribution[to][winner] > 0);

         
        uint userVotesForWinner = userVotesDistribution[to][winner];
        userVotesDistribution[to][winner] = 0;
        uint reward = (challengePrize * userVotesForWinner) / votes[winner];
        to.transfer(reward);

         
        emit RewardWasPaid(to, reward);
    }

     
    function sendCreatorReward() public afterVotingPeriod {
        require(creatorPrize > 0);
        uint creatorReward = creatorPrize;
        creatorPrize = 0;
        creator.transfer(creatorReward);

         
        emit CreatorRewardWasPaid(creator, creatorReward);
    }

     
    function sendCryptoVersusReward() public afterVotingPeriod {
        require(cryptoVersusPrize > 0);
        uint cryptoVersusReward = cryptoVersusPrize;
        cryptoVersusPrize = 0;
        cryptoVersusWallet.transfer(cryptoVersusReward);

         
        emit CryptoVersusRewardWasPaid(cryptoVersusWallet, cryptoVersusReward);
    }
}