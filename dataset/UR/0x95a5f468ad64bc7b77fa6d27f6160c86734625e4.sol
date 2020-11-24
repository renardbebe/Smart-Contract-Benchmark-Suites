 

 
 
 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
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

contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

   
  constructor(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

   
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

   
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

contract RoundVault is RefundVault {

    uint256 constant DEV_FUND_COMMISSION = 4;  

    uint256 public totalRoundPrize;
    uint256 public finalCumulativeWeight;

    StartersProxyInterface public startersProxy;

    event RewardWinner(address player, uint256 weiAmount, uint256 kPercent);

    constructor(address _devFundWallet, address _proxyAddress) RefundVault(_devFundWallet) public {
        startersProxy = StartersProxyInterface(_proxyAddress);
    }

     
    function reward(address _winner, uint256 _personalWeight) onlyOwner public {
         
        uint256 _portion = _personalWeight.mul(100000000).div(finalCumulativeWeight);

         
        uint256 _prizeWei = totalRoundPrize.mul(_portion).div(100000000);

        require(address(this).balance > _prizeWei, "Vault run out of funds!");

        if (isContract(_winner)) {
             
             
        } else {
             
            uint256 _personalDept = startersProxy.debt(_winner);
            if (_personalDept > 0) {
                uint256 _toRepay = _personalDept;
                if (_prizeWei < _personalDept) {
                     
                    _toRepay = _prizeWei;
                }
                startersProxy.payDebt.value(_toRepay)(_winner);
                 
                if (_prizeWei.sub(_toRepay) > 0) {
                    _winner.transfer(_prizeWei.sub(_toRepay));
                }
            } else {
                _winner.transfer(_prizeWei);
            }
        }

        emit RewardWinner(_winner, _prizeWei, _portion);
    }

    function isContract(address _address) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_address) }
        return size > 0;
    }

    function personalPrizeByNow(uint256 _personalWeight, uint256 _roundCumulativeWeigh) onlyOwner public view returns (uint256){
        if (_roundCumulativeWeigh == 0) {
             
            return 0;
        }
         
        uint256 _portion = _personalWeight.mul(100000000).div(_roundCumulativeWeigh);
         
        return totalPrizePot().mul(_portion).div(100000000);
    }

    function personalPrizeWithBet(uint256 _personalWeight, uint256 _roundCumulativeWeight, uint256 _bet) onlyOwner public view returns (uint256){
        if (_roundCumulativeWeight == 0) {
             
            _roundCumulativeWeight = _personalWeight;
        } else {
             
            _roundCumulativeWeight = _roundCumulativeWeight.add(_personalWeight);
        }
        uint256 _portion = _personalWeight.mul(100).div(_roundCumulativeWeight);

         
        uint256 _assumingPersonalAdditionToPot = _bet.mul(100 - DEV_FUND_COMMISSION).div(100);
        uint256 _assumingPrizePot = totalPrizePot().add(_assumingPersonalAdditionToPot);

        return _assumingPrizePot.mul(_portion).div(100);
    }

    function totalPrizePot() internal view returns (uint256) {
        return address(this).balance.mul(100 - DEV_FUND_COMMISSION).div(100);
    }

    function sumUp(uint256 _weight) onlyOwner public {
        finalCumulativeWeight = _weight;
        totalRoundPrize = totalPrizePot();
    }

    function terminate() onlyOwner public {
        state = State.Active;
        super.close();
    }

    function getWallet() public view returns (address) {
        return wallet;
    }

    function getDevFundAddress() public view returns (address){
        return wallet;
    }
}

interface StartersProxyInterface {

    function debt(address signer) external view returns (uint256);

    function payDebt(address signer) external payable;
}

contract Whitelist is Ownable, RBAC {
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyWhitelisted() {
    checkRole(msg.sender, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address addr)
    onlyOwner
    public
  {
    addRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressAdded(addr);
  }

   
  function whitelist(address addr)
    public
    view
    returns (bool)
  {
    return hasRole(addr, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      addAddressToWhitelist(addrs[i]);
    }
  }

   
  function removeAddressFromWhitelist(address addr)
    onlyOwner
    public
  {
    removeRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressRemoved(addr);
  }

   
  function removeAddressesFromWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      removeAddressFromWhitelist(addrs[i]);
    }
  }

}

