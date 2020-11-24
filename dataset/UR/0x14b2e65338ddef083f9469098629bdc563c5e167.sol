 

pragma solidity ^0.4.23;

contract Ownable {
  address public owner;

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

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


contract Mortal is Ownable{
    uint public stopTS;
    uint public minimumWait = 1 hours;
    bool public killed;

     
    function stopPlaying() public onlyOwner{
        stopTS = now;
    }

     
    function kill() public onlyOwner{
        require(stopTS > 0 && stopTS + 2 * minimumWait <= now, "before killing, playing needs to be stopped and sufficient time has to pass");
        selfdestruct(owner);
    }

     
    function permaStop() public onlyOwner{
        require(stopTS > 0 && stopTS + 2 * minimumWait <= now, "before killing, playing needs to be stopped and sufficient time has to pass");
        killed = true;
        owner.transfer(address(this).balance);
    }

     
    function resumePlaying() public onlyOwner{
        require(!killed, "killed contract cannot be reactivated");
        stopTS = 0;
    }

     
    modifier active(){
        require(stopTS == 0, "playing has been stopped by the owner");
        _;
    }
}

contract Administrable is Mortal{
     
    uint public charityPot;
    uint public highscorePot;
    uint public affiliatePot;
    uint public surprisePot;
    uint public developerPot;
     
    uint public charityPercent = 25;
    uint public highscorePercent = 50;
    uint public affiliatePercent = 50;
    uint public surprisePercent = 25;
    uint public developerPercent = 50;
    uint public winnerPercent = 800;
     
    address public highscoreHolder;
    address public signer;
     
    mapping (address => uint) public affiliateBalance;
     
    mapping (bytes32 => bool) public used;
    event Withdrawal(uint8 pot, address receiver, uint value);

    modifier validAddress(address receiver){
        require(receiver != 0x0, "invalid receiver");
        _;
    }


     
    function setMinimumWait(uint newMin) public onlyOwner{
        minimumWait = newMin;
    }

     
    function withdrawDeveloperPot(address receiver) public onlyOwner validAddress(receiver){
        uint value = developerPot;
        developerPot = 0;
        receiver.transfer(value);
        emit Withdrawal(0, receiver, value);
    }

     
    function donate(address charity) public onlyOwner validAddress(charity){
        uint value = charityPot;
        charityPot = 0;
        charity.transfer(value);
        emit Withdrawal(1, charity, value);
    }

     
    function withdrawHighscorePot(address receiver) public validAddress(receiver){
        require(msg.sender == highscoreHolder);
        uint value = highscorePot;
        highscorePot = 0;
        receiver.transfer(value);
        emit Withdrawal(2, receiver, value);
    }

     
    function withdrawAffiliateBalance(address receiver) public validAddress(receiver){
        uint value = affiliateBalance[msg.sender];
        require(value > 0);
        affiliateBalance[msg.sender] = 0;
        receiver.transfer(value);
        emit Withdrawal(3, receiver, value);
    }

     
    function withdrawSurprisePot(address receiver) public onlyOwner validAddress(receiver){
        uint value = surprisePot;
        surprisePot = 0;
        receiver.transfer(value);
        emit Withdrawal(4, receiver, value);
    }

     
    function withdrawSurprisePotUser(uint value, uint expiry, uint8 v, bytes32 r, bytes32 s) public{
        require(expiry >= now, "signature expired");
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, value, expiry));
        require(!used[hash], "same signature was used before");
        require(ecrecover(hash, v, r, s) == signer, "invalid signer");
        require(value <= surprisePot, "not enough in the pot");
        surprisePot -= value;
        used[hash] = true;
        msg.sender.transfer(value);
        emit Withdrawal(4, msg.sender, value);
    }

     
    function setSigner(address signingAddress) public onlyOwner{
        signer = signingAddress;
    }

     
    function setPercentages(uint affiliate, uint charity, uint dev, uint highscore, uint surprise) public onlyOwner{
        uint sum =  affiliate + charity + highscore + surprise + dev;
        require(sum < 500, "winner should not lose money");
        charityPercent = charity;
        affiliatePercent = affiliate;
        highscorePercent = highscore;
        surprisePercent = surprise;
        developerPercent = dev;
        winnerPercent = 1000 - sum;
    }
}

