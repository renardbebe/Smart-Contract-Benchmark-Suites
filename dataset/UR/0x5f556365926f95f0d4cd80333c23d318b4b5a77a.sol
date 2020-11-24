 

 

 

pragma solidity 0.5.13;
pragma experimental ABIEncoderV2;

contract RelayersContest {
    mapping(string => bool) public participants;
    string[] public participantsArray;
    uint256 endRegistration;
    uint256 endContest;
    address public owner;
    string[] public winners;
    bool isWinnersSet = false;
    
    event Register(string participant);
    event Winners(string[] winners);
    
    constructor(uint256 _endRegistration, uint256 _endContest) public {
        require(_endRegistration > now);
        require(_endContest >= _endRegistration + 3 days);
        endRegistration = _endRegistration;
        owner = msg.sender;
        endContest = _endContest;
    }
    
    function register(string memory _ensDomain) public {
        require(now <= endRegistration, 'registration is over');
        require(!participants[_ensDomain], 'already registred');
        participants[_ensDomain] = true;
        participantsArray.push(_ensDomain);
        emit Register(_ensDomain);
    }
    
    function setWinners(string[] memory _winners) public {
        require(msg.sender == owner);
        require(now > endContest, 'too early');
        require(!isWinnersSet);
        for(uint i = 0; i < _winners.length; i++) {
            require(participants[_winners[i]], 'not participant');
            winners.push(_winners[i]);
        }
        isWinnersSet = true;
        emit Winners(_winners);
    }
}