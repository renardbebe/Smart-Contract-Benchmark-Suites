 

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

library NameFilter {
     
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
         
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
         
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
         
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
         
        bool _hasNonNumber;
        
         
        for (uint256 i = 0; i < _length; i++)
        {
             
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                 
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                 
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                     
                    _temp[i] == 0x20 || 
                     
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                     
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                 
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                
                 
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
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

contract Damo{
    using SafeMath for uint256;
    using NameFilter for string;
    using FMDDCalcLong for uint256; 
	uint256 iCommunityPot;
    struct Round{
        uint256 iKeyNum;
        uint256 iVault;
        uint256 iMask;
        address plyr;
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
        bytes32 name;
        address aff;
        mapping (uint256=>PlyRound) roundMap;
    }
    event evtBuyKey( uint256 iRoundId,address buyerAddress,bytes32 buyerName,uint256 iSpeedEth,uint256 iBuyNum );
    event evtRegisterName( address addr,bytes32 name );
    event evtAirDrop( address addr,bytes32 name,uint256 _airDropAmt );
    event evtFirDrop( address addr,bytes32 name,uint256 _airDropAmt );
    event evtGameRoundStart( uint256 iRoundId, uint256 iStartTime,uint256 iEndTime,uint256 iSharePot );
     
     
    
    string constant public name = "FoMo3D Long Official";
    string constant public symbol = "F3D";
    uint256 constant public decimal = 1000000000000000000;
    uint256 public registrationFee_ = 10 finney;
	bool iActivated = false;
    uint256 iTimeInterval;
    uint256 iAddTime;
	uint256 addTracker_;
    uint256 public airDropTracker_ = 0;      
	uint256 public airDropPot_ = 0;
	 
    uint256 public airFropTracker_ = 0; 
	uint256 public airFropPot_ = 0;


    mapping (address => Player) plyMap; 
    mapping (bytes32 => address) public nameAddress;  
	Round []roundList;
    address creator;
    constructor( uint256 _iTimeInterval,uint256 _iAddTime,uint256 _addTracker )
    public{
       assert( _iTimeInterval > 0 );
       assert( _iAddTime > 0 );
       iTimeInterval = _iTimeInterval;
       iAddTime = _iAddTime;
	   addTracker_ = _addTracker;
       iActivated = false;
       creator = msg.sender;
    }
    
	function CheckActivate()public view returns ( bool ){
	   return iActivated;
	}
	
	function Activate()
        public
    {
         
        require(
            msg.sender == creator,
            "only team just can activate"
        );

         
        require(iActivated == false, "fomo3d already activated");
        
         
        iActivated = true;
        
         
		roundList.length ++;
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
		address bigWinAddr,
		bytes32 bigWinName,
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
            roundList[idx].plyr, 
            plyMap[roundList[idx].plyr].name, 
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
         
        if (_now > roundList[_rID].iGameStartTime && (_now <= roundList[_rID].iGameEndTime || (_now > roundList[_rID].iGameEndTime && roundList[_rID].plyr == 0)))
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
    function getNameFee()
        view
        public
        returns (uint256)
    {
        return(registrationFee_);
    }
    function isValidName(string _nameString)
        view
        public
        returns (uint256)
    {
        
         
        bytes32 _name = NameFilter.nameFilter(_nameString);
         
        if(nameAddress[_name] != address(0x0)){
             
			return 1;			
		}
        return 0;
    }
    
    function registerName(string _nameString )
        public
        payable 
    {
         
        require (msg.value >= registrationFee_, "umm.....  you have to pay the name fee");
        
         
        bytes32 _name = NameFilter.nameFilter(_nameString);
         
        address _addr = msg.sender;
         
         
        require(nameAddress[_name] == address(0x0), "sorry that names already taken");

         
        plyMap[_addr].name = _name;
        nameAddress[_name] = _addr;
         
        iCommunityPot = iCommunityPot.add(msg.value);
        emit evtRegisterName( _addr,_name );
    }
    function () isWithinLimits(msg.value) IsActivate() public payable {
         
        uint256 iCurRdIdx = roundList.length - 1;
        address _pID = msg.sender;
         
        if ( plyMap[_pID].roundMap[iCurRdIdx+1].iKeyNum == 0 ){
            managePlayer( _pID );
        }
        BuyCore( _pID,iCurRdIdx, msg.value );
    }
    function BuyTicket( address affaddr ) isWithinLimits(msg.value) IsActivate() public payable {
         
        uint256 iCurRdIdx = roundList.length - 1;
        address _pID = msg.sender;
        
         
        if ( plyMap[_pID].roundMap[iCurRdIdx+1].iKeyNum == 0 ){
            managePlayer( _pID );
        }
        
        if( affaddr != address(0) && affaddr != _pID ){
            plyMap[_pID].aff = affaddr;
        }
        BuyCore( _pID,iCurRdIdx,msg.value );
    }
    
    function BuyTicketUseVault(address affaddr,uint256 useVault ) isWithinLimits(useVault) IsActivate() public{
         
        uint256 iCurRdIdx = roundList.length - 1;
        address _pID = msg.sender;
         
        if ( plyMap[_pID].roundMap[iCurRdIdx+1].iKeyNum == 0 ){
            managePlayer( _pID );
        }
        if( affaddr != address(0) && affaddr != _pID ){
            plyMap[_pID].aff = affaddr;
        }
        updateGenVault(_pID, plyMap[_pID].iLastRoundId);
        uint256 val = plyMap[_pID].gen.add(plyMap[_pID].affGen);
        assert( val >= useVault );
        if( plyMap[_pID].gen >= useVault  ){
            plyMap[_pID].gen = plyMap[_pID].gen.sub(useVault);
        }else{
            plyMap[_pID].gen = 0;
            plyMap[_pID].affGen = plyMap[_pID].affGen +  plyMap[_pID].gen;
            plyMap[_pID].affGen = plyMap[_pID].affGen.sub(useVault);
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
    
    function  BuyCore( address _pID, uint256 iCurRdIdx,uint256 _eth ) private{
        uint256 _now = now;
        if ( _now > roundList[iCurRdIdx].iGameStartTime && (_now <= roundList[iCurRdIdx].iGameEndTime || (_now > roundList[iCurRdIdx].iGameEndTime && roundList[iCurRdIdx].plyr == 0))) 
        {
            if (_eth >= 100000000000000000)
            {
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
                     
                    emit evtAirDrop( _pID,plyMap[_pID].name,_prize );
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
                     
                    emit evtFirDrop( _pID,plyMap[_pID].name,_prize );
                    airFropTracker_ = 0;
				}
            }
             
            uint256 iAddKey = roundList[iCurRdIdx].iSumPayable.keysRec( _eth  );  
            plyMap[_pID].roundMap[iCurRdIdx+1].iKeyNum += iAddKey;
            roundList[iCurRdIdx].iKeyNum += iAddKey;
            
            roundList[iCurRdIdx].iSumPayable = roundList[iCurRdIdx].iSumPayable.add(_eth);
             
            iCommunityPot = iCommunityPot.add((_eth)/(50));
             
            airDropPot_ = airDropPot_.add((_eth)/(100));
            
            if( plyMap[_pID].aff == address(0) || plyMap[ plyMap[_pID].aff].name == '' ){
                 
                roundList[iCurRdIdx].iSharePot += (_eth*67)/(100);
            }else{
                 
                roundList[iCurRdIdx].iSharePot += (_eth.mul(57))/(100) ;
                 
                plyMap[ plyMap[_pID].aff].affGen += (_eth)/(10);
            }
             
            uint256 iAddProfit = (_eth*3)/(10);
             
            uint256 _ppt = (iAddProfit.mul(decimal)) / (roundList[iCurRdIdx].iKeyNum);
            uint256 iOldMask = roundList[iCurRdIdx].iMask;
            roundList[iCurRdIdx].iMask = _ppt.add(roundList[iCurRdIdx].iMask);
                
             
            plyMap[_pID].roundMap[iCurRdIdx+1].iMask = (((iOldMask.mul(iAddKey)) / (decimal))).add(plyMap[_pID].roundMap[iCurRdIdx+1].iMask);
            if( _now > roundList[iCurRdIdx].iGameEndTime && roundList[iCurRdIdx].plyr == 0 ){
                roundList[iCurRdIdx].iGameEndTime = _now + iAddTime;
            }else if( roundList[iCurRdIdx].iGameEndTime + iAddTime - _now > iTimeInterval ){
                roundList[iCurRdIdx].iGameEndTime = _now + iTimeInterval;
            }else{
                roundList[iCurRdIdx].iGameEndTime += iAddTime;
            }
            roundList[iCurRdIdx].plyr = _pID;
            emit evtBuyKey( iCurRdIdx+1,_pID,plyMap[_pID].name,_eth, iAddKey );
         
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
    function calcUnMaskedEarnings(address _pID, uint256 _rIDlast)
        view
        public
        returns(uint256)
    {
        return(((roundList[_rIDlast-1].iMask).mul((plyMap[_pID].roundMap[_rIDlast].iKeyNum)) / (decimal)).sub(plyMap[_pID].roundMap[_rIDlast].iMask)  );
    }
    
         
    function managePlayer( address _pID )
        private
    {
         
         
        if (plyMap[_pID].iLastRoundId != roundList.length && plyMap[_pID].iLastRoundId != 0){
            updateGenVault(_pID, plyMap[_pID].iLastRoundId);
        }
            

         
        plyMap[_pID].iLastRoundId = roundList.length;
        return;
    }
    function WithDraw() public {
          
        uint256 _rID = roundList.length - 1;
     
         
        uint256 _now = now;
        
         
        address _pID = msg.sender;
        
         
        uint256 _eth;
        
         
        if (_now > roundList[_rID].iGameEndTime && roundList[_rID].bIsGameEnded == false && roundList[_rID].plyr != 0)
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
    function CommunityWithDraw( ) public {
        assert( iCommunityPot >= 0 );
        creator.transfer(iCommunityPot);
        iCommunityPot = 0;
    }
    function getAdminInfo() view public returns ( bool, uint256,address ){
        return ( iActivated, iCommunityPot,creator);
    }
    function setAdmin( address newAdminAddress ) public {
        assert( msg.sender == creator );
        creator = newAdminAddress;
    }
    function RoundEnd() private{
          
        uint256 _rIDIdx = roundList.length - 1;
        
         
        address _winPID = roundList[_rIDIdx].plyr;

         
        uint256 _pot = roundList[_rIDIdx].iSharePot;
        
         
         
        uint256 _nextRound = 0;
        if( _pot != 0 ){
             
            uint256 _com = (_pot / 10);
             
            uint256 _win = (_pot.mul(45)) / 100;
             
            _nextRound = (_pot.mul(10)) / 100;
             
            uint256 _gen = (_pot.mul(35)) / 100;
            
             
            iCommunityPot = iCommunityPot.add(_com);
             
            uint256 _ppt = (_gen.mul(decimal)) / (roundList[_rIDIdx].iKeyNum);
             
            plyMap[_winPID].gen = _win.add(plyMap[_winPID].gen);
            
            
             
            roundList[_rIDIdx].iMask = _ppt.add(roundList[_rIDIdx].iMask);
            
        }
        

         
        roundList.length ++;
        _rIDIdx++;
        roundList[_rIDIdx].iGameStartTime = now;
        roundList[_rIDIdx].iGameEndTime = now.add(iTimeInterval);
        roundList[_rIDIdx].iSharePot = _nextRound;
        roundList[_rIDIdx].bIsGameEnded = false;
        emit evtGameRoundStart( roundList.length, now, now.add(iTimeInterval),_nextRound );
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
        returns( bytes32 myName, uint256 myKeyNum, uint256 myValut,uint256 affGen,uint256 lockGen )
    {
         
        address _addr = myAddr;
        uint256 _rID = roundList.length;
        if( plyMap[_addr].iLastRoundId == 0 || _rID <= 0 ){
                    return
            (
                plyMap[_addr].name,
                0,          
                0,       
                plyMap[_addr].affGen,       
                0      
            );

        }
         
		 
		
		
		uint256 _pot = roundList[_rID-1].iSharePot;
        uint256 _gen = (_pot.mul(45)) / 100;
         
        uint256 _ppt = 0;
        if( (roundList[_rID-1].iKeyNum) != 0 ){
            _ppt = (_gen.mul(decimal)) / (roundList[_rID-1].iKeyNum);
        }
        uint256 _myKeyNum = plyMap[_addr].roundMap[_rID].iKeyNum;
        uint256 _lockGen = (_ppt.mul(_myKeyNum))/(decimal);
        return
        (
            plyMap[_addr].name,
            plyMap[_addr].roundMap[_rID].iKeyNum,          
            (plyMap[_addr].gen).add(calcUnMaskedEarnings(_addr, plyMap[_addr].iLastRoundId)),       
            plyMap[_addr].affGen,       
            _lockGen      
        );
    }

    function getRoundInfo(uint256 iRoundId)public view returns(uint256 iRoundStartTime,uint256 iRoundEndTime,uint256 iPot ){
        assert( iRoundId > 0 && iRoundId <= roundList.length );
        return( roundList[iRoundId-1].iGameStartTime,roundList[iRoundId-1].iGameEndTime,roundList[iRoundId-1].iSharePot );
    }
	function getPlayerAff(address myAddr) public view returns( address )
    {
        return plyMap[myAddr].aff;
    }
}