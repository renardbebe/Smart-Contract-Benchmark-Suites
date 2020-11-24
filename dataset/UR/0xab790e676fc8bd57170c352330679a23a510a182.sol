 

pragma solidity ^0.4.18;  



contract TicTacPotato{

     
    event StalematePayout(address adr, uint256 amount);

    address public ceoAddress;
    uint256 public lastBidTime;
    uint256 public contestStartTime;
    uint256 public lastPot;
    
     
    mapping (uint256 => address) public indexToAddress;
    mapping (address => uint256) public cantBidUntil;
    Tile[] public tiles;
    
    uint256 public TIME_TO_STALEMATE=30 minutes;
    uint256 public NUM_TILES=12;
    uint256 public START_PRICE=0.005 ether;
    uint256 public CONTEST_INTERVAL=15 minutes;
    uint256 public COOLDOWN_TIME=7 minutes; 
    uint[][]  tests = [[0,1,2],[3,4,5],[6,7,8], [0,3,6],[1,4,7],[2,5,8], [0,4,8],[2,4,6]];
     
    struct Tile {
        address owner;
        uint256 price;
    }
    
     
    function TicTacPotato() public{
        ceoAddress=msg.sender;
        contestStartTime=SafeMath.add(now,1 hours);
        for(uint i = 0; i<NUM_TILES; i++){
            Tile memory newtile=Tile({owner:address(this),price: START_PRICE});
            tiles.push(newtile);
            indexToAddress[i]=address(this);
        }
    }
    
     
    function buyTile(uint256 index) public payable{
        require(now>contestStartTime);
        if(_endContestIfNeededStalemate()){ 

        }
        else{
            Tile storage tile=tiles[index];
            require(msg.value >= tile.price);
            require(now >= cantBidUntil[msg.sender]); 
            cantBidUntil[msg.sender]=SafeMath.add(now,COOLDOWN_TIME);
             
            require(msg.sender != tile.owner);
            require(msg.sender != ceoAddress);
            uint256 sellingPrice=tile.price;
            uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
            uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 70), 100));
            uint256 devFee= uint256(SafeMath.div(SafeMath.mul(sellingPrice, 4), 100));
             
             
            if(tile.owner!=address(this)){
                tile.owner.transfer(payment);
            }
            ceoAddress.transfer(devFee);
             
            tile.price= SafeMath.div(SafeMath.mul(sellingPrice, 115), 70);
            tile.owner=msg.sender; 
            indexToAddress[index]=msg.sender;
            lastBidTime=block.timestamp;
            if(!_endContestIfNeeded()){ 
                msg.sender.transfer(purchaseExcess); 
            }
        }
    }
    function pause() public {
        require(msg.sender==ceoAddress);
        require(now<contestStartTime);
        contestStartTime=SafeMath.add(now,7 days);
    }
    function unpause() public{
        require(msg.sender==ceoAddress);
        require(now<contestStartTime);
        _setNewStartTime();
    }
    function getBalance() public view returns(uint256 value){
        return this.balance;
    }
    function timePassed() public view returns(uint256 time){
        if(lastBidTime==0){
            return 0;
        }
        return SafeMath.sub(block.timestamp,lastBidTime);
    }
    function timeLeftToContestStart() public view returns(uint256 time){
        if(block.timestamp>contestStartTime){
            return 0;
        }
        return SafeMath.sub(contestStartTime,block.timestamp);
    }
    function timeLeftToBid(address addr) public view returns(uint256 time){
        if(now>cantBidUntil[addr]){
            return 0;
        }
        return SafeMath.sub(cantBidUntil[addr],now);
    }
    function timeLeftToCook() public view returns(uint256 time){
        return SafeMath.sub(TIME_TO_STALEMATE,timePassed());
    }
    function contestOver() public view returns(bool){
        return timePassed()>=TIME_TO_STALEMATE;
    }
    function haveIWon() public view returns(bool){
        return checkWinner(msg.sender);
    }
    
      
     
     
    function checkWinner(address a) constant returns (bool){
        for(uint i =0; i < 8;i++){
            uint[] memory b = tests[i];
            if(indexToAddress[b[0]] ==a && indexToAddress[b[1]]==a && indexToAddress[b[2]]==a) return true;
        }
        return false;
    }
    
     
    
    function _endContestIfNeeded() private returns(bool){
        if(haveIWon()){
            lastPot=this.balance;
            msg.sender.transfer(this.balance); 
            lastBidTime=0;
            _resetTiles();
            _setNewStartTime();
            return true;
        }
        return false;
    }
     
    function _endContestIfNeededStalemate() private returns(bool){
        if(timePassed()>=TIME_TO_STALEMATE){
             
            msg.sender.transfer(msg.value);
            lastPot=this.balance;
            _stalemateTransfer();
            lastBidTime=0;
            _resetTiles();
            _setNewStartTime();
            return true;
        }
        return false;
    }
     
    function _stalemateTransfer() private{
        uint payout=this.balance;
         
        for(uint i=9;i<12;i++){
            require(msg.sender != indexToAddress[i]);
            if(indexToAddress[i]!=address(this)){
                uint proportion=(i-8)*15;
                indexToAddress[i].transfer(uint256(SafeMath.div(SafeMath.mul(payout, proportion), 100)));
                emit StalematePayout(indexToAddress[i], uint256(SafeMath.div(SafeMath.mul(payout, proportion), 100)));
            }
        }
    }
    function _resetTiles() private{
        for(uint i = 0; i<NUM_TILES; i++){
             
            Tile memory newtile=Tile({owner:address(this),price: START_PRICE});
            tiles[i]=newtile;
            indexToAddress[i]=address(this);
        }
         
    }
    function _setNewStartTime() private{
            contestStartTime=SafeMath.add(now,CONTEST_INTERVAL);
    }
}
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
}