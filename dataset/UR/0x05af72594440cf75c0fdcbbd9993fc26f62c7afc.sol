 

pragma solidity ^0.4.25;

 
 
 
 
 
 
 
 

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
interface TwelveHourTokenInterface {
     function fallback() external payable; 
     function buy(address _referredBy) external payable returns (uint256);
     function exit() external;
}

contract TwelveHourAuction {

    bool init = false;
    using SafeMath for uint256;
    
    address owner;
    uint256 public round     = 0;
    uint256 public nextPot   = 0;
    uint256 public profitTHT = 0;
     
    uint256 constant private THT_TOKEN_OWNERS     = 10;
    uint256 constant private KEY_HOLDERS_DIVIDEND = 30;
    uint256 constant private REFERRAL             = 10;
    uint256 constant private FINAL_POT            = 30;
     
    uint256 constant private MARKETING            = 5;

    uint256 constant private MAGINITUDE           = 2 ** 64;
    uint256 constant private HALF_TIME            = 12 hours;
    uint256 constant private KEY_PRICE_DEFAULT    = 0.005 ether;
    uint256 constant private VERIFY_REFERRAL_PRICE= 0.01 ether;
     
    address public twelveHourTokenAddress;
    TwelveHourTokenInterface public TwelveHourToken; 

     
    mapping(uint256 => Game) public games;
     
    mapping(address => Player) public players;

    mapping(address => bool) public referrals;

    address[10] public teamMarketing;

    struct Game {
        uint256 round;
        uint256 finalPot;
        uint256 profitPerShare;
        address keyHolder;
        uint256 keyLevel;
        uint256 endTime;
        bool ended; 
    }
     
    struct Player {
      uint256 curentRound;
      uint256 lastRound;
      uint256 bonus;
      uint256 keys;  
      uint256 dividends;
      uint256 referrals;
      int256 payouts;
    }
    event Buy(uint256 round, address buyer, uint256 amount, uint256 keyLevel);
    event EndRound(uint256 round, uint256 finalPot, address keyHolder, uint256 keyLevel, uint256 endTime);
    event Withdraw(address player, uint256 amount);
    event WithdrawReferral(address player, uint256 amount);
    modifier onlyOwner() 
    {
      require(msg.sender == owner);
      _;
    }
    modifier disableContract()
    {
      require(tx.origin == msg.sender);
      _;
    }
    constructor() public 
    {
      owner = msg.sender;
       
      for (uint256 idx = 0; idx < 10; idx++) {
        teamMarketing[idx] = owner;
      }
    }
    function () public payable
    {
        if (msg.sender != twelveHourTokenAddress) buy(0x0);
    }
     
    function setTwelveHourToken(address _addr) public onlyOwner
    {
      twelveHourTokenAddress = _addr;
      TwelveHourToken = TwelveHourTokenInterface(twelveHourTokenAddress);  
    }
    function setTeamMaketing(address _addr, uint256 _idx) public onlyOwner
    {
      teamMarketing[_idx] = _addr;
    }
    function verifyReferrals() public payable disableContract
    {
      require(msg.value >= VERIFY_REFERRAL_PRICE);
      referrals[msg.sender] = true;
      owner.transfer(msg.value);
    }
     
     
     
    function startGame() public onlyOwner
    {
      require(init == false);
      init = true;
      games[round].ended = true;
      startRound();
    }
    function startRound() private
    {
      require(games[round].ended == true);
       
      round = round + 1;
      uint256 endTime = now + HALF_TIME;
 
      games[round] = Game(round, nextPot, 0, 0x0, 1, endTime, false);
      nextPot = 0;
    }
    function endRound() private disableContract
    {
      require(games[round].ended == false && games[round].endTime <= now);

      Game storage g = games[round];
      address keyHolder = g.keyHolder;
      g.ended = true;
      players[keyHolder].bonus += g.finalPot;
      startRound();

       

      emit EndRound(g.round, g.finalPot, g.keyHolder, g.keyLevel, g.endTime);
    }
     
     
     
    function buy(address _referral) public payable disableContract
    {
      require(init == true);
      require(games[round].ended == false);
      require(msg.sender != _referral);

      if (games[round].endTime <= now) endRound();
      Game storage g   = games[round];

      uint256 keyPrice       = SafeMath.mul(g.keyLevel, KEY_PRICE_DEFAULT);
      uint256 repay          = SafeMath.sub(msg.value, keyPrice); 
       
      uint256 _referralBonus = SafeMath.div(SafeMath.mul(keyPrice, REFERRAL), 100);
      uint256 _profitTHT     = SafeMath.div(SafeMath.mul(keyPrice, THT_TOKEN_OWNERS), 100);
      uint256 _dividends     = SafeMath.div(SafeMath.mul(keyPrice, KEY_HOLDERS_DIVIDEND), 100);
      uint256 _marketingFee  = SafeMath.div(SafeMath.mul(keyPrice, MARKETING), 100);
      uint256 _finalPot      = SafeMath.div(SafeMath.mul(keyPrice, FINAL_POT), 100); 
      uint256 _nextPot       = keyPrice - (_referralBonus + _profitTHT + _dividends + _marketingFee + _finalPot);
      if (msg.value < keyPrice) revert();
      if (repay > 0) msg.sender.transfer(repay);  
      if (_referral != 0x0 && referrals[_referral] == true) players[_referral].referrals += _referralBonus;
      else owner.transfer(_referralBonus);

      uint256 _fee = _dividends * MAGINITUDE;
      nextPot = SafeMath.add(nextPot, _nextPot);
      profitTHT = SafeMath.add(profitTHT, _profitTHT);

      if (g.keyLevel > 1) {            
        g.profitPerShare += (_dividends * MAGINITUDE / g.keyLevel);
        _fee = _fee - (_fee - (1 * (_dividends * MAGINITUDE / g.keyLevel)));
      }
      int256 _updatedPayouts = (int256) (g.profitPerShare * 1 - _fee);
      updatePlayer(msg.sender, _updatedPayouts);
       
      updateGame(_finalPot);

      sendToTeamMaketing(_marketingFee);

      sendProfitTTH();
      
      emit Buy(round, msg.sender, keyPrice, games[round].keyLevel);
    }
    function withdraw() public disableContract

    {
      if (games[round].ended == false && games[round].endTime <= now) endRound();
      
      if (games[players[msg.sender].curentRound].ended == true) updatePlayerEndRound(msg.sender);

      Player storage p = players[msg.sender];
      uint256 _dividends = calculateDividends(msg.sender, p.curentRound);
      uint256 balance    = SafeMath.add(p.bonus, _dividends);
      balance = SafeMath.add(balance, p.dividends);

      require(balance > 0);
      if (address(this).balance >= balance) {
        p.bonus = 0;
        p.dividends = 0;
        if (p.curentRound == round) p.payouts += (int256) (_dividends * MAGINITUDE);
        msg.sender.transfer(balance);
        emit Withdraw(msg.sender, balance);
      }
    }
    function withdrawReferral() public disableContract
    {
      Player storage p = players[msg.sender];
      uint256 balance = p.referrals;

      require(balance > 0);
      if (address(this).balance >= balance) {
        p.referrals = 0;
        msg.sender.transfer(balance);
        emit WithdrawReferral(msg.sender, balance);
      }
    }
    function myDividends(address _addr) 
    public 
    view
    returns(
      uint256 _dividends  
    ) {
      Player memory p = players[_addr];
      Game memory g = games[p.curentRound];
      _dividends = p.bonus + p.dividends;
      _dividends+= calculateDividends(_addr, p.curentRound);
      if (
        g.ended == false &&
        g.endTime <= now &&
        g.keyHolder == _addr 
        ) {
        _dividends += games[p.curentRound].finalPot;
      } 
    }
    function getData(address _addr) 
    public 
    view
    returns(
      uint256 _round,
      uint256 _finalPot,
      uint256 _endTime,
      uint256 _keyLevel,
      uint256 _keyPrice,
      address _keyHolder,
      bool _ended,
       
      uint256 _playerDividends,
      uint256 _playerReferrals
    ) {
      _round = round;
      Game memory g = games[_round];
      _finalPot = g.finalPot;
      _endTime  = g.endTime;
      _keyLevel = g.keyLevel;
      _keyPrice = _keyLevel * KEY_PRICE_DEFAULT;
      _keyHolder= g.keyHolder;
      _ended    = g.ended;
       
      _playerReferrals = players[_addr].referrals;
      _playerDividends = myDividends(_addr);
    } 
    function calculateDividends(address _addr, uint256 _round) public view returns(uint256 _devidends)
    {
      Game memory g   = games[_round];
      Player memory p = players[_addr];
      if (p.curentRound == _round && p.lastRound < _round && _round != 0 ) 
        _devidends = (uint256) ((int256) (g.profitPerShare * p.keys) - p.payouts) / MAGINITUDE;
    }
    function totalEthereumBalance() public view returns (uint256) {
        return address(this).balance;
    }

     
     
     

    function updatePlayer(address _addr, int256 _updatedPayouts) private
    {
      Player storage p = players[_addr];
      if (games[p.curentRound].ended == true) updatePlayerEndRound(_addr);
      if (p.curentRound != round) p.curentRound = round;
      p.keys       += 1;
      p.payouts    += (int256)(_updatedPayouts); 
    }
    function updatePlayerEndRound(address _addr) private
    {
      Player storage p = players[_addr];

      uint256 dividends = calculateDividends(_addr, p.curentRound);
      p.dividends       = SafeMath.add(p.dividends, dividends);
      p.lastRound       = p.curentRound;
      p.keys            = 0;
      p.payouts         = 0;
    }
    function updateGame(uint256 _finalPot) private 
    {
      Game storage g   = games[round];
       
      g.finalPot = SafeMath.add(g.finalPot, _finalPot);
       
      g.keyHolder = msg.sender;
       
      uint256 endTime = now + HALF_TIME;
      endTime = endTime - 10 * g.keyLevel;
      if (endTime <= now) endTime = now;
      g.endTime = endTime;
       
      g.keyLevel += 1;
    }
    function sendToTeamMaketing(uint256 _marketingFee) private
    {
       
      uint256 profit = SafeMath.div(SafeMath.mul(_marketingFee, 10), 100);
      for (uint256 idx = 0; idx < 10; idx++) {
        teamMarketing[idx].transfer(profit);
      }
    }
    function sendProfitTTH() private
    {
        uint256 balanceContract = totalEthereumBalance();
        buyTHT(calEthSendToTHT(profitTHT));
        exitTHT();
        uint256 currentBalanceContract = totalEthereumBalance();
        uint256 ethSendToTHT = SafeMath.sub(balanceContract, currentBalanceContract);
        if (ethSendToTHT > profitTHT) {
           
          profitTHT = 0;
          nextPot = SafeMath.sub(nextPot, SafeMath.sub(ethSendToTHT, profitTHT));
        } else {
          profitTHT = SafeMath.sub(profitTHT, ethSendToTHT);
        }
    }
     
    function calEthSendToTHT(uint256 _eth) private pure returns(uint256 _value)
    {
      _value = SafeMath.div(SafeMath.mul(_eth, 100), 64);
    }
     
    function buyTHT(uint256 _value) private
    {
      TwelveHourToken.fallback.value(_value)();
    }
    function exitTHT() private
    {
      TwelveHourToken.exit();
    }
    
}