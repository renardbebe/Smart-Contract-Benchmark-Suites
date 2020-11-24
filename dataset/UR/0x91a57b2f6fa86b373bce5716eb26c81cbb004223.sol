 

pragma solidity ^0.4.8;

contract OwnedByWinsome {

  address public owner;
  mapping (address => bool) allowedWorker;

  function initOwnership(address _owner, address _worker) internal{
    owner = _owner;
    allowedWorker[_owner] = true;
    allowedWorker[_worker] = true;
  }

  function allowWorker(address _new_worker) onlyOwner{
    allowedWorker[_new_worker] = true;
  }
  function removeWorker(address _old_worker) onlyOwner{
    allowedWorker[_old_worker] = false;
  }
  function changeOwner(address _new_owner) onlyOwner{
    owner = _new_owner;
  }
						    
  modifier onlyAllowedWorker{
    if (!allowedWorker[msg.sender]){
      throw;
    }
    _;
  }

  modifier onlyOwner{
    if (msg.sender != owner){
      throw;
    }
    _;
  }

  
}

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


 
contract BasicToken {
  using SafeMath for uint;
  event Transfer(address indexed from, address indexed to, uint value);
  mapping(address => uint) balances;
  uint public     totalSupply =    0;    			  
  
   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  
}


contract StandardToken is BasicToken{
  
  event Approval(address indexed owner, address indexed spender, uint value);

  
  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


contract WinToken is StandardToken, OwnedByWinsome{

  string public   name =           "Winsome.io Token";
  string public   symbol =         "WIN";
  uint public     decimals =       18;
  
  mapping (address => bool) allowedMinter;

  function WinToken(address _owner){
    allowedMinter[_owner] = true;
    initOwnership(_owner, _owner);
  }

  function allowMinter(address _new_minter) onlyOwner{
    allowedMinter[_new_minter] = true;
  }
  function removeMinter(address _old_minter) onlyOwner{
    allowedMinter[_old_minter] = false;
  }

  modifier onlyAllowedMinter{
    if (!allowedMinter[msg.sender]){
      throw;
    }
    _;
  }
  function mintTokens(address _for, uint _value_wei) onlyAllowedMinter {
    balances[_for] = balances[_for].add(_value_wei);
    totalSupply = totalSupply.add(_value_wei) ;
    Transfer(address(0), _for, _value_wei);
  }
  function destroyTokens(address _for, uint _value_wei) onlyAllowedMinter {
    balances[_for] = balances[_for].sub(_value_wei);
    totalSupply = totalSupply.sub(_value_wei);
    Transfer(_for, address(0), _value_wei);    
  }
  
}

contract Rouleth
{
   
  address public developer;
  uint8 public blockDelay;  
  uint8 public blockExpiration;  
  uint256 public maxGamble;  
  uint256 public minGamble;  

  mapping (address => uint) pendingTokens;
  
  address public WINTOKENADDRESS;
  WinToken winTokenInstance;

  uint public emissionRate;
  
   
  enum BetTypes{number, color, parity, dozen, column, lowhigh} 
  struct Gamble
  {
    address player;
    bool spinned;  
    bool win;
     
    BetTypes betType;
    uint input;  
    uint256 wager;
    uint256 blockNumber;  
    uint256 blockSpinned;  
    uint8 wheelResult;
  }
  Gamble[] private gambles;

   
  mapping (address=>uint) gambleIndex;  
   
  enum Status {waitingForBet, waitingForSpin} mapping (address=>Status) playerStatus; 


   
   
   

  function  Rouleth(address _developer, address _winToken)  
  {
    WINTOKENADDRESS = _winToken;
    winTokenInstance = WinToken(_winToken);
    developer = _developer;
    blockDelay=0;  
    blockExpiration=245;  
    minGamble=10 finney;  
    maxGamble=1 ether;  
    emissionRate = 5;
  }
    
  modifier onlyDeveloper() 
  {
    if (msg.sender!=developer) throw;
    _;
  }

  function addBankroll()
    onlyDeveloper
    payable {
  }

  function removeBankroll(uint256 _amount_wei)
    onlyDeveloper
  {
    if (!developer.send(_amount_wei)) throw;
  }
    
  function changeDeveloper_only_Dev(address new_dev)
    onlyDeveloper
  {
    developer=new_dev;
  }





   
  function changeSettings_only_Dev(uint256 newMinGamble, uint256 newMaxGamble, uint8 newBlockDelay, uint8 newBlockExpiration, uint newEmissionRate)
    onlyDeveloper
  {
    emissionRate = newEmissionRate;
     
    if (newMaxGamble<newMinGamble) throw;  
    maxGamble=newMaxGamble; 
    minGamble=newMinGamble;
     
    blockDelay=newBlockDelay;
    if (newBlockExpiration < blockDelay + 250) throw;
    blockExpiration=newBlockExpiration;
  }


   
   
   

   
   
   
  function ()
    payable
    {
       
      betOnColor(false);
    } 

   
   
  function checkBetValue() private returns(uint256)
  {
    if (msg.value < minGamble) throw;
    if (msg.value > maxGamble){
      return maxGamble;
    }
    else{
      return msg.value;
    }
  }



   
  function placeBet(BetTypes betType, uint input) private
  {

    if (playerStatus[msg.sender] != Status.waitingForBet) {
      if (!SpinTheWheel(msg.sender)) throw;
    }

     
    playerStatus[msg.sender] = Status.waitingForSpin;
    gambleIndex[msg.sender] = gambles.length;
    
     
    uint256 betValue = checkBetValue();
    pendingTokens[msg.sender] += betValue * emissionRate;

    
    gambles.push(Gamble(msg.sender, false, false, betType, input, betValue, block.number, 0, 37));  
    
     
    if (betValue < msg.value) {
      if (msg.sender.send(msg.value-betValue)==false) throw;
    }
  }

  function getPendingTokens(address account) constant returns (uint){
    return pendingTokens[account];
  }
  
  function redeemTokens(){
    uint totalTokens = pendingTokens[msg.sender];
    if (totalTokens == 0) return;
    pendingTokens[msg.sender] = 0;

     
    
     
    winTokenInstance.mintTokens(msg.sender, totalTokens);
  }

  

   
  function betOnNumber(uint numberChosen)
    payable
  {
     
    if (numberChosen>36) throw;
    placeBet(BetTypes.number, numberChosen);
  }

   
   
   
   
  function betOnColor(bool Black)
    payable
  {
    uint input;
    if (!Black) 
      { 
	input=0;
      }
    else{
      input=1;
    }
    placeBet(BetTypes.color, input);
  }

   
   
   
   
  function betOnLowHigh(bool High)
    payable
  {
    uint input;
    if (!High) 
      { 
	input=0;
      }
    else 
      {
	input=1;
      }
    placeBet(BetTypes.lowhigh, input);
  }

   
   
   
   
  function betOnOddEven(bool Odd)
    payable
  {
    uint input;
    if (!Odd) 
      { 
	input=0;
      }
    else{
      input=1;
    }
    placeBet(BetTypes.parity, input);
  }

   
   
   
   
   
  function betOnDozen(uint dozen_selected_0_1_2)
    payable

  {
    if (dozen_selected_0_1_2 > 2) throw;
    placeBet(BetTypes.dozen, dozen_selected_0_1_2);
  }


   
   
   
   
   
  function betOnColumn(uint column_selected_0_1_2)
    payable
  {
    if (column_selected_0_1_2 > 2) throw;
    placeBet(BetTypes.column, column_selected_0_1_2);
  }

   
   
   

  event Win(address player, uint8 result, uint value_won, bytes32 bHash, bytes32 sha3Player, uint gambleId, uint bet);
  event Loss(address player, uint8 result, uint value_loss, bytes32 bHash, bytes32 sha3Player, uint gambleId, uint bet);

   
   
  function spinTheWheel(address spin_for_player)
  {
    SpinTheWheel(spin_for_player);
  }


  function SpinTheWheel(address playerSpinned) private returns(bool)
  {
    if (playerSpinned==0)
      {
	playerSpinned=msg.sender;          
      }

     
    if (playerStatus[playerSpinned] != Status.waitingForSpin) return false;

     
    if (gambles[gambleIndex[playerSpinned]].spinned == true) throw;

    
     
     
    uint playerblock = gambles[gambleIndex[playerSpinned]].blockNumber;
     
    if (block.number <= playerblock+blockDelay) throw;
     
    else if (block.number > playerblock+blockExpiration) solveBet(playerSpinned, 255, false, 1, 0, 0) ;
     
    else
      {
	uint8 wheelResult;
	 
	bytes32 blockHash= block.blockhash(playerblock+blockDelay);
	 
	if (blockHash==0) throw;
	 
	bytes32 shaPlayer = sha3(playerSpinned, blockHash, this);
	 
	wheelResult = uint8(uint256(shaPlayer)%37);
	 
	checkBetResult(wheelResult, playerSpinned, blockHash, shaPlayer);
      }
    return true;
  }
    

   
  function checkBetResult(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  {
    BetTypes betType=gambles[gambleIndex[player]].betType;
     
    if (betType==BetTypes.number) checkBetNumber(result, player, blockHash, shaPlayer);
    else if (betType==BetTypes.parity) checkBetParity(result, player, blockHash, shaPlayer);
    else if (betType==BetTypes.color) checkBetColor(result, player, blockHash, shaPlayer);
    else if (betType==BetTypes.lowhigh) checkBetLowhigh(result, player, blockHash, shaPlayer);
    else if (betType==BetTypes.dozen) checkBetDozen(result, player, blockHash, shaPlayer);
    else if (betType==BetTypes.column) checkBetColumn(result, player, blockHash, shaPlayer);
  }

   
  function solveBet(address player, uint8 result, bool win, uint8 multiplier, bytes32 blockHash, bytes32 shaPlayer) private
  {
     
    playerStatus[player]=Status.waitingForBet;
    gambles[gambleIndex[player]].wheelResult=result;
    gambles[gambleIndex[player]].spinned=true;
    gambles[gambleIndex[player]].blockSpinned=block.number;
    uint bet_v = gambles[gambleIndex[player]].wager;
	
    if (win)
      {
	gambles[gambleIndex[player]].win=true;
	uint win_v = (multiplier-1)*bet_v;
	Win(player, result, win_v, blockHash, shaPlayer, gambleIndex[player], bet_v);
	 
	 
	if (player.send(win_v+bet_v)==false) throw;
      }
    else
      {
	Loss(player, result, bet_v-1, blockHash, shaPlayer, gambleIndex[player], bet_v);
	 
	if (player.send(1)==false) throw;
      }

  }

   
   
   
  function checkBetNumber(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  {
    bool win;
     
    if (result==gambles[gambleIndex[player]].input)
      {
	win=true;  
      }
    solveBet(player, result,win,36, blockHash, shaPlayer);
  }


   
   
   
  function checkBetParity(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  {
    bool win;
     
    if (result%2==gambles[gambleIndex[player]].input && result!=0)
      {
	win=true;                
      }
    solveBet(player,result,win,2, blockHash, shaPlayer);
  }
    
   
   
   
  function checkBetLowhigh(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  {
    bool win;
     
    if (result!=0 && ( (result<19 && gambles[gambleIndex[player]].input==0)
		       || (result>18 && gambles[gambleIndex[player]].input==1)
		       ) )
      {
	win=true;
      }
    solveBet(player,result,win,2, blockHash, shaPlayer);
  }

   
   
   
  uint[18] red_list=[1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36];
  function checkBetColor(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  {
    bool red;
     
    for (uint8 k; k<18; k++)
      { 
	if (red_list[k]==result) 
	  { 
	    red=true; 
	    break;
	  }
      }
    bool win;
     
    if ( result!=0
	 && ( (gambles[gambleIndex[player]].input==0 && red)  
	      || ( gambles[gambleIndex[player]].input==1 && !red)  ) )
      {
	win=true;
      }
    solveBet(player,result,win,2, blockHash, shaPlayer);
  }

   
   
   
  function checkBetDozen(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  { 
    bool win;
     
    if ( result!=0 &&
	 ( (result<13 && gambles[gambleIndex[player]].input==0)
	   ||
	   (result>12 && result<25 && gambles[gambleIndex[player]].input==1)
	   ||
	   (result>24 && gambles[gambleIndex[player]].input==2) ) )
      {
	win=true;                
      }
    solveBet(player,result,win,3, blockHash, shaPlayer);
  }

   
   
   
  function checkBetColumn(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
  {
    bool win;
     
    if ( result!=0
	 && ( (gambles[gambleIndex[player]].input==0 && result%3==1)  
	      || ( gambles[gambleIndex[player]].input==1 && result%3==2)
	      || ( gambles[gambleIndex[player]].input==2 && result%3==0)  ) )
      {
	win=true;
      }
    solveBet(player,result,win,3, blockHash, shaPlayer);
  }


  function checkMyBet(address player) constant returns(Status player_status, BetTypes bettype, uint input, uint value, uint8 result, bool wheelspinned, bool win, uint blockNb, uint blockSpin, uint gambleID)
  {
    player_status=playerStatus[player];
    bettype=gambles[gambleIndex[player]].betType;
    input=gambles[gambleIndex[player]].input;
    value=gambles[gambleIndex[player]].wager;
    result=gambles[gambleIndex[player]].wheelResult;
    wheelspinned=gambles[gambleIndex[player]].spinned;
    win=gambles[gambleIndex[player]].win;
    blockNb=gambles[gambleIndex[player]].blockNumber;
    blockSpin=gambles[gambleIndex[player]].blockSpinned;
    gambleID=gambleIndex[player];
    return;
  }

  function getTotalGambles() constant returns(uint){
    return gambles.length;
  }

  
  function getGamblesList(uint256 index) constant returns(address player, BetTypes bettype, uint input, uint value, uint8 result, bool wheelspinned, bool win, uint blockNb, uint blockSpin)
  {
    player=gambles[index].player;
    bettype=gambles[index].betType;
    input=gambles[index].input;
    value=gambles[index].wager;
    result=gambles[index].wheelResult;
    wheelspinned=gambles[index].spinned;
    win=gambles[index].win;
    blockNb=gambles[index].blockNumber;
    blockSpin=gambles[index].blockSpinned;
    return;
  }

}  