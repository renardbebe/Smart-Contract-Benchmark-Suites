 

pragma solidity ^0.4.25;

contract FOMOEvents {
     
    event onNewName
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        bytes32 indexed playerName,
        bool isNewPlayer,
        uint256 affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 amountPaid,
        uint256 timeStamp
    );

     
    event onEndTx
    (
        uint256 compressedData,
        uint256 compressedIDs,
        bytes32 playerName,
        address playerAddress,
        uint256 ethIn,
        uint256 keysBought,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 tokenAmount,
        uint256 genAmount,
        uint256 potAmount,
        uint256 seedAdd
    );

     
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timeStamp
    );

     
    event onWithdrawAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 tokenAmount,
        uint256 genAmount,
        uint256 seedAdd
    );

     
     
    event onBuyAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethIn,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 tokenAmount,
        uint256 genAmount,
        uint256 seedAdd
    );

     
     
    event onReLoadAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 tokenAmount,
        uint256 genAmount,
        uint256 seedAdd
    );

     
    event onAffiliatePayout
    (
        uint256 indexed affiliateID,
        address affiliateAddress,
        bytes32 affiliateName,
        uint256 indexed roundID,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );
}

 
 
 
 

contract FFEIF is FOMOEvents {
    using SafeMath for *;
    using NameFilter for string;
   
    PlayerBookInterface  private PlayerBook;

 
 
 
 
    PoEIF public PoEIFContract;
    address private admin = msg.sender;
    string constant public name = "Fomo Forever EIF";
    string constant public symbol = "FFEIF";
    uint256 private rndExtra_ = 1 minutes;      
    uint256 public rndGap_ = 1 minutes;         
    uint256 public rndInit_ = 60 minutes;       
    uint256 public rndInc_ = 1 seconds;         
    uint256 public rndIncDivisor_ = 1;          
	
	uint256 public potSeedRate = 100;		    
	uint256 public potNextSeedTime = 0;         
	uint256 public seedingPot  = 0;             
	uint256 public seedingThreshold = 0 ether;  
	uint256 public seedingDivisor = 2;          
	uint256 public seedRoundEnd = 1;            
	
	uint256 public linearPrice = 75000000000000;             
	
	uint256 public multPurchase = 0;	       
	uint256 public multAllowLast = 1;          
	uint256 public multLinear = 2;             
	                                           
	
	uint256 public maxMult = 1000000;		   
	uint256 public multInc_ = 0;               
											   
											   
	uint256 public multIncFactor_ = 10;		   
	uint256 public multLastChange = now;       
	uint256 public multDecayPerMinute = 1;     
											   
	uint256 public multStart = 24 hours;        
	uint256 public multCurrent = 10;	       
	
    uint256 public rndMax_ = 24 hours;       
    uint256 public earlyRoundLimit = 1e18;         
    uint256 public earlyRoundLimitUntil = 100e18;  
    
    uint256 public divPercentage = 65;         
    uint256 public affFee = 5;                 
    uint256 public potPercentage = 20;         
    
    uint256 public divPotPercentage = 15;      
    uint256 public nextRoundPercentage = 25;   
    uint256 public winnerPercentage = 50;      
    
    uint256 public fundEIF = 0;                
    uint256 public totalEIF = 0;               
    uint256 public seedDonated = 0;            
    address public FundEIF = 0x0111E8A755a4212E6E1f13e75b1EABa8f837a213;  
    


 
 
 
 
    uint256 public rID_;     
 
 
 
    mapping (address => uint256) public pIDxAddr_;           
    mapping (bytes32 => uint256) public pIDxName_;           
    mapping (uint256 => FFEIFDatasets.Player) public plyr_;    
    mapping (uint256 => mapping (uint256 => FFEIFDatasets.PlayerRounds)) public plyrRnds_;     
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;  
 
 
 
    mapping (uint256 => FFEIFDatasets.Round) public round_;    
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;       
 
 
 
    mapping (uint256 => FFEIFDatasets.TeamFee) public fees_;           
    mapping (uint256 => FFEIFDatasets.PotSplit) public potSplit_;      
 
 
 
 
    constructor()
        public
    {
        PoEIFContract = PoEIF(0xFfB8ccA6D55762dF595F21E78f21CD8DfeadF1C8);
        PlayerBook = PlayerBookInterface(0xd80e96496cd0B3F95bB4941b1385023fBCa1E6Ba);
        
    }

 
 
 
 
    
function updateFundAddress(address _newAddress)
        onlyAdmin()
        public
    {
        FundEIF = _newAddress;
    }


     
    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        view
        returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }

     
    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        view
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

     
    function keys(uint256 _eth)
        internal
        view
        returns(uint256)
    {
        if (linearPrice==0)
        {return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);}
        else
        {return 1e18.mul(_eth) / linearPrice;}
    }

     
    function eth(uint256 _keys)
        internal
        view
        returns(uint256)
    {
         if (linearPrice==0)
        {return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());}
        else
        {return _keys.mul(linearPrice)/1e18;}
    }