contract EthBattleRound is Whitelist, Claimable {
    using SafeMath for uint256;

    uint256 public constant SMART_ASS_COEFFICIENT = 5;  
    uint256 public constant REFERRAL_BONUS = 1;  

     
     
    RoundVault public vault;

    event Play(address player, uint256 bet, address referral, address round);
    event Win(address player, address round);
    event Reward(uint256 counter, address winner);
    event Finalize(uint256 count);
    event CoolDown(uint256 winCount);

     
     
     
     
    enum State {Active, CoolingDown, Rewarding, Closed}
    State private state;

    uint256 public roundCumulativeWeight;
    uint256 public winCount;    
    uint256 public winnerCount;  
    uint256 public rewardCount;

    uint256 public roundSwapLimit = 200;  

     
    mapping(address => uint256) public winnersBacklog;

     
    mapping(address => address) public referralBacklog;
     
    mapping(address => uint256) public lastBetWei;
     
    mapping(address => uint256) public playerWinWeight;
     
    mapping(address => bool) public rewardedWinners;


     
    function () public payable {
        vault.getWallet().transfer(msg.value);
    }

     
    constructor (address _devFundWallet, address _battleAddress, address[] _rewardingAddrs, address _proxyAddress) public {
        vault = new RoundVault(_devFundWallet, _proxyAddress);

        addAddressToWhitelist(_battleAddress);

        addAddressesToWhitelist(_rewardingAddrs);

        state = State.Active;
    }

    function isActive() public view returns (bool){
        return state == State.Active;
    }

     
    function enableRefunds() onlyOwner public {
        require(isActive() || isCoolingDown(), "Round must be active");
        vault.enableRefunds();
    }

     
    function terminate() external onlyWhitelisted {
         
        vault.terminate();
        state = State.Closed;
    }

     
    function claimRefund() public {
        vault.refund(msg.sender);
    }


    function coolDown() onlyOwner public {
        require(isActive() || isCoolingDown(), "Round must be active");
        state = State.CoolingDown;
        emit CoolDown(winCount);
    }

    function isCoolingDown() public view returns (bool){
        return state == State.CoolingDown;
    }

    function startRewarding() external onlyWhitelisted {
        require(isCoolingDown(), "Cool it down first");
        vault.sumUp(roundCumulativeWeight);

        state = State.Rewarding;
    }

    function isRewarding() public view returns (bool){
        return state == State.Rewarding;
    }

    function playRound(address _player, uint256 _bet) onlyOwner public payable {
        require(isActive(), "Not active anymore");

        lastBetWei[_player] = _bet;

        uint256 _thisBet = msg.value;
        if (referralBacklog[_player] != address(0)) {
             
            uint256 _referralReward = _thisBet.mul(REFERRAL_BONUS).div(100);
            if (isContract(referralBacklog[_player])) {
                 
                 
                vault.getDevFundAddress().transfer(_referralReward);
            } else {
                referralBacklog[_player].transfer(_referralReward);
            }
            _thisBet = _thisBet.sub(_referralReward);
        }

        vault.deposit.value(_thisBet)(_player);

        emit Play(_player, _thisBet, referralBacklog[_player], address(this));

    }

    function win(address _player) onlyOwner public {
        require(isActive() || isCoolingDown(), "Round must be active or cooling down");

        require(lastBetWei[_player] > 0, "Hmm, did this player call 'play' before?");

        uint256 _thisWinWeight = applySmartAssCorrection(_player, lastBetWei[_player]);

        recordWinFact(_player, _thisWinWeight);
    }

     
    function currentPrize(address _player) onlyOwner public view returns (uint256) {
         
        return vault.personalPrizeByNow(playerWinWeight[_player], roundCumulativeWeight);
    }

     
    function projectedPrizeForPlayer(address _player, uint256 _bet) onlyOwner public view returns (uint256) {
        uint256 _projectedPersonalWeight = applySmartAssCorrection(_player, _bet);
         
        return vault.personalPrizeWithBet(_projectedPersonalWeight, roundCumulativeWeight, _bet);
    }

    function recordWinFact(address _player, uint256 _winWeight) internal {
        if (playerWinWeight[_player] == 0) {
             
            winnerCount++;
        }
        winCount++;
        playerWinWeight[_player] = playerWinWeight[_player].add(_winWeight);
        roundCumulativeWeight = roundCumulativeWeight.add(_winWeight);

        winnersBacklog[_player] = winnersBacklog[_player].add(1);
        if (winCount == roundSwapLimit) {
             
            coolDown();
        }
        emit Win(_player, address(this));
    }

    function applySmartAssCorrection(address _player, uint256 _bet) internal view returns (uint256){
        if (winnersBacklog[_player] > 0) {
             
            uint256 _personalWinCount = winnersBacklog[_player];
            if (_personalWinCount > 10) {
                 
                _personalWinCount = 10;
            }
            _bet = _bet.mul(100 - _personalWinCount.mul(SMART_ASS_COEFFICIENT)).div(100);
        }
        return _bet;
    }

    function rewardWinner(address _winner) external onlyWhitelisted {
        require(state == State.Rewarding, "Round in not in 'Rewarding' state yet");
        require(playerWinWeight[_winner] > 0, "This player hasn't actually won anything");
        require(!rewardedWinners[_winner], "This player has been rewarded already");

        vault.reward(_winner, playerWinWeight[_winner]);

        rewardedWinners[_winner] = true;
        rewardCount++;
        emit Reward(rewardCount, _winner);
    }

    function setReferral(address _player, address _referral) onlyOwner public {
        if (referralBacklog[_player] == address(0)) {
            referralBacklog[_player] = _referral;
        }
    }

    function finalizeRound() external onlyWhitelisted {
        require(state == State.Rewarding, "The round must be in 'Rewarding' state");
        isAllWinnersRewarded();

         
        vault.close();

        state = State.Closed;
        emit Finalize(rewardCount);
    }

    function isContract(address _address) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_address) }
        return size > 0;
    }

    function isClosed() public view returns (bool){
        return state == State.Closed;
    }

    function isAllWinnersRewarded() public view returns (bool){
        return winnerCount == rewardCount;
    }

    function getVault() public view returns (RoundVault) {
        return vault;
    }

    function getDevWallet() public view returns (address) {
        return vault.getWallet();
    }

    function setRoundSwapLimit(uint256 _newLimit) external onlyWhitelisted {
        roundSwapLimit = _newLimit;
    }


}