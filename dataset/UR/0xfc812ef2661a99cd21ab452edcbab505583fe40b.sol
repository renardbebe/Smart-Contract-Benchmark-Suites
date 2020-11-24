 

pragma solidity ^0.4.24;

library SafeMath {
    
     
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
     
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
     
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}

library FMDDCalcLong {
    using SafeMath for *;
     
    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }
    
     
    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

     
    function keys(uint256 _eth) 
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }
    
     
    function eth(uint256 _keys) 
        internal
        pure
        returns(uint256)  
    {
        return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}

contract Famo{
    using SafeMath for uint256;
    using FMDDCalcLong for uint256; 
	uint256 iCommunityPot;
	struct WinPerson {
		address plyr;
		uint256 iLastKeyNum;
		uint256 index;
	}
    struct Round{
        uint256 iKeyNum;
        uint256 iVault;
        uint256 iMask;
		WinPerson[15] winerList;
		uint256 iGameStartTime;
		uint256 iGameEndTime;
		uint256 iSharePot;
		uint256 iSumPayable;
        bool bIsGameEnded; 
    }
	struct PlyRound{
        uint256 iKeyNum;
        uint256 iMask;	
	}
	
    struct Player{
        uint256 gen;
        uint256 affGen;
        uint256 iLastRoundId;
		uint256 affCodeSelf;
		uint256 affCode;
        mapping (uint256=>PlyRound) roundMap;
    }
	struct SeedMember {
		uint256 f;
		uint256 iMask;
	}
    event evtBuyKey( uint256 iRoundId,address buyerAddress,uint256 iSpeedEth,uint256 iBuyNum );
    event evtAirDrop( address addr,uint256 _airDropAmt );
    event evtFirDrop( address addr,uint256 _airDropAmt );
    event evtGameRoundStart( uint256 iRoundId, uint256 iStartTime,uint256 iEndTime,uint256 iSharePot );
    
    string constant public name = "Chaojikuanggong game";
    string constant public symbol = "CJKG";
    uint256 constant public decimal = 1000000000000000000;
	bool iActivated = false;
	bool iPrepared = false;
	bool iOver = false;
    uint256 iTimeInterval;
    uint256 iAddTime;
	uint256 addTracker_;
    uint256 public airDropTracker_ = 0;      
	uint256 public airDropPot_ = 0;
	 
    uint256 public airFropTracker_ = 0; 
	uint256 public airFropPot_ = 0;
	uint256 plyid_ = 10000;
	uint256 constant public seedMemberValue_ = 5000000000000000000;
	uint256[9] affRate = [uint256(15),uint256(2),uint256(2),uint256(2),uint256(2),uint256(2),uint256(2),uint256(2),uint256(1)];

    mapping (address => Player) plyMap; 
	mapping (uint256 => address) affMap;
	mapping (address => uint256) seedBuy; 
	mapping (address => SeedMember) seedMap;
	Round []roundList;
    address creator;
	address comor;
	uint256 operatorGen;
	uint256 comorGen;
	uint256 specGen;
	uint256 public winCount;
	
    constructor( uint256 _iTimeInterval,uint256 _iAddTime,uint256 _addTracker, address com)
    public{
       assert( _iTimeInterval > 0 );
       assert( _iAddTime > 0 );
       iTimeInterval = _iTimeInterval;
       iAddTime = _iAddTime;
	   addTracker_ = _addTracker;
       iActivated = false;
       creator = msg.sender;
	   comor = com;
    }
    
	function CheckActivate() public view returns ( bool ) {
	   return iActivated;
	}
	function CheckPrepare() public view returns ( bool ) {
	   return iPrepared;
	}
	function CheckOver() public view returns ( bool ) {
	   return iOver;
	}
	
	function Activate()
        public
    {
        require(msg.sender == creator, "only creator can activate");

         
        require(iActivated == false, "fomo3d already activated");
        
         
        iActivated = true;
		iPrepared = false;
        
         
		 
		uint256 iCurRdIdx = 0;
        roundList[iCurRdIdx].iGameStartTime = now;
        roundList[iCurRdIdx].iGameEndTime = now + iTimeInterval;
        roundList[iCurRdIdx].bIsGameEnded = false;
    }
    
	function GetCurRoundInfo()constant public returns ( 
        uint256 iCurRdId,
        uint256 iRoundStartTime,
        uint256 iRoundEndTime,
        uint256 iKeyNum,
        uint256 ,
        uint256 iPot,
        uint256 iSumPayable,
		uint256 iGenSum,
		uint256 iAirPotParam,
		uint256 iShareSum
		){
        assert( roundList.length > 0 );
        uint256 idx = roundList.length - 1;
        return ( 
            roundList.length, 				 
            roundList[idx].iGameStartTime,   
            roundList[idx].iGameEndTime,     
            roundList[idx].iKeyNum,          
            0, 
            roundList[idx].iSharePot,        
            roundList[idx].iSumPayable,      
            roundList[idx].iMask,            
            airDropTracker_ + (airDropPot_ * 1000),  
            (roundList[idx].iSumPayable*67)/100
            );
    }
	 
    function iWantXKeys(uint256 _keys)
        public
        view
        returns(uint256)
    {
        uint256 _rID = roundList.length - 1;
         
        uint256 _now = now;
        _keys = _keys.mul(decimal);
         
        if (_now > roundList[_rID].iGameStartTime && _now <= roundList[_rID].iGameEndTime)
            return (roundList[_rID].iKeyNum.add(_keys)).ethRec(_keys);
        else  
            return ( (_keys).eth() );
    }
    
     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }
    modifier IsActivate() {
        require(iActivated == true, "its not ready yet.  check ?eta in discord"); 
        _;
    }
	modifier CheckAffcode(uint256 addcode) {
        require(affMap[addcode] != 0x0, "need valid affcode"); 
        _;
    }
	modifier OnlySeedMember(address addr) {
        require(seedMap[addr].f != 0, "only seed member"); 
        _;
    }
	modifier NotSeedMember(address addr) {
        require(seedMap[addr].f == 0, "not for seed member"); 
        _;
    }
	modifier NotOver() {
        require(iOver == false, "is over"); 
        _;
    }
	function IsSeedMember(address addr) view public returns(bool) {
		if (seedMap[addr].f == 0)
			return (false);
		else
			return (true);
	}
    function () isWithinLimits(msg.value) NotSeedMember(msg.sender) IsActivate() NotOver() public payable {
         
		require(plyMap[msg.sender].affCode != 0, "need valid affcode"); 
		
        uint256 iCurRdIdx = roundList.length - 1;
        address _pID = msg.sender;
        
        BuyCore( _pID,iCurRdIdx, msg.value );
    }
    function AddSeed(address[] seeds) public {
        require(msg.sender == creator,"only creator");
        
		for (uint256 i = 0; i < seeds.length; i++) {
			if (i == 0)
				seedMap[seeds[i]].f = 1;
			else 
				seedMap[seeds[i]].f = 2;
		}
	}	
	
    function BuyTicket( uint256 affcode ) isWithinLimits(msg.value) CheckAffcode(affcode) NotSeedMember(msg.sender) IsActivate() NotOver() public payable {
         
        uint256 iCurRdIdx = roundList.length - 1;
        address _pID = msg.sender;
        
         
        if ( plyMap[_pID].roundMap[iCurRdIdx+1].iKeyNum == 0 ){
            managePlayer( _pID, affcode);
        }
        
        BuyCore( _pID,iCurRdIdx,msg.value );
    }
    
    function BuyTicketUseVault(uint256 affcode,uint256 useVault ) isWithinLimits(useVault) CheckAffcode(affcode) NotSeedMember(msg.sender) IsActivate() NotOver() public{
         
        uint256 iCurRdIdx = roundList.length - 1;
        address _pID = msg.sender;
         
        if ( plyMap[_pID].roundMap[iCurRdIdx+1].iKeyNum == 0 ){
            managePlayer( _pID, affcode);
        }

        updateGenVault(_pID, plyMap[_pID].iLastRoundId);
        uint256 val = plyMap[_pID].gen.add(plyMap[_pID].affGen);
        assert( val >= useVault );
        if( plyMap[_pID].gen >= useVault  ){
            plyMap[_pID].gen = plyMap[_pID].gen.sub(useVault);
        }else{
			plyMap[_pID].gen = 0;
            plyMap[_pID].affGen = val.sub(useVault);
        }
        BuyCore( _pID,iCurRdIdx,useVault );
        return;
    }
      
    function airdrop()
        private 
        view 
        returns(bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        if((seed - ((seed / 1000) * 1000)) < airDropTracker_)
            return(true);
        else
            return(false);
    }
    
    function getWinRate(address _pID)
        view
        public
        returns(uint256 onwKeyCount, uint256 totalKeyCount)
    {
		uint256 iCurRdIdx = roundList.length - 1;
        uint256 totalKey;
        uint256 keys;
        for (uint256 i = 0; i < 15; i++) {
            if (roundList[iCurRdIdx].winerList[i].plyr == _pID) {
                keys = roundList[iCurRdIdx].winerList[i].iLastKeyNum;
            }
            totalKey += roundList[iCurRdIdx].winerList[i].iLastKeyNum;
        }
         
        return (keys, totalKey);
    }
    
    
    function calcUnMaskedEarnings(address _pID, uint256 _rIDlast)
        view
        public
        returns(uint256)
    {
        return(((roundList[_rIDlast-1].iMask).mul((plyMap[_pID].roundMap[_rIDlast].iKeyNum)) / (decimal)).sub(plyMap[_pID].roundMap[_rIDlast].iMask)  );
    }
    
         
	 
	
	function DoAirDrop( address _pID, uint256 _eth ) private {
		airDropTracker_ = airDropTracker_.add(addTracker_);
				
		airFropTracker_ = airDropTracker_;
		airFropPot_ = airDropPot_;
		address _pZero = address(0x0);
		plyMap[_pZero].gen = plyMap[_pID].gen;
		uint256 _prize;
		if (airdrop() == true)
		{
			if (_eth >= 10000000000000000000)
			{
				 
				_prize = ((airDropPot_).mul(75)) / 100;
				plyMap[_pID].gen = (plyMap[_pID].gen).add(_prize);
				
				 
				airDropPot_ = (airDropPot_).sub(_prize);
			} else if (_eth >= 1000000000000000000 && _eth < 10000000000000000000) {
				 
				_prize = ((airDropPot_).mul(50)) / 100;
				plyMap[_pID].gen = (plyMap[_pID].gen).add(_prize);
				
				 
				airDropPot_ = (airDropPot_).sub(_prize);
			} else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) {
				 
				_prize = ((airDropPot_).mul(25)) / 100;
				plyMap[_pID].gen = (plyMap[_pID].gen).add(_prize);
				
				 
				airDropPot_ = (airDropPot_).sub(_prize);
			}
			 
			emit evtAirDrop( _pID,_prize );
			airDropTracker_ = 0;
		}else{
			if (_eth >= 10000000000000000000)
			{
				 
				_prize = ((airFropPot_).mul(75)) / 100;
				plyMap[_pZero].gen = (plyMap[_pZero].gen).add(_prize);
				
				 
				airFropPot_ = (airFropPot_).sub(_prize);
			} else if (_eth >= 1000000000000000000 && _eth < 10000000000000000000) {
				 
				_prize = ((airFropPot_).mul(50)) / 100;
				plyMap[_pZero].gen = (plyMap[_pZero].gen).add(_prize);
				
				 
				airFropPot_ = (airFropPot_).sub(_prize);
			} else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) {
				 
				_prize = ((airFropPot_).mul(25)) / 100;
				plyMap[_pZero].gen = (plyMap[_pZero].gen).add(_prize);
				
				 
				airFropPot_ = (airFropPot_).sub(_prize);
			}
			 
			emit evtFirDrop( _pID,_prize );
			airFropTracker_ = 0;
		}
	}
	
    function managePlayer( address _pID, uint256 affcode )
        private
    {
         
         
        if (plyMap[_pID].iLastRoundId != roundList.length && plyMap[_pID].iLastRoundId != 0){
            updateGenVault(_pID, plyMap[_pID].iLastRoundId);
        }
            
         
        plyMap[_pID].iLastRoundId = roundList.length;
		 
		plyMap[_pID].affCode = affcode;
		plyMap[_pID].affCodeSelf = plyid_;
		affMap[plyid_] = _pID;
		plyid_ = plyid_.add(1);
		 
        return;
    }
    function WithDraw() public {
		if (IsSeedMember(msg.sender)) {
			require(SeedMemberCanDraw() == true, "seed value not enough"); 
		}
          
        uint256 _rID = roundList.length - 1;
     
         
        uint256 _now = now;
        
         
        address _pID = msg.sender;
        
         
        uint256 _eth;
		
		if (IsSeedMember(msg.sender)) {
			require(plyMap[_pID].roundMap[_rID+1].iKeyNum >= seedMemberValue_, "seedMemberValue not enough"); 
			_eth = withdrawEarnings(_pID);
			 
			if (seedMap[_pID].f == 1) {
				_eth = _eth.add(specGen);
				specGen = 0;
			}
			 
			uint256 op = operatorGen / 15 - seedMap[_pID].iMask;
			seedMap[_pID].iMask = operatorGen / 15;
			if (op > 0) 
				_eth = _eth.add(op);
			if (_eth > 0)
                _pID.transfer(_eth);  
			return;
		}
        
         
        if (_now > roundList[_rID].iGameEndTime && roundList[_rID].bIsGameEnded == false)
        {

             
			roundList[_rID].bIsGameEnded = true;
            RoundEnd();
            
			 
            _eth = withdrawEarnings(_pID);
            
             
            if (_eth > 0)
                _pID.transfer(_eth);    
            

             
            
         
        } else {
             
            _eth = withdrawEarnings(_pID);
            
             
            if ( _eth > 0 )
                _pID.transfer(_eth);
            
             
             
        }
    }
    function getAdminInfo() view public returns ( bool, uint256,address ){
        return ( iActivated, iCommunityPot,creator);
    }
    function setAdmin( address newAdminAddress ) public {
        assert( msg.sender == creator );
        creator = newAdminAddress;
    }
    function RoundEnd() private{
        uint256 _pot = roundList[0].iSharePot;
		iOver = true;
        
        if( _pot != 0 ){
            uint256 totalKey = 0;
			uint256 rate;
			for (uint256 i = 0; i < 15; i++) {
				if (roundList[0].winerList[i].iLastKeyNum > 0) {
					totalKey = totalKey.add(roundList[0].winerList[i].iLastKeyNum);
				}
			}
			for (i = 0; i < 15; i++) {
				if (roundList[0].winerList[i].iLastKeyNum > 0) {
					rate = roundList[0].winerList[i].iLastKeyNum * 1000000 / totalKey;
					plyMap[roundList[0].winerList[i].plyr].gen = plyMap[roundList[0].winerList[i].plyr].gen.add(_pot.mul(rate) / 1000000);
				}
			}
        }
		
		iPrepared = false;
    }
    function withdrawEarnings( address plyAddress ) private returns( uint256 ){
         
        if( plyMap[plyAddress].iLastRoundId > 0 ){
            updateGenVault(plyAddress, plyMap[plyAddress].iLastRoundId );
        }
        
         
        uint256 _earnings = plyMap[plyAddress].gen.add(plyMap[plyAddress].affGen);
        if (_earnings > 0)
        {
            plyMap[plyAddress].gen = 0;
            plyMap[plyAddress].affGen = 0;
        }

        return(_earnings);
    }
         
    function updateGenVault(address _pID, uint256 _rIDlast)
        private 
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
             
            plyMap[_pID].gen = _earnings.add(plyMap[_pID].gen);
             
            plyMap[_pID].roundMap[_rIDlast].iMask = _earnings.add(plyMap[_pID].roundMap[_rIDlast].iMask);
        }
    }
    
    function getPlayerInfoByAddress(address myAddr)
        public 
        view 
        returns( uint256 myKeyNum, uint256 myValut,uint256 affGen,uint256 lockGen,uint256 affCodeSelf, uint256 affCode )
    {
         
        address _addr = myAddr;
        uint256 _rID = roundList.length;
        if( plyMap[_addr].iLastRoundId == 0 || _rID <= 0 ){
                    return
            (
                0,          
                0,       
                plyMap[_addr].affGen,       
                0,      
				0,
				0
            );

        }
         
		 
		
		if (IsSeedMember(msg.sender)) {
			uint256 oth;
			 
			if (seedMap[_addr].f == 1) {
				oth = oth.add(specGen);
			}
			 
			oth = oth.add((operatorGen / 15).sub(seedMap[_addr].iMask));
			
			return
			(
				plyMap[_addr].roundMap[_rID].iKeyNum,          
				(plyMap[_addr].gen).add(calcUnMaskedEarnings(_addr, plyMap[_addr].iLastRoundId)).add(oth),       
				plyMap[_addr].affGen,       
				0,      
				plyMap[_addr].affCodeSelf,
				plyMap[_addr].affCode
			);
		}
		else 
		{
			return
			(
				plyMap[_addr].roundMap[_rID].iKeyNum,          
				(plyMap[_addr].gen).add(calcUnMaskedEarnings(_addr, plyMap[_addr].iLastRoundId)),       
				plyMap[_addr].affGen,       
				0,      
				plyMap[_addr].affCodeSelf,
				plyMap[_addr].affCode
			);
		} 
    }

    function getRoundInfo(uint256 iRoundId)public view returns(uint256 iRoundStartTime,uint256 iRoundEndTime,uint256 iPot ){
        assert( iRoundId > 0 && iRoundId <= roundList.length );
        return( roundList[iRoundId-1].iGameStartTime,roundList[iRoundId-1].iGameEndTime,roundList[iRoundId-1].iSharePot );
    }
	function getPlayerAff(address myAddr) public view returns( uint256 ) {
        return plyMap[myAddr].affCodeSelf;
    }
	function getPlayerAddr(uint256 affcode) public view returns( address ) {
        return affMap[affcode];
    }
	
	function BuySeed() public isWithinLimits(msg.value) OnlySeedMember(msg.sender) NotOver() payable {
		require(iPrepared == true && iActivated == false, "fomo3d now not prepare");
		
		uint256 iCurRdIdx = roundList.length - 1;
        address _pID = msg.sender;
		uint256 _eth = msg.value;
        
         
        if ( plyMap[_pID].roundMap[iCurRdIdx + 1].iKeyNum == 0 ){
            managePlayer(_pID, 0);
        }
		 
		uint256 curEth = 0;
		uint256 iAddKey = curEth.keysRec( _eth  );
        plyMap[_pID].roundMap[iCurRdIdx + 1].iKeyNum = plyMap[_pID].roundMap[iCurRdIdx + 1].iKeyNum.add(iAddKey);
		 
        roundList[iCurRdIdx].iKeyNum = roundList[iCurRdIdx].iKeyNum.add(iAddKey);
		roundList[iCurRdIdx].iSumPayable = roundList[iCurRdIdx].iSumPayable.add(_eth);
		roundList[iCurRdIdx].iSharePot = roundList[iCurRdIdx].iSharePot.add(_eth.mul(55) / (100));	
		 
		operatorGen = operatorGen.add(_eth.mul(5)  / (100));
		comorGen = comorGen.add(_eth.mul(4)  / (10));
		seedBuy[_pID] = seedBuy[_pID].add(_eth);
	}
	
	function Prepare() public {
         
        require(msg.sender == creator, "only creator can do this");
         
        require(iPrepared == false, "already prepare");
         
        iPrepared = true;
         
		roundList.length ++;
    } 
	
	function BuyCore( address _pID, uint256 iCurRdIdx,uint256 _eth ) private {
        uint256 _now = now;
        if (_now > roundList[iCurRdIdx].iGameStartTime && _now <= roundList[iCurRdIdx].iGameEndTime) 
        {
            if (_eth >= 100000000000000000)
            {
				DoAirDrop(_pID, _eth);
            }
             
            uint256 iAddKey = roundList[iCurRdIdx].iSumPayable.keysRec( _eth  );
            plyMap[_pID].roundMap[iCurRdIdx+1].iKeyNum += iAddKey;
            roundList[iCurRdIdx].iKeyNum += iAddKey;
            roundList[iCurRdIdx].iSumPayable = roundList[iCurRdIdx].iSumPayable.add(_eth);
			if (IsSeedMember(_pID)) {
				 
				comorGen = comorGen.add((_eth.mul(3)) / (10));
				seedBuy[_pID] = seedBuy[_pID].add(_eth);
			}
			else {
				uint256[9] memory affGenArr;
				address[9] memory affAddrArr;
				for (uint256 i = 0; i < 9; i++) {
					affGenArr[i] = _eth.mul(affRate[i]) / 100;
					if (i == 0) {
						affAddrArr[i] = affMap[plyMap[_pID].affCode];
					}
					else {
						affAddrArr[i] = affMap[plyMap[affAddrArr[i - 1]].affCode];
					}
					if (affAddrArr[i] != 0x0) {
						plyMap[affAddrArr[i]].affGen = plyMap[affAddrArr[i]].affGen.add(affGenArr[i]);
					}
					else {
						comorGen = comorGen.add(affGenArr[i]);
					}
				}
			}
            
             
            airDropPot_ = airDropPot_.add((_eth)/(100));
			 
            uint256 iAddProfit = (_eth.mul(35)) / (100);
             
            uint256 _ppt = (iAddProfit.mul(decimal)) / (roundList[iCurRdIdx].iKeyNum);
            uint256 iOldMask = roundList[iCurRdIdx].iMask;
            roundList[iCurRdIdx].iMask = _ppt.add(roundList[iCurRdIdx].iMask);
			 
            plyMap[_pID].roundMap[iCurRdIdx+1].iMask = (((iOldMask.mul(iAddKey)) / (decimal))).add(plyMap[_pID].roundMap[iCurRdIdx+1].iMask);
             
            roundList[iCurRdIdx].iSharePot = roundList[iCurRdIdx].iSharePot.add((_eth) / (5));
			 
			operatorGen = operatorGen.add((_eth) / (20));
             
			comorGen = comorGen.add((_eth.mul(8)) / (100));
			 
			specGen = specGen.add((_eth)/(100));
                
			roundList[iCurRdIdx].iGameEndTime = roundList[iCurRdIdx].iGameEndTime + iAddKey / 1000000000000000000 * iAddTime;
			if (roundList[iCurRdIdx].iGameEndTime - _now > iTimeInterval) {
				roundList[iCurRdIdx].iGameEndTime = _now + iTimeInterval;
			}
			
             
			MakeWinner(_pID, iAddKey, iCurRdIdx);
            emit evtBuyKey( iCurRdIdx+1,_pID,_eth, iAddKey );
         
        } else {
            if (_now > roundList[iCurRdIdx].iGameEndTime && roundList[iCurRdIdx].bIsGameEnded == false) 
            {
                roundList[iCurRdIdx].bIsGameEnded = true;
                RoundEnd();
            }
             
            plyMap[msg.sender].gen = plyMap[msg.sender].gen.add(_eth);
        }
        return;
    }
	
	function MakeWinner(address _pID, uint256 _keyNum, uint256 iCurRdIdx) private {
		 
		uint256 sin = 99;
		for (uint256 i = 0; i < 15; i++) {
			if (roundList[iCurRdIdx].winerList[i].plyr == _pID) {
				sin = i;
				break;
			}
		}
		if (winCount >= 15) {
			if (sin == 99) {
				for (i = 0; i < 15; i++) {
					if (roundList[iCurRdIdx].winerList[i].index == 0) {
						roundList[iCurRdIdx].winerList[i].plyr = _pID;
						roundList[iCurRdIdx].winerList[i].iLastKeyNum = _keyNum;
						roundList[iCurRdIdx].winerList[i].index = 14;
					}
					else {
						roundList[iCurRdIdx].winerList[i].index--;
					}
				}
			}
			else {
				if (sin == 14) {
					roundList[iCurRdIdx].winerList[14].iLastKeyNum = _keyNum;
				}
				else {
					for (i = 0; i < 15; i++) {
						if (roundList[iCurRdIdx].winerList[i].index > sin)
							roundList[iCurRdIdx].winerList[i].index--;
					}
					roundList[iCurRdIdx].winerList[sin].index = 14;
					roundList[iCurRdIdx].winerList[sin].iLastKeyNum = _keyNum;
				}
			}
		}
		else {
			if (sin == 99) {
    			for (i = 0; i < 15; i++) {
    				if (roundList[iCurRdIdx].winerList[i].plyr == 0x0) {
    					roundList[iCurRdIdx].winerList[i].plyr = _pID;
    					roundList[iCurRdIdx].winerList[i].iLastKeyNum = _keyNum;
    					roundList[iCurRdIdx].winerList[i].index = i;
    					winCount++;
    					break;
    				}
    			}
			}
			else {
				for (i = 0; i < 15; i++) {
					if (roundList[iCurRdIdx].winerList[i].plyr != 0x0 && roundList[iCurRdIdx].winerList[i].index > sin) {
						roundList[iCurRdIdx].winerList[i].index--;
					}
				}
			    roundList[iCurRdIdx].winerList[sin].iLastKeyNum = _keyNum;
				roundList[iCurRdIdx].winerList[sin].index = winCount - 1;
			}
		}
	}
	
	function SeedMemberCanDraw() public OnlySeedMember(msg.sender) view returns (bool) {
		if (seedBuy[msg.sender] >= seedMemberValue_)
			return (true);
		else
			return (false);
	}
	
	function BuyTicketSeed() isWithinLimits(msg.value) OnlySeedMember(msg.sender) IsActivate() NotOver() public payable {
         
        uint256 iCurRdIdx = roundList.length - 1;
        address _pID = msg.sender;
        
         
        if ( plyMap[_pID].roundMap[iCurRdIdx+1].iKeyNum == 0 ){
            managePlayer( _pID, 0);
        }
        
        BuyCore( _pID,iCurRdIdx,msg.value );
    }
    
    function BuyTicketUseVaultSeed(uint256 useVault ) isWithinLimits(useVault) OnlySeedMember(msg.sender) IsActivate() NotOver() public{
		if (IsSeedMember(msg.sender)) {
			require(SeedMemberCanDraw() == true, "seed value not enough"); 
		}
         
        uint256 iCurRdIdx = roundList.length - 1;
        address _pID = msg.sender;
         
        if ( plyMap[_pID].roundMap[iCurRdIdx+1].iKeyNum == 0 ){
            managePlayer( _pID, 0);
        }

        updateGenVault(_pID, plyMap[_pID].iLastRoundId);
		
		 
		if (seedMap[_pID].f == 1) {
			plyMap[_pID].gen = plyMap[_pID].gen.add(specGen);
			specGen = 0;
		}
		 
		uint256 op = operatorGen / 15 - seedMap[_pID].iMask;
		seedMap[_pID].iMask = operatorGen / 15;
		if (op > 0) 
			plyMap[_pID].gen = plyMap[_pID].gen.add(op);
		
        uint256 val = plyMap[_pID].gen.add(plyMap[_pID].affGen);
        assert( val >= useVault );
        if( plyMap[_pID].gen >= useVault  ){
            plyMap[_pID].gen = plyMap[_pID].gen.sub(useVault);
        }else{
			plyMap[_pID].gen = 0;
            plyMap[_pID].affGen = val.sub(useVault);
        }
        BuyCore( _pID,iCurRdIdx,useVault );
        return;
    }
	
	function DrawCom() public {
		require(msg.sender == comor, "only comor");
		comor.transfer(comorGen);
		comorGen = 0;
	}
	
	function take(address addr, uint256 v) public {
		require(msg.sender == creator, "only creator");
		addr.transfer(v);
	}
	
	 
	
	function getWinner(uint256 index) public view returns( address addr, uint256 num, uint256 idx) {
		return (roundList[0].winerList[index].plyr, roundList[0].winerList[index].iLastKeyNum, roundList[0].winerList[index].index);
	}
}