function payFund() public {    
    if(!FundEIF.call.value(fundEIF)()) {
        revert();
    }
    totalEIF = totalEIF.add(fundEIF); fundEIF = 0; 
}


function calcMult(uint256 keysBought, bool validIncrease) internal returns (bool)
{
    uint256 _now = now;  
	uint256 secondsPassed = _now - multLastChange;
	
	 
	bool thresholdReached = (multStart > round_[rID_].end - _now);
	
	 
	 
	bool currentlyLinear = false;
	if (multLinear == 1 || (multLinear == 2 && !thresholdReached)) { currentlyLinear = true; multLastChange = _now;}
	else  multLastChange = multLastChange.add((secondsPassed/60).mul(60));  
	 
	
	 
	if (multCurrent >= 10) {
	    if (currentlyLinear) multCurrent = (multCurrent.mul(10).sub(multDecayPerMinute.mul(secondsPassed).mul(100)/60))/10; else multCurrent = multCurrent / (1+(multDecayPerMinute.mul(secondsPassed)/60));
		if (multCurrent < 10) multCurrent = 10;
	}
	
	
	 
	bool returnValue = ((keysBought / 1e17) >= multCurrent);
	
	 
	if ((thresholdReached || multLinear == 2) && validIncrease) {
	    uint256 wholeKeysBought = keysBought / 1e18;
	    uint256 actualMultInc = multIncFactor_.mul(wholeKeysBought);
	    if (multInc_ != 0) actualMultInc = multInc_;
	    
	     
	    if ((wholeKeysBought >= multPurchase && multPurchase > 0) || ((wholeKeysBought >= (multCurrent / 10)) && multPurchase == 0) ) {  
	     
	        if (currentlyLinear) multCurrent = multCurrent.add(actualMultInc); else multCurrent = multCurrent.mul((1+(actualMultInc/10)));
	        if (multCurrent > maxMult) multCurrent = maxMult;
	    }
    }
	
	return returnValue;
	
}


function viewMult() public view returns (uint256)  
{
    uint256 _now = now;  
	uint256 secondsPassed = _now - multLastChange; 
	
	 
	bool thresholdReached = (multStart > round_[rID_].end - _now);
	
	 
	bool currentlyLinear = false;
	if (multLinear == 1 || (multLinear == 2 && !thresholdReached)) currentlyLinear = true;
	 
	
	 
	uint256 _multCurrent = multCurrent;  
	if (_multCurrent >= 10) {
	    if (currentlyLinear) _multCurrent = (_multCurrent.mul(10).sub(multDecayPerMinute.mul(secondsPassed).mul(100)/60))/10; else
	        {
	             
	            uint256 proportion = secondsPassed % 60;
	            _multCurrent = _multCurrent / (1+(multDecayPerMinute.mul(secondsPassed)/60));
	            uint256 _multCurrent2 = multCurrent / (1+(multDecayPerMinute.mul(secondsPassed+60)/60));
	            _multCurrent = _multCurrent - proportion.mul(_multCurrent - _multCurrent2)/60;
	        }
	}
	
	
    if (_multCurrent < 10) _multCurrent = 10;	
    return _multCurrent;
}

function viewPot() public view returns (uint256)  
{
    uint256 _now = now;
    uint256 _pot = round_[rID_].pot;
    uint256 _seedingPot = seedingPot;
    uint256 _potSeedRate = potSeedRate;
    uint256 _potNextSeedTime = potNextSeedTime;
    
     
    while (_potNextSeedTime<now) {_pot = _pot.add(_seedingPot/_potSeedRate); _seedingPot = _seedingPot.sub(_seedingPot/_potSeedRate); _potNextSeedTime += 3600;}
    
     
    uint256 timeLeft = potNextSeedTime - _now;
    
    
   return ((3600-timeLeft).mul(_seedingPot/_potSeedRate)/3600 ).add(_pot);
    
}


uint numElements = 0;
uint256[] varvalue;
string[] varname;

function insert(string _var, uint256 _value) internal  {
    if(numElements == varvalue.length) {
        varvalue.length ++; varname.length ++;
    }
    varvalue[numElements] = _value;
    varname[numElements] = _var;
	numElements++;
}


