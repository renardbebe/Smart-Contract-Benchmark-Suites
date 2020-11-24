 

pragma solidity ^0.4.23;

contract ballotBox {
     
    mapping(address => bool) public creators;
     
    struct ballot {
        uint8 choiceCount;
        uint256 voteCountBlock;
    }
     
    ballot[] public ballots;
    
     
    event BallotCreated( string ballotProposal, uint256 indexed ballotIndex, address indexed ballotCreator, bytes32[] choices, uint256 countBlock );
     
    event Vote(uint256 indexed ballotIndex, address voter, uint8 choice);
     
    event CreatorModified(address creator, bool active, address indexed by);
    
    constructor() public {
         
        creators[msg.sender] = true;
        emit CreatorModified(msg.sender, true, msg.sender);
    }
    
    function createBallot(string _ballotQuestion, bytes32[] _choices, uint256 _countBlock) public {
         
        require(_countBlock > block.number);
         
        require(creators[msg.sender]);
         
        ballots.push(ballot(uint8(_choices.length),_countBlock));
         
        emit BallotCreated( _ballotQuestion, ballots.length-1 , msg.sender, _choices, _countBlock);
    }
    
    function vote(uint256 _ballotIndex, uint8 _choice) public {
         
        require(ballots[_ballotIndex].voteCountBlock > block.number);
         
        require(_choice < ballots[_ballotIndex].choiceCount);
         
        emit Vote(_ballotIndex, msg.sender, _choice);
    }
    
    function modifyCreator(address _creator, bool _active) public {
         
        require(creators[msg.sender]);
         
        if(_active == false) require(_creator == msg.sender);
         
        creators[_creator] = _active;
         
        emit CreatorModified(_creator, _active, msg.sender); 
    }
}