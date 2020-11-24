 

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

     
    address[NUMBER_OF_CHOICES] internal whitelistedSenderAdresses;

     
    uint40 public voteCountTotal;

     
    uint32[NUMBER_OF_CHOICES] internal currentVoteResults;

     
    event NewVote(uint8 indexed addedVote, uint32[NUMBER_OF_CHOICES] allVotes);

     
    event WhitelistUpdated(address[NUMBER_OF_CHOICES] whitelistedSenderAdresses);

     
    event DemoResetted();

     
    function()
    public {
        require(false, "Fallback function always throws.");
    }

     
    function setWhiteList(address[NUMBER_OF_CHOICES] whitelistedSenders)
    external
    onlyOwner {
         
         
        whitelistedSenderAdresses = whitelistedSenders;
        emit WhitelistUpdated(whitelistedSenders);
    }

     
    function resetDemo()
    external
    onlyOwner {
        voteCountTotal = 0;
        currentVoteResults[0] = 0;
        currentVoteResults[1] = 0;
        currentVoteResults[2] = 0;
        currentVoteResults[3] = 0;
        emit DemoResetted();
    }

     
    function castVote()
    external {
        uint8 choice;
        if (msg.sender == whitelistedSenderAdresses[0]) {
            choice = 0;
        } else if (msg.sender == whitelistedSenderAdresses[1]) {
            choice = 1;
        } else if (msg.sender == whitelistedSenderAdresses[2]) {
            choice = 2;
        } else if (msg.sender == whitelistedSenderAdresses[3]) {
            choice = 3;
        } else {
            require(false, "Only whitelisted sender addresses can cast votes.");
        }

         
        voteCountTotal = safeAdd40(voteCountTotal, 1);
        currentVoteResults[choice] = safeAdd32(currentVoteResults[choice], 1);

         
         
         
        emit NewVote(choice, currentVoteResults);
    }

     
    function currentResult()
    external
    view
    returns (uint32[NUMBER_OF_CHOICES]) {
        return currentVoteResults;
    }

     
    function whitelistedSenderAddresses()
    external
    view
    returns (address[NUMBER_OF_CHOICES]) {
        return whitelistedSenderAdresses;
    }

     
    function votesPerChoice(uint8 option)
    external
    view
    returns (uint32) {
        require(option < NUMBER_OF_CHOICES, "Choice must be less than numberOfChoices.");
        return currentVoteResults[option];
    }

     
    function numberOfPossibleChoices()
    public
    pure
    returns (uint8) {
        return NUMBER_OF_CHOICES;
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