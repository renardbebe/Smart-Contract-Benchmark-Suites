 

pragma solidity 0.4.21;

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract CoinsKarmaFactory is Ownable {

    event NewCoinsKarma(uint coinsKarmaId, string name, string symbol, uint totalKarmaUp, uint totalKarmaDown, bool exists);
    event NewKarmaVoter(uint karmaVoteId, uint coinsKarmaId, address voterAddress, uint up, uint down, uint voteTime, bool exists);

    struct CoinsKarma {
        string name;
        string symbol;
        uint totalKarmaUp;
        uint totalKarmaDown;
        bool exists;
    }

    struct KarmaVotes {
        uint coinsKarmaId;
        address voterAddress;
        uint up;
        uint down;
        uint voteTime;
        bool exists;
    }

    CoinsKarma[] public coinkarma;
    mapping(string => uint) coinsKarmaCreated;
    mapping(string => uint) coinsKarmaMap;

    KarmaVotes[] public karmavoters;
    mapping(address => mapping(uint => uint)) karmaVoterCreated;
    mapping(address => mapping(uint => uint)) karmaVoterMap;

    uint giveKarmaFee = 1800000000000000;  

     
     

    function viewCoinsKarma(uint _coinsKarmaId) view public returns (uint, string, string, uint, uint, bool) {
        CoinsKarma storage coinskarma = coinkarma[_coinsKarmaId];
        return (_coinsKarmaId, coinskarma.name, coinskarma.symbol, coinskarma.totalKarmaUp, coinskarma.totalKarmaDown, coinskarma.exists);
    }

    function viewCoinsKarmaBySymbol(string _coinSymbol) view public returns (uint, string, string, uint, uint, bool) {
        CoinsKarma storage coinskarma = coinkarma[coinsKarmaMap[_coinSymbol]];
        if (coinskarma.exists == true) {
            return (coinsKarmaMap[_coinSymbol], coinskarma.name, coinskarma.symbol, coinskarma.totalKarmaUp, coinskarma.totalKarmaDown, coinskarma.exists);
        } else {
            return (0, "", "", 0, 0, false);
        }
    }

    function viewKarmaVotes(uint _karmaVoteId) view public returns (uint, uint, address, uint, uint, uint, bool) {
        KarmaVotes storage karmavotes = karmavoters[_karmaVoteId];
        return (_karmaVoteId, karmavotes.coinsKarmaId, karmavotes.voterAddress, karmavotes.up, karmavotes.down, karmavotes.voteTime, karmavotes.exists);
    }

    function viewKarmaVotesBySymbol(string _coinSymbol, address _userAddress) view public returns (uint, address, uint, uint, uint, string) {
        uint getCoinsId = coinsKarmaMap[_coinSymbol];
        if (karmavoters[karmaVoterMap[_userAddress][getCoinsId]].exists == true) {
            return (karmavoters[karmaVoterMap[_userAddress][getCoinsId]].coinsKarmaId, karmavoters[karmaVoterMap[_userAddress][getCoinsId]].voterAddress, karmavoters[karmaVoterMap[_userAddress][getCoinsId]].up, karmavoters[karmaVoterMap[_userAddress][getCoinsId]].down, karmavoters[karmaVoterMap[_userAddress][getCoinsId]].voteTime, _coinSymbol);
        } else {
            return (0, 0x0, 0, 0, 0, "");
        }
    }

    function giveKarma(uint _upOrDown, string _coinName, string _coinSymbol) payable public {
        require(msg.value >= giveKarmaFee);

        uint upVote = 0;
        uint downVote = 0;
        if(_upOrDown == 1){
            downVote = 1;
        } else if (_upOrDown == 2){
            upVote = 1;
        }

        uint id;

         
        if (coinsKarmaCreated[_coinSymbol] == 0) {
             
            id = coinkarma.push(CoinsKarma(_coinName, _coinSymbol, 0, 0, true)) - 1;
            emit NewCoinsKarma(id, _coinName, _coinSymbol, 0, 0, true);

            coinsKarmaMap[_coinSymbol] = id;
            coinsKarmaCreated[_coinSymbol] = 1;

        } else {
            id = coinsKarmaMap[_coinSymbol];

        }

         
        if (karmaVoterCreated[msg.sender][id] == 0) {
             
            uint idd = karmavoters.push(KarmaVotes(id, msg.sender, upVote, downVote, now, true)) - 1;
            emit NewKarmaVoter(idd, id, msg.sender, upVote, downVote, now, true);

            karmaVoterCreated[msg.sender][id] = 1;
            karmaVoterMap[msg.sender][id] = idd;

            coinkarma[coinsKarmaMap[_coinSymbol]].totalKarmaUp = coinkarma[coinsKarmaMap[_coinSymbol]].totalKarmaUp + upVote;
            coinkarma[coinsKarmaMap[_coinSymbol]].totalKarmaDown = coinkarma[coinsKarmaMap[_coinSymbol]].totalKarmaDown + downVote;

        }else{
             
            if (karmavoters[karmaVoterMap[msg.sender][id]].up > 0){
                coinkarma[coinsKarmaMap[_coinSymbol]].totalKarmaUp = coinkarma[coinsKarmaMap[_coinSymbol]].totalKarmaUp - 1;
            } else if(karmavoters[karmaVoterMap[msg.sender][id]].down > 0) { 
                coinkarma[coinsKarmaMap[_coinSymbol]].totalKarmaDown = coinkarma[coinsKarmaMap[_coinSymbol]].totalKarmaDown - 1;
            }
            
            karmavoters[karmaVoterMap[msg.sender][id]].up = upVote;
            karmavoters[karmaVoterMap[msg.sender][id]].down = downVote;
            karmavoters[karmaVoterMap[msg.sender][id]].voteTime = now;

            coinkarma[coinsKarmaMap[_coinSymbol]].totalKarmaUp = coinkarma[coinsKarmaMap[_coinSymbol]].totalKarmaUp + upVote;
            coinkarma[coinsKarmaMap[_coinSymbol]].totalKarmaDown = coinkarma[coinsKarmaMap[_coinSymbol]].totalKarmaDown + downVote;

        }

    }

     
     

    function viewGiveKarmaFee() public view returns(uint) {
        return giveKarmaFee;
    }

    function alterGiveKarmaFee (uint _giveKarmaFee) public onlyOwner() {
        giveKarmaFee = _giveKarmaFee;
    }

    function withdrawFromContract(address _to, uint _amount) payable external onlyOwner() {
        _to.transfer(_amount);

    }

}