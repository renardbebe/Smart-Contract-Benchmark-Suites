 

pragma solidity ^0.4.8;

 
contract FederatedOracleBytes8 {
    struct Voter {
        bool isVoter;
        bool hasVoted;
    }

    event VoterAdded(address account);
    event VoteSubmitted(address account, bytes8 value);
    event ValueFinalized(bytes8 value);

    mapping(address => Voter) public voters;
    mapping(bytes8 => uint8) public votes;

    uint8 public m;
    uint8 public n;
    bytes8 public finalValue;

    uint8 private voterCount;
    address private creator;

    function FederatedOracleBytes8(uint8 m_, uint8 n_) {
        creator = msg.sender;
        m = m_;
        n = n_;
    }

    function addVoter(address account) {
        if (msg.sender != creator) {
            throw;
        }
        if (voterCount == n) {
            throw;
        }

        var voter = voters[account];
        if (voter.isVoter) {
            throw;
        }

        voter.isVoter = true;
        voterCount++;
        VoterAdded(account);
    }

    function submitValue(bytes8 value) {
        var voter = voters[msg.sender];
        if (!voter.isVoter) {
            throw;
        }
        if (voter.hasVoted) {
            throw;
        }

        voter.hasVoted = true;
        votes[value]++;
        VoteSubmitted(msg.sender, value);

        if (votes[value] == m) {
            finalValue = value;
            ValueFinalized(value);
        }
    }
}

 
 
 
 
 
 
 
 