contract Etherman is Administrable{

    struct game{
        uint32 timestamp;
        uint128 stake;
        address player1;
        address player2;
    }

    struct player{
        uint8 team;
        uint64 score;
        address referrer;
    }

    mapping (bytes32 => game) public games;
    mapping (address => player) public players;

    event NewGame(bytes32 gameId, address player1, uint stake);
    event GameStarted(bytes32 gameId, address player1, address player2, uint stake);
    event GameDestroyed(bytes32 gameId);
    event GameEnd(bytes32 gameId, address winner, uint value);
    event NewHighscore(address holder, uint score, uint lastPot);

    modifier onlyHuman(){
        require(msg.sender == tx.origin, "contract calling");
        _;
    }

    constructor(address signingAddress) public{
        setSigner(signingAddress);
    }

     
    function initGameReferred(address referrer, uint8 team) public payable active onlyHuman validAddress(referrer){
         
        if(players[msg.sender].referrer == 0x0 && players[msg.sender].score == 0)
            players[msg.sender] = player(team, 0, referrer);
        initGame();
    }

     
    function initGameTeam(uint8 team) public payable active onlyHuman{
        if(players[msg.sender].score == 0)
            players[msg.sender].team = team;
        initGame();
    }

     
    function initGame() public payable active onlyHuman{
        require(msg.value <= 10 ether, "stake needs to be lower than or equal to 10 ether");
        require(msg.value > 1 finney, "stake needs to be at least 1 finney");
        bytes32 gameId = keccak256(abi.encodePacked(msg.sender, block.number));
        games[gameId] = game(uint32(now), uint128(msg.value), msg.sender, 0x0);
        emit NewGame(gameId, msg.sender, msg.value);
    }

     
    function joinGameReferred(bytes32 gameId, address referrer, uint8 team) public payable active onlyHuman validAddress(referrer){
         
        if(players[msg.sender].referrer == 0x0 && players[msg.sender].score == 0)
            players[msg.sender] = player(team, 0, referrer);
        joinGame(gameId);
    }

     
    function joinGameTeam(bytes32 gameId, uint8 team) public payable active onlyHuman{
        if(players[msg.sender].score == 0)
            players[msg.sender].team = team;
        joinGame(gameId);
    }

     
    function joinGame(bytes32 gameId) public payable active onlyHuman{
        game storage cGame = games[gameId];
        require(cGame.player1!=0x0, "game id unknown");
        require(cGame.player1 != msg.sender, "cannot play with one self");
        require(msg.value >= cGame.stake, "value does not suffice to join the game");
        cGame.player2 = msg.sender;
        cGame.timestamp = uint32(now);
        emit GameStarted(gameId, cGame.player1, msg.sender, cGame.stake);
        if(msg.value > cGame.stake) developerPot += msg.value - cGame.stake;
    }

     
    function withdraw(bytes32 gameId) public onlyHuman{
        game storage cGame = games[gameId];
        uint128 value = cGame.stake;
        if(msg.sender == cGame.player1){
            if(cGame.player2 == 0x0){
                delete games[gameId];
                msg.sender.transfer(value);
            }
            else if(cGame.timestamp + minimumWait <= now){
                address player2 = cGame.player2;
                delete games[gameId];
                msg.sender.transfer(value);
                player2.transfer(value);
            }
            else{
                revert("minimum waiting time has not yet passed");
            }
        }
        else if(msg.sender == cGame.player2){
            if(cGame.timestamp + minimumWait <= now){
                address player1 = cGame.player1;
                delete games[gameId];
                msg.sender.transfer(value);
                player1.transfer(value);
            }
            else{
                revert("minimum waiting time has not yet passed");
            }
        }
        else{
            revert("sender is not a player in this game");
        }
        emit GameDestroyed(gameId);
    }

     
    function claimWin(bytes32 gameId, uint8 v, bytes32 r, bytes32 s) public onlyHuman{
        game storage cGame = games[gameId];
        require(cGame.player2!=0x0, "game has not started yet");
        require(msg.sender == cGame.player1 || msg.sender == cGame.player2, "sender is not a player in this game");
        require(ecrecover(keccak256(abi.encodePacked(gameId, msg.sender)), v, r, s) == signer, "invalid signature");
        uint256 value = 2*cGame.stake;
        uint256 win = winnerPercent * value / 1000;
        addScore(msg.sender, cGame.stake);
        delete games[gameId];
        charityPot += value * charityPercent / 1000;
         
        if(players[highscoreHolder].team == players[msg.sender].team){
            win += value * highscorePercent / 1000;
        }
        else{
            highscorePot += value * highscorePercent / 1000;
        }
        surprisePot += value * surprisePercent / 1000;
        if(players[msg.sender].referrer == 0x0){
            developerPot += value * (developerPercent + affiliatePercent) / 1000;
        }
        else{
            developerPot += value * developerPercent / 1000;
            affiliateBalance[players[msg.sender].referrer] += value * affiliatePercent / 1000;
        }
        msg.sender.transfer(win); 
        emit GameEnd(gameId, msg.sender, win);
    }

    function addScore(address receiver, uint stake) private{
        player storage rec = players[receiver];
        player storage hsh = players[highscoreHolder];
        if(rec.team == hsh.team){
            if(stake < 0.05 ether) rec.score += 1;
            else if(stake < 0.5 ether) rec.score += 5;
            else rec.score += 10;
        }
        else{ 
            if(stake < 0.05 ether) rec.score += 2;
            else if(stake < 0.5 ether) rec.score += 7;
            else rec.score += 13;
        }
        if(rec.score > hsh.score){
            uint pot = highscorePot;
            if(pot > 0){
                highscorePot = 0;
                highscoreHolder.transfer(pot);
            }
            highscoreHolder = receiver;
            emit NewHighscore(receiver, rec.score, pot);
        }
    }

     
    function() public payable{
        developerPot+=msg.value;
    }
    
    function doNothing(){
        
    }

}