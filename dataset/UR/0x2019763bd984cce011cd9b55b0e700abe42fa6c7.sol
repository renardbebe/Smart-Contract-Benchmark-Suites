 

pragma solidity ^0.4.19;
 
 

contract ClassSize {
    event VoteYes(string note);
    event VoteNo(string note);

    string constant proposalText = "Should the class size increase from 35 to 45?";
    uint16 public votesYes = 0;
    uint16 public votesNo = 0;
    function isYesWinning() public view returns(uint8) {
        if (votesYes >= votesNo) {
            return 0;  
        } else  {
            return 1;  
        }
    }
    function voteYes(string note) public {
        votesYes += 1;
        VoteYes(note);
    }
    function voteNo(string note) public {
        votesNo += 1;
        VoteNo(note);
    }
}

contract A {
    ClassSize cz = ClassSize(0x6faf33c051c0703ad2a6e86b373bb92bb30c8f5c);
    string[] rik = ["never gonna", "give you", "up, never gonna", "let you down", "never gonna run", "around and desert", "youuuuuu"];
    function whee(uint256 whee2) {
        for (uint i = 0; i < whee2; i++) {
            cz.voteYes(rik[i % 7]);
        }
    }
}