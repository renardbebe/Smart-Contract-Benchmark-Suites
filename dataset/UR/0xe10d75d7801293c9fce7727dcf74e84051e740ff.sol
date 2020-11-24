 

pragma solidity ^0.4.25;

contract Ownable {
  address public owner;

   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
     
    owner = newOwner;
  }
  
     
    modifier isHuman() {
        address _addr = msg.sender;
        require (_addr == tx.origin);
        
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }


}

contract pokerEvents{
    event Bettings(
        uint indexed guid,
        uint gameType,
        address indexed playerAddr,
        uint[] bet,
        bool indexed result,
        uint winNo,
        uint amount,
        uint winAmount,
        uint jackpot
        );
        
    event JackpotPayment(
        uint indexed juid,
        address indexed playerAddr,
        uint amount,
        uint winAmount
        );
    
    event FreeLottery(
        uint indexed luid,
        address indexed playerAddr,
        uint indexed winAmount
        );
    
}

contract Poker is Ownable,pokerEvents{
    using inArrayExt for address[];
    using intArrayExt for uint[];
    
    address private opAddress;
    address private wallet1;
    address private wallet2;
    
    bool public gamePaused=false;
    uint public guid=1;
    uint public luid=1;
    mapping(string=>uint) odds;

     
    uint minPrize=0.01 ether;
    uint lotteryPercent = 3 ether;
    uint public minBetVal=0.01 ether;
    uint public maxBetVal=1 ether;
    
     
    struct FreeLotto{
        bool active;
        uint prob;
        uint prize;
        uint freezeTimer;
        uint count;
        mapping(address => uint) lastTime;
    }
    mapping(uint=>FreeLotto) lotto;
    mapping(address=>uint) playerCount;
    bool freeLottoActive=true;
    
     
    uint public jpBalance=0;
    uint jpMinBetAmount=0.05 ether;
    uint jpMinPrize=0.01 ether;
    uint jpChance=1000;
    uint jpPercent=0.3 ether;
    
     
    bytes32 private rndSeed;
    uint private minute=60;
    uint private hour=60*60;
    
     
    constructor(address _rndAddr) public{
        opAddress=msg.sender;
        wallet1=msg.sender;
        wallet2=msg.sender;
        
        odds['bs']=1.97 ether;
        odds['suit']=3.82 ether;
        odds['num']=11.98 ether;
        odds['nsuit']=49.98 ether;
    
         
        lotto[1]=FreeLotto(true,1000,0.1 ether,hour / 100 ,0);
        lotto[2]=FreeLotto(true,100000,1 ether,3*hour/100 ,0);

        
         
        RandomOnce rnd=RandomOnce(_rndAddr);
        bytes32 _rndSeed=rnd.getRandom();
        rnd.destruct();
        
        rndSeed=keccak256(abi.encodePacked(blockhash(block.number-1), msg.sender,now,_rndSeed));
    }

     function play(uint _gType,uint[] _bet) payable isHuman() public{
        require(!gamePaused,'Game Pause');
        require(msg.value >=  minBetVal*_bet.length && msg.value <=  maxBetVal*_bet.length,"value is incorrect" );

        bool _ret=false;
        uint _betAmount= msg.value /_bet.length;
        uint _prize=0;
        
        uint _winNo= uint(keccak256(abi.encodePacked(rndSeed,msg.sender,block.coinbase,block.timestamp, block.difficulty,block.gaslimit))) % 52 + 1;
        rndSeed = keccak256(abi.encodePacked(msg.sender,block.timestamp,rndSeed, block.difficulty));
        
        if(_gType==1){
            if(_betAmount * odds['bs']  / 1 ether >= address(this).balance/2){
                revert("over max bet amount");
            }
            
            if((_winNo > 31 && _bet.contain(2)) || (_winNo < 28 && _bet.contain(1))){
                _ret=true;
                _prize=(_betAmount * odds['bs']) / 1 ether;
            }else if(_winNo>=28 && _winNo <=31 && _bet.contain(0)){
                _ret=true;
                _prize=(_betAmount * 12 ether) / 1 ether; 
            }
        }
        
         
        if(_gType==2 && _bet.contain(_winNo%4+1)){
            if(_betAmount * odds['suit'] / 1 ether >= address(this).balance/2){
                revert("over max bet amount");
            }
            
            _ret=true;
            _prize=(_betAmount * odds['suit']) / 1 ether; 
        }
        
        if(_gType==3 && _bet.contain((_winNo-1)/4+1)){
            if(_betAmount * odds['num'] / 1 ether >= address(this).balance/2){
                revert("over max bet amount");
            }
            
            _ret=true;
            _prize=(_betAmount * odds['num']) / 1 ether; 
        }
        
        if(_gType==4 && _bet.contain(_winNo)){
            if(_betAmount * odds['nsuit'] / 1 ether >= address(this).balance/2){
                revert("over max bet amount");
            }
            
            _ret=true;
            _prize=(_betAmount * odds['nsuit']) / 1 ether; 
            
        }

        if(_ret){
            msg.sender.transfer(_prize);
        }else{
            jpBalance += (msg.value * jpPercent) / 100 ether;
        }
        
        
         
        uint tmpJackpot=0;
        if(_betAmount >= jpMinBetAmount){
            uint _jpNo= uint(keccak256(abi.encodePacked(rndSeed,msg.sender,block.coinbase,block.timestamp, block.difficulty,block.gaslimit))) % jpChance;
            if(_jpNo==77 && jpBalance>jpMinPrize){
                msg.sender.transfer(jpBalance);
                emit JackpotPayment(guid,msg.sender,_betAmount,jpBalance);
                tmpJackpot=jpBalance;
                jpBalance=0;
            }else{
                tmpJackpot=0;
            }
            
            rndSeed = keccak256(abi.encodePacked(block.coinbase,msg.sender,block.timestamp, block.difficulty,rndSeed));
        }
        
        emit Bettings(guid,_gType,msg.sender,_bet,_ret,_winNo,msg.value,_prize,tmpJackpot);
        
        guid+=1;
    }
    

    function freeLottery(uint _gid) public isHuman(){
        require(!gamePaused,'Game Pause');
        require(freeLottoActive && lotto[_gid].active,'Free Lotto is closed');
        require(now - lotto[_gid].lastTime[msg.sender] >= lotto[_gid].freezeTimer,'in the freeze time');
        
        uint chancex=1;
        uint winNo = 0;
        if(playerCount[msg.sender]>=3){
            chancex=2;
        }
        if(playerCount[msg.sender]>=6){
            chancex=3;
        }
        
        winNo=uint(keccak256(abi.encodePacked(msg.sender,block.number,block.timestamp, rndSeed,block.difficulty,block.gaslimit))) % (playerCount[msg.sender]>=3?lotto[_gid].prob/chancex:lotto[_gid].prob)+1;

        bool result;
        if(winNo==7){
            result=true;
            msg.sender.transfer(lotto[_gid].prize);
        }else{
            result=false;
            if(playerCount[msg.sender]==0 || lotto[_gid].lastTime[msg.sender] <= now -lotto[_gid].freezeTimer - 15*minute){
                playerCount[msg.sender]+=1;
            }else{
                playerCount[msg.sender]=0;
            }
        }
        
        emit FreeLottery(luid,msg.sender,result?lotto[_gid].prize:0);
        
        rndSeed = keccak256(abi.encodePacked( block.difficulty,block.coinbase,msg.sender,block.timestamp,rndSeed));
        luid=luid+1;
        lotto[_gid].lastTime[msg.sender]=now;
    }
    
    function freeLottoInfo() public view isHuman() returns(uint,uint,uint){
        uint chance=1;
        if(playerCount[msg.sender]>=3){
            chance=2;
        }
        if(playerCount[msg.sender]>=6){
            chance=3;
        }
        return (lotto[1].lastTime[msg.sender],lotto[2].lastTime[msg.sender],chance);
    }
    
    function updateRndSeed(address _rndAddr) isHuman() public {
        require(msg.sender==owner || msg.sender==opAddress,"DENIED");
        
        RandomOnce rnd=RandomOnce(_rndAddr);
        bytes32 _rndSeed=rnd.getRandom();
        rnd.destruct();
        
        rndSeed = keccak256(abi.encodePacked(msg.sender,block.number,_rndSeed,block.timestamp,block.coinbase,rndSeed, block.difficulty,block.gaslimit));
    }
    
    function updateOdds(string _game,uint _val) public isHuman(){
        require(msg.sender==owner || msg.sender==opAddress);
        
        odds[_game]=_val;
    }
    
    function updateStatus(uint _p,bool _status) public isHuman(){
        require(msg.sender==owner || msg.sender==opAddress);
        
        if(_p==1){gamePaused=_status;}
        if(_p==2){freeLottoActive=_status;}
        if(_p==3){lotto[1].active =_status;}
        if(_p==4){lotto[2].active =_status;}
        
    }
    
    function getOdds() public view returns(uint[]) {
        uint[] memory ret=new uint[](4);
        ret[0]=odds['bs'];
        ret[1]=odds['suit'];
        ret[2]=odds['num'];
        ret[3]=odds['nsuit'];
        
        return ret;
    }
    
    function updateLottoParams(uint _gid,uint _key,uint _val) public isHuman(){
        require(msg.sender==owner || msg.sender==opAddress);
         
        
        if(_key==1){lotto[_gid].active=(_val==1);}
        if(_key==2){lotto[_gid].prob=_val;}
        if(_key==3){lotto[_gid].prize=_val;}
        if(_key==4){lotto[_gid].freezeTimer=_val;}
        
    }
    
    function getLottoData(uint8 _gid) public view returns(bool,uint,uint,uint,uint){
        return (lotto[_gid].active,lotto[_gid].prob,lotto[_gid].prize,lotto[_gid].freezeTimer,lotto[_gid].count);
        
    }
    
    function setAddr(uint _acc,address _addr) public onlyOwner isHuman(){
        if(_acc==1){wallet1=_addr;}
        if(_acc==2){wallet2=_addr;}
        if(_acc==3){opAddress=_addr;}
    }
    
    function getAddr(uint _acc) public view onlyOwner returns(address){
        if(_acc==1){return wallet1;}
        if(_acc==2){return wallet2;}
        if(_acc==3){return opAddress;}
    }
    

    function withdraw(address _to,uint amount) public onlyOwner isHuman() returns(bool){
        require(address(this).balance - amount > 0);
        _to.transfer(amount);
    }
    
    function distribute(uint _p) public onlyOwner isHuman(){
        uint prft1=_p* 85 / 100;
        uint prft2=_p* 10 / 100;
        uint prft3=_p* 5 / 100;

        owner.transfer(prft1);
        wallet1.transfer(prft2);
        wallet2.transfer(prft3);

    }
    
    
    function() payable isHuman() public {
        
    }
    
}




contract RandomOnce{
    constructor() public{}
    function getRandom() public view returns(bytes32){}
    function destruct() public{}
}



library inArrayExt{
    function contain(address[] _arr,address _val) internal pure returns(bool){
        for(uint _i=0;_i< _arr.length;_i++){
            if(_arr[_i]==_val){
                return true;
                break;
            }
        }
        return false;
    }
}

library intArrayExt{
    function contain(uint[] _arr,uint _val) internal pure returns(bool){
        for(uint _i=0;_i< _arr.length;_i++){
            if(_arr[_i]==_val){
                return true;
                break;
            }
        }
        return false;
    }
}