library ByteBracket {
    function getBracketScore(bytes8 bracket, bytes8 results, uint64 filter)
        constant
        returns (uint8 points)
    {
        uint8 roundNum = 0;
        uint8 numGames = 32;
        uint64 blacklist = (uint64(1) << numGames) - 1;
        uint64 overlap = uint64(~(bracket ^ results));

        while (numGames > 0) {
            uint64 scores = overlap & blacklist;
            points += popcount(scores) << roundNum;
            blacklist = pairwiseOr(scores & filter);
            overlap >>= numGames;
            filter >>= numGames;
            numGames /= 2;
            roundNum++;
        }
    }

    function getScoringMask(bytes8 results) constant returns (uint64 mask) {
         
        bytes8 bitSelector = 1 << 62;
        for (uint i = 0; i < 31; i++) {
            mask <<= 2;
            if (results & bitSelector != 0) {
                mask |= 1;
            } else {
                mask |= 2;
            }
            results <<= 1;
        }
    }

     
     
     
     
    function pairwiseOr(uint64 bits) internal returns (uint64) {
        uint64 tmp;
        tmp = (bits ^ (bits >> 1)) & 0x22222222;
        bits ^= (tmp ^ (tmp << 1));
        tmp = (bits ^ (bits >> 2)) & 0x0c0c0c0c;
        bits ^= (tmp ^ (tmp << 2));
        tmp = (bits ^ (bits >> 4)) & 0x00f000f0;
        bits ^= (tmp ^ (tmp << 4));
        tmp = (bits ^ (bits >> 8)) & 0x0000ff00;
        bits ^= (tmp ^ (tmp << 8));
        uint64 evens = bits >> 16;
        uint64 odds = bits % 0x10000;
        return evens | odds;
    }

     
    function popcount(uint64 bits) internal returns (uint8) {
        bits -= (bits >> 1) & 0x5555555555555555;
        bits = (bits & 0x3333333333333333) + ((bits >> 2) & 0x3333333333333333);
        bits = (bits + (bits >> 4)) & 0x0f0f0f0f0f0f0f0f;
        return uint8(((bits * 0x0101010101010101) & 0xffffffffffffffff) >> 56);
    }
}

 
contract MarchMadness {
    struct Submission {
        bytes32 commitment;
        bytes8 bracket;
        uint8 score;
        bool collectedWinnings;
        bool collectedEntryFee;
    }

    event SubmissionAccepted(address account);
    event NewWinner(address winner, uint8 score);
    event TournamentOver();

    FederatedOracleBytes8 resultsOracle;

	mapping(address => Submission) submissions;

     
    uint public winnings;

     
    uint public numWinners;

     
    uint64 private scoringMask;

     
    uint public entryFee;

     
    uint public scoringDuration;

     
    uint public tournamentStartTime;

     
     
    uint public noContestTime;

     
    uint public contestOverTime;

     
    bytes8 public results;

     
    uint8 public winningScore;

     
    uint32 public maxSubmissions;

     
    uint32 public numSubmissions;

     
    string public tournamentDataIPFSHash;

	function MarchMadness(
        uint entryFee_,
        uint tournamentStartTime_,
        uint noContestTime_,
        uint scoringDuration_,
        uint32 maxSubmissions_,
        string tournamentDataIPFSHash_,
        address oracleAddress
    ) {
		entryFee = entryFee_;
        tournamentStartTime = tournamentStartTime_;
        scoringDuration = scoringDuration_;
        noContestTime = noContestTime_;
        maxSubmissions = maxSubmissions_;
        tournamentDataIPFSHash = tournamentDataIPFSHash_;
        resultsOracle = FederatedOracleBytes8(oracleAddress);
	}

    function submitBracket(bytes32 commitment) payable {
        if (msg.value != entryFee) {
            throw;
        }
        if (now >= tournamentStartTime) {
            throw;
        }
        if (numSubmissions >= maxSubmissions) {
            throw;
        }

        var submission = submissions[msg.sender];
        if (submission.commitment != 0) {
            throw;
        }

        submission.commitment = commitment;
        numSubmissions++;
        SubmissionAccepted(msg.sender);
    }

    function startScoring() returns (bool) {
        if (results != 0) {
            return false;
        }
        if (now < tournamentStartTime) {
            return false;
        }
        if (now > noContestTime) {
            return false;
        }

        bytes8 oracleValue = resultsOracle.finalValue();
        if (oracleValue == 0) {
            return false;
        }

        results = oracleValue;
        scoringMask = ByteBracket.getScoringMask(results);
        contestOverTime = now + scoringDuration;
        TournamentOver();
        return true;
    }

    function revealBracket(bytes8 bracket, bytes16 salt) returns (bool) {
        var submission = submissions[msg.sender];
        if (sha3(msg.sender, bracket, salt) != submission.commitment) {
            return false;
        }

        submission.bracket = bracket;
        return true;
    }

    function scoreBracket(address account) returns (bool) {
        if (results == 0) {
            return false;
        }
        if (now >= contestOverTime) {
            return false;
        }

        var submission = submissions[account];
        if (submission.bracket == 0) {
            return false;
        }
        if (submission.score != 0) {
            return false;
        }

        submission.score = ByteBracket.getBracketScore(submission.bracket, results, scoringMask);

        if (submission.score > winningScore) {
            winningScore = submission.score;
            numWinners = 0;
        }
        if (submission.score == winningScore) {
            numWinners++;
            winnings = this.balance / numWinners;
            NewWinner(account, submission.score);
        }

        return true;
    }

    function collectWinnings() returns (bool) {
        if (now < contestOverTime) {
            return false;
        }

        var submission = submissions[msg.sender];
        if (submission.score != winningScore) {
            return false;
        }
        if (submission.collectedWinnings) {
            return false;
        }

        submission.collectedWinnings = true;

        if (!msg.sender.send(winnings)) {
            throw;
        }

        return true;
    }

    function collectEntryFee() returns (bool) {
        if (now < noContestTime) {
            return false;
        }
        if (results != 0) {
            return false;
        }

        var submission = submissions[msg.sender];
        if (submission.commitment == 0) {
            return false;
        }
        if (submission.collectedEntryFee) {
            return false;
        }

        submission.collectedEntryFee = true;

        if (!msg.sender.send(entryFee)) {
            throw;
        }

        return true;
    }

    function getBracketScore(bytes8 bracket) constant returns (uint8) {
        if (results == 0) {
            throw;
        }
        return ByteBracket.getBracketScore(bracket, results, scoringMask);
    }

    function getBracket(address account) constant returns (bytes8) {
        return submissions[account].bracket;
    }

    function getScore(address account) constant returns (uint8) {
        return submissions[account].score;
    }

    function getCommitment(address account) constant returns (bytes32) {
        return submissions[account].commitment;
    }

    function hasCollectedWinnings(address account) constant returns (bool) {
        return submissions[account].collectedWinnings;
    }
}