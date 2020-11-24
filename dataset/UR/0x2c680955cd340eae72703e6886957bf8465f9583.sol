 

pragma solidity 0.4.24;

 



 

 
contract Ownable {

    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor()
    public {
        _owner = msg.sender;
    }

     
    function owner()
    public
    view
    returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Only the owner can do this.");
        _;
    }

     
    function isOwner()
    public
    view
    returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership()
    public
    onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner)
    public
    onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner)
    internal {
        require(newOwner != address(0), "New owner cannot be 0x0.");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 
contract Destructible is Ownable {

     
    function destroy()
    public
    onlyOwner {
        selfdestruct(owner());
    }

     
    function destroyAndSend(address _recipient)
    public
    onlyOwner {
        selfdestruct(_recipient);
    }
}

 

 
interface IERC20 {

    function transfer(address to, uint256 value)
    external
    returns (bool);

    function balanceOf(address who)
    external
    view
    returns (uint256);

    function totalSupply()
    external
    view
    returns (uint256);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

}

 

 
contract CanRescueERC20 is Ownable {

     
    function recoverTokens(IERC20 token)
    public
    onlyOwner {
        uint256 balance = token.balanceOf(this);
         
         
         
        require(token.transfer(owner(), balance), "Token transfer failed, transfer() returned false.");
    }

}

 

contract Voting is Ownable, Destructible, CanRescueERC20 {

     
    uint8 internal constant NUMBER_OF_CHOICES = 4;

     
    uint40 public voteCountTotal;

     
    uint32[NUMBER_OF_CHOICES] internal currentVoteResults;

     
    mapping(address => Voter) public votersInfo;

     
    event NewVote(uint8 indexed addedVote, uint32[NUMBER_OF_CHOICES] allVotes);

     
    struct Voter {
        bool exists;
        uint8 choice;
        string name;
    }

     
    function()
    public {
    }

     
    function castVote(string voterName, uint8 givenVote)
    external {
         
        require(givenVote < numberOfChoices(), "Choice must be less than contract configured numberOfChoices.");

         
         
         

         
         
        require(bytes(voterName).length > 2, "Name of voter is too short.");

         
        votersInfo[msg.sender] = Voter(true, givenVote, voterName);
        voteCountTotal = safeAdd40(voteCountTotal, 1);
        currentVoteResults[givenVote] = safeAdd32(currentVoteResults[givenVote], 1);

         
         
         
        emit NewVote(givenVote, currentVoteResults);
    }

     
    function thisVoterExists()
    external
    view
    returns (bool) {
        return votersInfo[msg.sender].exists;
    }

     
    function thisVotersChoice()
    external
    view
    returns (uint8) {
         
        require(votersInfo[msg.sender].exists, "No vote so far.");
        return votersInfo[msg.sender].choice;
    }

     
    function thisVotersName()
    external
    view
    returns (string) {
         
        require(votersInfo[msg.sender].exists, "No vote so far.");
        return votersInfo[msg.sender].name;
    }

     
    function currentResult()
    external
    view
    returns (uint32[NUMBER_OF_CHOICES]) {
        return currentVoteResults;
    }

     
    function votesPerChoice(uint8 option)
    external
    view
    returns (uint32) {
        require(option < numberOfChoices(), "Choice must be less than contract configured numberOfChoices.");
        return currentVoteResults[option];
    }

     
    function numberOfChoices()
    public
    view
    returns (uint8) {
         
         
        return uint8(currentVoteResults.length);
    }

     
    function safeAdd40(uint40 _a, uint40 _b)
    internal
    pure
    returns (uint40 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }

     
    function safeAdd32(uint32 _a, uint32 _b)
    internal
    pure
    returns (uint32 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}