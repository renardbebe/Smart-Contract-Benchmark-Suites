 

pragma solidity 0.4.25;


interface IOrbsVoting {

    event VoteOut(address indexed voter, address[] validators, uint voteCounter);
    event Delegate(
        address indexed delegator,
        address indexed to,
        uint delegationCounter
    );
    event Undelegate(address indexed delegator, uint delegationCounter);

     
     
    function voteOut(address[] validators) external;

     
     
    function delegate(address to) external;

     
    function undelegate() external;

     
     
    function getCurrentVote(address guardian)
        external
        view
        returns (address[] validators, uint blockNumber);

     
     
    function getCurrentVoteBytes20(address guardian)
        external
        view
        returns (bytes20[] validatorsBytes20, uint blockNumber);

     
     
    function getCurrentDelegation(address delegator)
        external
        view
        returns (address);
}


contract OrbsVoting is IOrbsVoting {

     
     
    struct VotingRecord {
        uint blockNumber;
        address[] validators;
    }

     
    uint public constant VERSION = 1;

     
     
    uint internal voteCounter;
    uint internal delegationCounter;

     
    uint public maxVoteOutCount;

     
    mapping(address => VotingRecord) internal votes;
    mapping(address => address) internal delegations;

     
    constructor(uint maxVoteOutCount_) public {
        require(maxVoteOutCount_ > 0, "maxVoteOutCount_ must be positive");
        maxVoteOutCount = maxVoteOutCount_;
    }

     
     
    function voteOut(address[] validators) external {
        address sender = msg.sender;
        require(validators.length <= maxVoteOutCount, "Validators list is over the allowed length");
        sanitizeValidators(validators);

        voteCounter++;

        votes[sender] = VotingRecord({
            blockNumber: block.number,
            validators: validators
        });

        emit VoteOut(sender, validators, voteCounter);
    }

     
     
    function delegate(address to) external {
        address sender = msg.sender;
        require(to != address(0), "must delegate to non 0");
        require(sender != to , "cant delegate to yourself");

        delegationCounter++;

        delegations[sender] = to;

        emit Delegate(sender, to, delegationCounter);
    }

     
    function undelegate() external {
        address sender = msg.sender;
        delegationCounter++;

        delete delegations[sender];

        emit Delegate(sender, sender, delegationCounter);
        emit Undelegate(sender, delegationCounter);
    }

     
     
    function getCurrentVoteBytes20(address guardian)
        public
        view
        returns (bytes20[] memory validatorsBytes20, uint blockNumber)
    {
        address[] memory validatorAddresses;
        (validatorAddresses, blockNumber) = getCurrentVote(guardian);

        uint validatorAddressesLength = validatorAddresses.length;

        validatorsBytes20 = new bytes20[](validatorAddressesLength);

        for (uint i = 0; i < validatorAddressesLength; i++) {
            validatorsBytes20[i] = bytes20(validatorAddresses[i]);
        }
    }

     
     
    function getCurrentDelegation(address delegator)
        public
        view
        returns (address)
    {
        return delegations[delegator];
    }

     
     
    function getCurrentVote(address guardian)
        public
        view
        returns (address[] memory validators, uint blockNumber)
    {
        VotingRecord storage lastVote = votes[guardian];

        blockNumber = lastVote.blockNumber;
        validators = lastVote.validators;
    }

     
     
    function sanitizeValidators(address[] validators)
        private
        pure
    {
        uint validatorsLength = validators.length;
        for (uint i = 0; i < validatorsLength; i++) {
            require(validators[i] != address(0), "All validator addresses must be non 0");
            for (uint j = i + 1; j < validatorsLength; j++) {
                require(validators[j] != validators[i], "Duplicate Validators");
            }
        }
    }
}