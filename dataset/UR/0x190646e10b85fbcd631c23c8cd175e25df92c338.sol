 

 
 
 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract EthBattle is Ownable {
    using SafeMath for uint256;

    uint256 constant TOKEN_USE_BONUS = 15;  
    uint256 constant REFERRAL_REWARD = 2 ether;  
    uint256 constant MIN_PLAY_AMOUNT = 50 finney;  

    uint256 public roundIndex = 0;
    mapping(uint256 => address) public rounds;

    address[] private currentRewardingAddresses;

    PlaySeedInterface private playSeedGenerator;
    GTAInterface public token;
    AMUStoreInterface public store;

    mapping(address => address) public referralBacklog;  

    mapping(address => uint256) public tokens;  

    event RoundCreated(address createdAddress, uint256 index);
    event Deposit(address user, uint amount, uint balance);
    event Withdraw(address user, uint amount, uint balance);

     
    function () public payable {
        getLastRound().getDevWallet().transfer(msg.value);
    }

     
    constructor (address _playSeedAddress, address _tokenAddress, address _storeAddress) public {
        playSeedGenerator = PlaySeedInterface(_playSeedAddress);
        token = GTAInterface(_tokenAddress);
        store = AMUStoreInterface(_storeAddress);
    }

     
    function claimSeedOwnership() onlyOwner public {
        playSeedGenerator.claimOwnership();
    }

     
    function startRound(address _roundAddress) onlyOwner public {
        RoundInterface round = RoundInterface(_roundAddress);

        round.claimOwnership();

        roundIndex++;
        rounds[roundIndex] = round;
        emit RoundCreated(round, roundIndex);
    }


     
    function interruptLastRound() onlyOwner public {
        getLastRound().enableRefunds();
    }

     
    function finishLastRound() onlyOwner public {
        getLastRound().coolDown();
    }

    function getLastRound() public view returns (RoundInterface){
        return RoundInterface(rounds[roundIndex]);
    }

    function getLastRoundAddress() external view returns (address){
        return rounds[roundIndex];
    }

     
    function play(address _referral, uint256 _gtaBet) public payable {
        address player = msg.sender;
        uint256 weiAmount = msg.value;

        require(player != address(0), "Player's address is missing");
        require(weiAmount >= MIN_PLAY_AMOUNT, "The bet is too low");
        require(_gtaBet <= balanceOf(player), "Player's got not enough GTA");

        if (_referral != address(0) && referralBacklog[player] == address(0)) {
             
            referralBacklog[player] = _referral;
             
             
            transferInternally(owner, _referral, REFERRAL_REWARD);
        }

        playSeedGenerator.newPlaySeed(player);

        uint256 _bet = aggregateBet(weiAmount, _gtaBet);

        if (_gtaBet > 0) {
             
            transferInternally(player, owner, _gtaBet);
        }

        if (referralBacklog[player] != address(0)) {
             
             
            getLastRound().setReferral(player, referralBacklog[player]);
        }
        getLastRound().playRound.value(msg.value)(player, _bet);
    }

     
    function win(bytes32 _seed) public {
        address player = msg.sender;

        require(player != address(0), "Winner's address is missing");
        require(playSeedGenerator.findSeed(player) == _seed, "Wrong seed!");
        playSeedGenerator.cleanSeedUp(player);

        getLastRound().win(player);
    }

    function findSeedAuthorized(address player) onlyOwner public view returns (bytes32){
        return playSeedGenerator.findSeed(player);
    }

    function aggregateBet(uint256 _bet, uint256 _gtaBet) internal view returns (uint256) {
         
         
        uint256 _gtaValueWei = store.getTokenBuyPrice().mul(_gtaBet).div(1 ether).mul(100 + TOKEN_USE_BONUS).div(100);

         
        uint256 _resultBet = _bet.add(_gtaValueWei);

        return _resultBet;
    }

     
    function prizeByNow() public view returns (uint256) {
        return getLastRound().currentPrize(msg.sender);
    }

     
    function prizeProjection(uint256 _bet, uint256 _gtaBet) public view returns (uint256) {
        return getLastRound().projectedPrizeForPlayer(msg.sender, aggregateBet(_bet, _gtaBet));
    }


     
    function depositGTA(uint256 _amount) public {
        require(token.transferFrom(msg.sender, this, _amount), "Insufficient funds");
        tokens[msg.sender] = tokens[msg.sender].add(_amount);
        emit Deposit(msg.sender, _amount, tokens[msg.sender]);
    }

     
    function withdrawGTA(uint256 _amount) public {
        require(tokens[msg.sender] >= _amount, "Amount exceeds the available balance");
        tokens[msg.sender] = tokens[msg.sender].sub(_amount);
        require(token.transfer(msg.sender, _amount), "Amount exceeds the available balance");
        emit Withdraw(msg.sender, _amount, tokens[msg.sender]);
    }

     
    function transferInternally(address _from, address _to, uint256 _amount) internal {
        require(tokens[_from] >= _amount, "Too much to transfer");
        tokens[_from] = tokens[_from].sub(_amount);
        tokens[_to] = tokens[_to].add(_amount);
    }

    function balanceOf(address _user) public view returns (uint256) {
        return tokens[_user];
    }

    function setPlaySeed(address _playSeedAddress) onlyOwner public {
        playSeedGenerator = PlaySeedInterface(_playSeedAddress);
    }

    function setStore(address _storeAddress) onlyOwner public {
        store = AMUStoreInterface(_storeAddress);
    }

    function getTokenBuyPrice() public view returns (uint256) {
        return store.getTokenBuyPrice();
    }

    function getTokenSellPrice() public view returns (uint256) {
        return store.getTokenSellPrice();
    }

     
    function setReferralsMap(address[] _players, address[] _referrals) onlyOwner public {
        require(_players.length == _referrals.length, "Size of players must be equal to the size of referrals");
        for (uint i = 0; i < _players.length; ++i) {
            referralBacklog[_players[i]] = _referrals[i];
        }
    }

}

 
interface PlaySeedInterface {

    function newPlaySeed(address _player) external;

    function findSeed(address _player) external view returns (bytes32);

    function cleanSeedUp(address _player) external;

    function claimOwnership() external;

}

 
interface GTAInterface {

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

}

 
interface RoundInterface {

    function claimOwnership() external;

    function setReferral(address _player, address _referral) external;

    function playRound(address _player, uint256 _bet) external payable;

    function enableRefunds() external;

    function coolDown() external;

    function currentPrize(address _player) external view returns (uint256);

    function projectedPrizeForPlayer(address _player, uint256 _bet) external view returns (uint256);

    function win(address _player) external;

    function getDevWallet() external view returns (address);

}

 
interface AMUStoreInterface {

    function getTokenBuyPrice() external view returns (uint256);

    function getTokenSellPrice() external view returns (uint256);

}