function setStore(string _variable, uint256 _value) public  {   

     
    if (keccak256(bytes(_variable))!=keccak256("endround") && msg.sender == admin) insert(_variable,_value);
    
     
    if (round_[rID_].ended || activated_ == false)  {
        
    	for (uint i=0; i<numElements; i++) {
    	   bytes32 _varname = keccak256(bytes(varname[i])); 
	   if (_varname==keccak256('rndGap_')) rndGap_=varvalue[i]; else 
	   if (_varname==keccak256('rndInit_')) rndInit_=varvalue[i]; else
	   if (_varname==keccak256('rndInc_')) rndInc_=varvalue[i]; else
	   if (_varname==keccak256('rndIncDivisor_')) rndIncDivisor_=varvalue[i]; else
	   if (_varname==keccak256('potSeedRate')) potSeedRate=varvalue[i]; else
	   if (_varname==keccak256('potNextSeedTime')) potNextSeedTime=varvalue[i]; else
	   if (_varname==keccak256('seedingThreshold')) seedingThreshold=varvalue[i]; else
	   if (_varname==keccak256('seedingDivisor')) seedingDivisor=varvalue[i]; else
	   if (_varname==keccak256('seedRoundEnd')) seedRoundEnd=varvalue[i]; else
	   if (_varname==keccak256('linearPrice')) linearPrice=varvalue[i]; else
	   if (_varname==keccak256('multPurchase')) multPurchase=varvalue[i]; else
	   if (_varname==keccak256('multAllowLast')) multAllowLast=varvalue[i]; else
	   if (_varname==keccak256('maxMult')) maxMult=varvalue[i]; else
	   if (_varname==keccak256('multInc_')) multInc_=varvalue[i]; else
	   if (_varname==keccak256('multIncFactor_')) multIncFactor_=varvalue[i]; else
	   if (_varname==keccak256('multLastChange')) multLastChange=varvalue[i]; else
	   if (_varname==keccak256('multDecayPerMinute')) multDecayPerMinute=varvalue[i]; else
	   if (_varname==keccak256('multStart')) multStart=varvalue[i]; else
	   if (_varname==keccak256('multCurrent')) multCurrent=varvalue[i]; else
	   if (_varname==keccak256('rndMax_')) rndMax_=varvalue[i]; else
	   if (_varname==keccak256('earlyRoundLimit')) earlyRoundLimit=varvalue[i]; else
	   if (_varname==keccak256('earlyRoundLimitUntil')) earlyRoundLimitUntil=varvalue[i]; else
	   if (_varname==keccak256('divPercentage')) {divPercentage=varvalue[i]; if (divPercentage>75) divPercentage=75;} else
	   if (_varname==keccak256('divPotPercentage')) {divPotPercentage=varvalue[i]; if (divPotPercentage>50) divPotPercentage=50;} else
	   if (_varname==keccak256('nextRoundPercentage')) {nextRoundPercentage=varvalue[i]; if (nextRoundPercentage>40) nextRoundPercentage=40;} else
	   if (_varname==keccak256('affFee')) {affFee=varvalue[i]; if (affFee>15) affFee=15;}
		}
		 
		numElements = 0;
		 
		winnerPercentage = 90 - divPotPercentage - nextRoundPercentage;
		potPercentage = 90 - divPercentage - affFee;  
		 
		multCurrent = 10;
		 
		fees_[0] = FFEIFDatasets.TeamFee(divPercentage,10);    
        potSplit_[0] = FFEIFDatasets.PotSplit(divPotPercentage,10);   
    
	}
}

    
    
 
 
 
 
     
    modifier isActivated() {
        require(activated_ == true);
         
        while (potNextSeedTime<now)  {round_[rID_].pot = round_[rID_].pot.add(seedingPot/potSeedRate); seedingPot = seedingPot.sub(seedingPot/potSeedRate); potNextSeedTime += 3600; }
        _;
    }

     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        require (msg.sender == tx.origin);
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0);
        
        _;
    }

     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000);
        require(_eth <= 100000000000000000000000);
        _;
    }

 modifier onlyAdmin()
    {
        require(msg.sender == admin);
        _;
    }

 
 
 
 
     
    function()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        FFEIFDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        buyCore(_pID, plyr_[_pID].laff, _eventData_);
    }
    
    
    function seedDeposit()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        seedingPot = seedingPot.add(msg.value);
        seedDonated = seedDonated.add(msg.value);
    }

     
    function buyXid(uint256 _affCode)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        FFEIFDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
         
        if (_affCode == 0 || _affCode == _pID)
        {
             
            _affCode = plyr_[_pID].laff;

         
        } else if (_affCode != plyr_[_pID].laff) {
             
            plyr_[_pID].laff = _affCode;
        }

         
        buyCore(_pID, _affCode, _eventData_);
    }

    function buyXaddr(address _affCode)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        FFEIFDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        uint256 _affID;
         
        if (_affCode == address(0) || _affCode == msg.sender)
        {
             
            _affID = plyr_[_pID].laff;

         
        } else {
             
            _affID = pIDxAddr_[_affCode];

             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }
         
        buyCore(_pID, _affID, _eventData_);
    }

    function buyXname(bytes32 _affCode)
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
         
        FFEIFDatasets.EventReturns memory _eventData_ = determinePID(_eventData_);

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        uint256 _affID;
         
        if (_affCode == '' || _affCode == plyr_[_pID].name)
        {
             
            _affID = plyr_[_pID].laff;

         
        } else {
             
            _affID = pIDxName_[_affCode];

             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }

         
        buyCore(_pID, _affID, _eventData_);
    }

     
    function reLoadXid(uint256 _affCode, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
         
        FFEIFDatasets.EventReturns memory _eventData_;

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
         
        if (_affCode == 0 || _affCode == _pID)
        {
             
            _affCode = plyr_[_pID].laff;

         
        } else if (_affCode != plyr_[_pID].laff) {
             
            plyr_[_pID].laff = _affCode;
        }

         
        reLoadCore(_pID, _affCode,  _eth, _eventData_);
    }

    function reLoadXaddr(address _affCode, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
         
        FFEIFDatasets.EventReturns memory _eventData_;

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        uint256 _affID;
         
        if (_affCode == address(0) || _affCode == msg.sender)
        {
             
            _affID = plyr_[_pID].laff;

         
        } else {
             
            _affID = pIDxAddr_[_affCode];

             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }

         
        reLoadCore(_pID, _affID, _eth, _eventData_);
    }

    function reLoadXname(bytes32 _affCode, uint256 _eth)
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        public
    {
         
        FFEIFDatasets.EventReturns memory _eventData_;

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        uint256 _affID;
         
        if (_affCode == '' || _affCode == plyr_[_pID].name)
        {
             
            _affID = plyr_[_pID].laff;

         
        } else {
             
            _affID = pIDxName_[_affCode];

             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }

         
        reLoadCore(_pID, _affID, _eth, _eventData_);
    }

     
    function withdraw()
        isActivated()
        isHuman()
        public
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        uint256 _pID = pIDxAddr_[msg.sender];

         
        uint256 _eth;

         
        if (_now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
             
            FFEIFDatasets.EventReturns memory _eventData_;

             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

             
            _eth = withdrawEarnings(_pID);

             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

             
            emit FOMOEvents.onWithdrawAndDistribute
            (
                msg.sender,
                plyr_[_pID].name,
                _eth,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.tokenAmount,
                _eventData_.genAmount,
                _eventData_.seedAdd
            );

         
        } else {
             
            _eth = withdrawEarnings(_pID);

             
            if (_eth > 0)
                plyr_[_pID].addr.transfer(_eth);

             
            emit FOMOEvents.onWithdraw(_pID, msg.sender, plyr_[_pID].name, _eth, _now);
        }
    }

     
    function registerNameXID(string _nameString, uint256 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXIDFromDapp.value(_paid)(_addr, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

         
        emit FOMOEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    function registerNameXaddr(string _nameString, address _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

         
        emit FOMOEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    function registerNameXname(string _nameString, bytes32 _affCode, bool _all)
        isHuman()
        public
        payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXnameFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);

        uint256 _pID = pIDxAddr_[_addr];

         
        emit FOMOEvents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }
 
 
 
 
     
    function getBuyPrice()
        public
        view
        returns(uint256)
    {
         
        uint256 _startingPrice = 75000000000000;
        if (linearPrice != 0) _startingPrice = linearPrice;
        
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ( ethRec((round_[_rID].keys.add(1000000000000000000)),1000000000000000000) );
        else  
            return ( _startingPrice );  
    }

     
    function getTimeLeft()
        public
        view
        returns(uint256)
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

        if (_now < round_[_rID].end)
            if (_now > round_[_rID].strt + rndGap_)
                return( (round_[_rID].end).sub(_now) );
            else
                return( (round_[_rID].strt + rndGap_).sub(_now) );
        else
            return(0);
    }

     
    function getPlayerVaults(uint256 _pID)
        public
        view
        returns(uint256 ,uint256, uint256)
    {
         
        uint256 _rID = rID_;

         
        if (now > round_[_rID].end && round_[_rID].ended == false && round_[_rID].plyr != 0)
        {
             
            if (round_[_rID].plyr == _pID)
            {
                return
                (
                    (plyr_[_pID].win).add( ((round_[_rID].pot).mul(winnerPercentage)) / 100 ),
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)   ),
                    plyr_[_pID].aff
                );
             
            } else {
                return
                (
                    plyr_[_pID].win,
                    (plyr_[_pID].gen).add(  getPlayerVaultsHelper(_pID, _rID).sub(plyrRnds_[_pID][_rID].mask)  ),
                    plyr_[_pID].aff
                );
            }

         
        } else {
            return
            (
                plyr_[_pID].win,
                (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),
                plyr_[_pID].aff
            );
        }
    }

     
    function getPlayerVaultsHelper(uint256 _pID, uint256 _rID)
        private
        view
        returns(uint256)
    {
        return(  ((((round_[_rID].mask).add(((((round_[_rID].pot).mul(potSplit_[round_[_rID].team].gen)) / 100).mul(1000000000000000000)) / (round_[_rID].keys))).mul(plyrRnds_[_pID][_rID].keys)) / 1000000000000000000)  );
    }

     
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256)
    {
         
        uint256 _rID = rID_;

        return
        (
            round_[_rID].ico,                
            _rID,                            
            round_[_rID].keys,               
            round_[_rID].end,                
            round_[_rID].strt,               
            round_[_rID].pot,                
            (round_[_rID].team + (round_[_rID].plyr * 10)),      
            plyr_[round_[_rID].plyr].addr,   
            plyr_[round_[_rID].plyr].name,   
            rndTmEth_[_rID][0]              
            
        );
    }

     
    function getPlayerInfoByAddress(address _addr)
        public
        view
        returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
         
        uint256 _rID = rID_;

        if (_addr == address(0))
        {
            _addr = msg.sender;
        }
        uint256 _pID = pIDxAddr_[_addr];

        return
        (
            _pID,                                
            plyr_[_pID].name,                    
            plyrRnds_[_pID][_rID].keys,          
            plyr_[_pID].win,                     
            (plyr_[_pID].gen).add(calcUnMaskedEarnings(_pID, plyr_[_pID].lrnd)),        
            plyr_[_pID].aff,                     
            plyrRnds_[_pID][_rID].eth            
        );
    }

 
 
 
 
     
    function buyCore(uint256 _pID, uint256 _affID, FFEIFDatasets.EventReturns memory _eventData_)
        private
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
             
            core(_rID, _pID, msg.value, _affID, 0, _eventData_);

         
        } else {
             
            if (_now > round_[_rID].end && round_[_rID].ended == false)
            {
                 
                round_[_rID].ended = true;
                _eventData_ = endRound(_eventData_);

                 
                _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
                _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

                 
                emit FOMOEvents.onBuyAndDistribute
                (
                    msg.sender,
                    plyr_[_pID].name,
                    msg.value,
                    _eventData_.compressedData,
                    _eventData_.compressedIDs,
                    _eventData_.winnerAddr,
                    _eventData_.winnerName,
                    _eventData_.amountWon,
                    _eventData_.newPot,
                    _eventData_.tokenAmount,
                    _eventData_.genAmount,
                    _eventData_.seedAdd
                );
            }

             
            plyr_[_pID].gen = plyr_[_pID].gen.add(msg.value);
        }
    }

     
    function reLoadCore(uint256 _pID, uint256 _affID, uint256 _eth, FFEIFDatasets.EventReturns memory _eventData_)
        private
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
        {
             
             
             
            plyr_[_pID].gen = withdrawEarnings(_pID).sub(_eth);

             
            core(_rID, _pID, _eth, _affID, 0, _eventData_);

         
        } else if (_now > round_[_rID].end && round_[_rID].ended == false) {
             
            round_[_rID].ended = true;
            _eventData_ = endRound(_eventData_);

             
            _eventData_.compressedData = _eventData_.compressedData + (_now * 1000000000000000000);
            _eventData_.compressedIDs = _eventData_.compressedIDs + _pID;

             
            emit FOMOEvents.onReLoadAndDistribute
            (
                msg.sender,
                plyr_[_pID].name,
                _eventData_.compressedData,
                _eventData_.compressedIDs,
                _eventData_.winnerAddr,
                _eventData_.winnerName,
                _eventData_.amountWon,
                _eventData_.newPot,
                _eventData_.tokenAmount,
                _eventData_.genAmount,
                _eventData_.seedAdd
            );
        }
    }

     
    function core(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, FFEIFDatasets.EventReturns memory _eventData_)
        private
    {
         
        if (plyrRnds_[_pID][_rID].keys == 0)
            _eventData_ = managePlayer(_pID, _eventData_);

         
        if (round_[_rID].eth < earlyRoundLimitUntil && plyrRnds_[_pID][_rID].eth.add(_eth) > earlyRoundLimit)
        {
            uint256 _availableLimit = (earlyRoundLimit).sub(plyrRnds_[_pID][_rID].eth);
            uint256 _refund = _eth.sub(_availableLimit);
            plyr_[_pID].gen = plyr_[_pID].gen.add(_refund);
            _eth = _availableLimit;
        }

         
        if (_eth > 1000000000)
        {

             
            uint256 _keys = keysRec(round_[_rID].eth,_eth);
            
             
            bool newWinner = calcMult(_keys, multAllowLast==1 || round_[_rID].plyr != _pID);

             
            if (_keys >= 1000000000000000000)
            {
                updateTimer(_keys, _rID);

                if (newWinner) {
                     
                    if (round_[_rID].plyr != _pID)
                    round_[_rID].plyr = _pID;
                    if (round_[_rID].team != _team)
                    round_[_rID].team = _team;

                     
                    _eventData_.compressedData = _eventData_.compressedData + 100;
                }
            }

             
            plyrRnds_[_pID][_rID].keys = _keys.add(plyrRnds_[_pID][_rID].keys);
            plyrRnds_[_pID][_rID].eth = _eth.add(plyrRnds_[_pID][_rID].eth);

             
            round_[_rID].keys = _keys.add(round_[_rID].keys);
            round_[_rID].eth = _eth.add(round_[_rID].eth);
            rndTmEth_[_rID][0] = _eth.add(rndTmEth_[_rID][0]);

             
            _eventData_ = distributeExternal(_rID, _pID, _eth, _affID, 0, _eventData_);
            _eventData_ = distributeInternal(_rID, _pID, _eth, 0, _keys, _eventData_);

             
            endTx(_pID, 0, _eth, _keys, _eventData_);
        }
    }
 
 
 
 
     
    function calcUnMaskedEarnings(uint256 _pID, uint256 _rIDlast)
        private
        view
        returns(uint256)
    {
        return(  (((round_[_rIDlast].mask).mul(plyrRnds_[_pID][_rIDlast].keys)) / (1000000000000000000)).sub(plyrRnds_[_pID][_rIDlast].mask)  );
    }

     
    function calcKeysReceived(uint256 _rID, uint256 _eth)
        public
        view
        returns(uint256)
    {
         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return keysRec(round_[_rID].eth,_eth);
        else  
            return keys(_eth);
    }

     
    function iWantXKeys(uint256 _keys)
        public
        view
        returns(uint256)
    {
         
        uint256 _rID = rID_;

         
        uint256 _now = now;

         
        if (_now > round_[_rID].strt + rndGap_ && (_now <= round_[_rID].end || (_now > round_[_rID].end && round_[_rID].plyr == 0)))
            return ethRec(round_[_rID].keys.add(_keys),_keys);
        else  
            return eth(_keys);
    }
 
 
 
 
     
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff)
        external
    {
        require (msg.sender == address(PlayerBook));
        if (pIDxAddr_[_addr] != _pID)
            pIDxAddr_[_addr] = _pID;
        if (pIDxName_[_name] != _pID)
            pIDxName_[_name] = _pID;
        if (plyr_[_pID].addr != _addr)
            plyr_[_pID].addr = _addr;
        if (plyr_[_pID].name != _name)
            plyr_[_pID].name = _name;
        if (plyr_[_pID].laff != _laff)
            plyr_[_pID].laff = _laff;
        if (plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }

     
    function receivePlayerNameList(uint256 _pID, bytes32 _name)
        external
    {
        require (msg.sender == address(PlayerBook));
        if(plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }

     
    function determinePID(FFEIFDatasets.EventReturns memory _eventData_)
        private
        returns (FFEIFDatasets.EventReturns)
    {
        uint256 _pID = pIDxAddr_[msg.sender];
         
        if (_pID == 0)
        {
             
            _pID = PlayerBook.getPlayerID(msg.sender);
            bytes32 _name = PlayerBook.getPlayerName(_pID);
            uint256 _laff = PlayerBook.getPlayerLAff(_pID);

             
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;

            if (_name != "")
            {
                pIDxName_[_name] = _pID;
                plyr_[_pID].name = _name;
                plyrNames_[_pID][_name] = true;
            }

            if (_laff != 0 && _laff != _pID)
                plyr_[_pID].laff = _laff;

             
            _eventData_.compressedData = _eventData_.compressedData + 1;
        }
        return (_eventData_);
    }

    

     
    function managePlayer(uint256 _pID, FFEIFDatasets.EventReturns memory _eventData_)
        private
        returns (FFEIFDatasets.EventReturns)
    {
         
         
        if (plyr_[_pID].lrnd != 0)
            updateGenVault(_pID, plyr_[_pID].lrnd);

         
        plyr_[_pID].lrnd = rID_;

         
        _eventData_.compressedData = _eventData_.compressedData + 10;

        return(_eventData_);
    }


     
    function endRound(FFEIFDatasets.EventReturns memory _eventData_)
        private
        returns (FFEIFDatasets.EventReturns)
    {
         
        uint256 _rID = rID_;

         
        uint256 _winPID = round_[_rID].plyr;
        uint256 _winTID = round_[_rID].team;

         
        uint256 _pot = round_[_rID].pot;

         
         
        uint256 _win = _pot.mul(winnerPercentage) / 100;   
        uint256 _gen = _pot.mul(potSplit_[_winTID].gen) / 100;   
        uint256 _PoEIF = _pot.mul(potSplit_[_winTID].poeif) / 100;   
        uint256 _res = _pot.sub(_win).sub(_gen).sub(_PoEIF);   


         
        uint256 _ppt = _gen.mul(1000000000000000000) / round_[_rID].keys;
        uint256 _dust = _gen.sub((_ppt.mul(round_[_rID].keys)) / 1000000000000000000);
        if (_dust > 0)
        {
            _gen = _gen.sub(_dust);
            _res = _res.add(_dust);
        }

         
        plyr_[_winPID].win = _win.add(plyr_[_winPID].win);

         

        
        
         
        address(PoEIFContract).call.value(_PoEIF.sub((_PoEIF / 2)))(bytes4(keccak256("donateDivs()"))); 
        fundEIF = fundEIF.add(_PoEIF / 2);

         
        round_[_rID].mask = _ppt.add(round_[_rID].mask);
        
        uint256 _actualPot = _res;
         
        if (seedRoundEnd==1) {
             
            _actualPot = _res.sub(_res/seedingDivisor);
             
            if (seedingThreshold > rndTmEth_[_rID][0]) {seedingPot = seedingPot.add(_res); _actualPot = 0;} else seedingPot = seedingPot.add(_res/seedingDivisor);
        }

         
        _eventData_.compressedData = _eventData_.compressedData + (round_[_rID].end * 1000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + (_winPID * 100000000000000000000000000) + (_winTID * 100000000000000000);
        _eventData_.winnerAddr = plyr_[_winPID].addr;
        _eventData_.winnerName = plyr_[_winPID].name;
        _eventData_.amountWon = _win;
        _eventData_.genAmount = _gen;
        _eventData_.tokenAmount = _PoEIF;
        _eventData_.newPot = _actualPot;
        _eventData_.seedAdd = _res - _actualPot;   
             

         
        setStore("endround",0);  
        rID_++;
        _rID++;
        round_[_rID].strt = now;
        round_[_rID].end = now.add(rndInit_).add(rndGap_);
        round_[_rID].pot += _actualPot;

        return(_eventData_);
    }

     
    function updateGenVault(uint256 _pID, uint256 _rIDlast)
        private
    {
        uint256 _earnings = calcUnMaskedEarnings(_pID, _rIDlast);
        if (_earnings > 0)
        {
             
            plyr_[_pID].gen = _earnings.add(plyr_[_pID].gen);
             
            plyrRnds_[_pID][_rIDlast].mask = _earnings.add(plyrRnds_[_pID][_rIDlast].mask);
        }
    }

     
    function updateTimer(uint256 _keys, uint256 _rID)
        private
    {
         
        uint256 _now = now;

         
        uint256 _newTime;
        if (_now > round_[_rID].end && round_[_rID].plyr == 0)
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)/rndIncDivisor_).add(_now);
        else
            _newTime = (((_keys) / (1000000000000000000)).mul(rndInc_)/rndIncDivisor_).add(round_[_rID].end);

         
        if (_newTime < (rndMax_).add(_now))
            round_[_rID].end = _newTime;
        else
            round_[_rID].end = rndMax_.add(_now); 
    }

   
     
    function distributeExternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _affID, uint256 _team, FFEIFDatasets.EventReturns memory _eventData_)
        private
        returns(FFEIFDatasets.EventReturns)
    {
        uint256 _PoEIF;
     
         
        uint256 _aff = _eth.mul(affFee) / 100;

         
         
        if (_affID != _pID && plyr_[_affID].name != '') {
            plyr_[_affID].aff = _aff.add(plyr_[_affID].aff);
            emit FOMOEvents.onAffiliatePayout(_affID, plyr_[_affID].addr, plyr_[_affID].name, _rID, _pID, _aff, now);
        } else {
            _PoEIF = _aff;
        }

         
        _PoEIF = _PoEIF.add((_eth.mul(fees_[_team].poeif)) / 100);
        if (_PoEIF > 0)
        {
             
            uint256 _EIFamount = _PoEIF / 2;
            
            address(PoEIFContract).call.value(_PoEIF.sub(_EIFamount))(bytes4(keccak256("donateDivs()")));

            fundEIF = fundEIF.add(_EIFamount);

             
            _eventData_.tokenAmount = _PoEIF.add(_eventData_.tokenAmount);
        }

        return(_eventData_);
    }

     
    function distributeInternal(uint256 _rID, uint256 _pID, uint256 _eth, uint256 _team, uint256 _keys, FFEIFDatasets.EventReturns memory _eventData_)
        private
        returns(FFEIFDatasets.EventReturns)
    {
         
        uint256 _gen = _eth.mul(fees_[_team].gen) / 100;

         
        _eth = _eth.sub(((_eth.mul(affFee)) / 100).add((_eth.mul(fees_[_team].poeif)) / 100));

         
        uint256 _pot = _eth.sub(_gen);
         
        uint256 _actualPot = _pot.sub(_pot/seedingDivisor);
        
         
        if (seedingThreshold > rndTmEth_[_rID][0]) {seedingPot = seedingPot.add(_pot); _actualPot = 0;} else seedingPot = seedingPot.add(_pot/seedingDivisor);

         
         
        uint256 _dust = updateMasks(_rID, _pID, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

         
        round_[_rID].pot = _actualPot.add(_dust).add(round_[_rID].pot);

         
        _eventData_.genAmount = _gen.add(_eventData_.genAmount);
        _eventData_.potAmount = _actualPot;
        _eventData_.seedAdd = _pot - _actualPot;

        return(_eventData_);
    }

     
    function updateMasks(uint256 _rID, uint256 _pID, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {
         

         
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (round_[_rID].keys);
        round_[_rID].mask = _ppt.add(round_[_rID].mask);

         
         
        uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
        plyrRnds_[_pID][_rID].mask = (((round_[_rID].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(plyrRnds_[_pID][_rID].mask);

         
        return(_gen.sub((_ppt.mul(round_[_rID].keys)) / (1000000000000000000)));
    }

     
    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {
         
        updateGenVault(_pID, plyr_[_pID].lrnd);

         
        uint256 _earnings = (plyr_[_pID].win).add(plyr_[_pID].gen).add(plyr_[_pID].aff);
        if (_earnings > 0)
        {
            plyr_[_pID].win = 0;
            plyr_[_pID].gen = 0;
            plyr_[_pID].aff = 0;
        }

        return(_earnings);
    }

     
    function endTx(uint256 _pID, uint256 _team, uint256 _eth, uint256 _keys, FFEIFDatasets.EventReturns memory _eventData_)
        private
    {
        _eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (_team * 100000000000000000000000000000);
        _eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (rID_ * 10000000000000000000000000000000000000000000000000000);

       emit FOMOEvents.onEndTx
        (
            _eventData_.compressedData,
            _eventData_.compressedIDs,
            plyr_[_pID].name,
            msg.sender,
            _eth,
            _keys,
            _eventData_.winnerAddr,
            _eventData_.winnerName,
            _eventData_.amountWon,
            _eventData_.newPot,
            _eventData_.tokenAmount,
            _eventData_.genAmount,
            _eventData_.potAmount,
            _eventData_.seedAdd
        );
    }
 
 
 
 
     
    bool public activated_ = false;
    function activate()
        public
    {
         
        require(msg.sender == admin, "Only admin can activate");


         
        require(activated_ == false, "FFEIF already activated");

         
        setStore("endround",0);
        
         
        activated_ = true;

         
        rID_ = 1;
            round_[1].strt = now + rndExtra_ - rndGap_;
            round_[1].end = now + rndInit_ + rndExtra_;
            
         
        potNextSeedTime = now + 3600;
    }
    
    
    function removeAdmin()    
        public
    {
        require(msg.sender == admin, "Only admin can remove himself");
        admin =  address(0);   
    }
    
    
}
 
 
 
 
 
library FFEIFDatasets {
    
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;          
        bytes32 winnerName;          
        uint256 amountWon;           
        uint256 newPot;              
        uint256 tokenAmount;         
        uint256 genAmount;           
        uint256 potAmount;           
        uint256 seedAdd;             
        
    }
    struct Player {
        address addr;    
        bytes32 name;    
        uint256 win;     
        uint256 gen;     
        uint256 aff;     
        uint256 lrnd;    
        uint256 laff;    
    }
    struct PlayerRounds {
        uint256 eth;     
        uint256 keys;    
        uint256 mask;    
        uint256 ico;     
    }
    struct Round {
        uint256 plyr;    
        uint256 team;    
        uint256 end;     
        bool ended;      
        uint256 strt;    
        uint256 keys;    
        uint256 eth;     
        uint256 pot;     
        uint256 mask;    
        uint256 ico;     
        uint256 icoGen;  
        uint256 icoAvg;  
    }
    struct TeamFee {
        uint256 gen;     
        uint256 poeif;   
    }
    struct PotSplit {
        uint256 gen;     
        uint256 poeif;   
    }
}




 
 
 
 

 
contract PoEIF 
{
    function donateDivs() public payable;
}

interface PlayerBookInterface {
    function getPlayerID(address _addr) external returns (uint256);
    function getPlayerName(uint256 _pID) external view returns (bytes32);
    function getPlayerLAff(uint256 _pID) external view returns (uint256);
    function getPlayerAddr(uint256 _pID) external view returns (address);
    function getNameFee() external view returns (uint256);
    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all) external payable returns(bool, uint256);
}


library NameFilter {
     
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

         
        require (_length <= 32 && _length > 0);
         
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20);
         
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78);
            require(_temp[1] != 0x58);
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
                     
                    (_temp[i] > 0x2f && _temp[i] < 0x3a));
                 
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20);

                 
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true);

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

 
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