 

pragma solidity ^0.4.25;


contract SPBevents {

     
    event onWithdraw
    (
        uint256 indexed sniperID,
        address sniperAddress,
        uint256 ethOut,
        uint256 timeStamp
    );

     
    event onAffiliatePayout
    (
        uint256 indexed affiliateID,
        uint256 indexed roundID,
        uint256 indexed buyerID,
        uint256 amount,
        uint256 timeStamp
    );
    
     
    event onCheckMainpot
    (
        uint256 indexed randomNumber,
        uint256 indexed roundID,
        address indexed sniperAddress,
        uint256 timeStamp
    );
    
     
    event onCheckLuckypot
    (
        uint256 indexed randomNumber,
        uint256 indexed roundID,
        address indexed sniperAddress,
        uint256 timeStamp
    );
    
     
    event onCheckKingpot
    (
        uint256 indexed randomNumber,
        address indexed sniperAddress,
        uint256 indexed roundID,
        uint256 timeStamp
    );
    
     
    event onCheckHitNumber
    (
        uint256 indexed randomNumber,
        uint256 indexed beingHitSniperID,
        address indexed firedSniperAddress,
        uint256 roundID,
        uint256 timeStamp
    );
    
     
    event onEndTx
    (
        uint256 sniperID,
        uint256 ethIn,
        uint256 number,
        uint256 laffID,
        uint256 timeStamp
    );
    
     
    event onICOAngel
    (
        address indexed whoInvest,
        uint256 amount,
        uint256 timeStamp
    );
    
    event onOEZDay
    (
        uint256 amount,
        uint256 timeStamp
    );
}

contract modularBillion is SPBevents {}

contract SniperBillion is modularBillion {
    
    using SafeMath for *;
    using Array256Lib for uint256[];
   
    
    address constant private comReward_ = 0x8Aa94D530cC572aF0C730147E1ab76875F25f71C;
    address constant private comMarket_ = 0x6c14CAAc549d7411faE4e201105B4D33afb8a3db;
    address constant private comICO_ = 0xbAdb636C5C3665a969159a6b993F811D9F263639;
    address constant private donateAccount_ =  0x1bB064708eBf4763BeB495877E99Dfeb75198942;
    
    RubyFundForwarderInterface constant private Ruby_Fund = RubyFundForwarderInterface(0x7D653E0Ecb4DAF3166a49525Df04147a7180B051);
    SniperBookInterface constant private SniperBook = SniperBookInterface(0xc294FA45F713B09d865A088543765800F47514eD);

    string constant public name   = "Sniper Billion Official";
    string constant public symbol = "SPB";
    

    uint256 constant private icoEndTime_ = 24 hours;    
    uint256 constant private maxNumber_  = 100000000;  

    uint256 public totalSum_;
    uint256 public rID_;
    uint256 public icoAmount_;
    
    bool private isDrawed_ = false;
    uint256 lastSID_;
    
    uint256[] private globalArr_;
    uint256[] private icoSidArr_;            
    uint256[] private luckyPotBingoArr_;
    uint256[] private airdropPotBingoArr_;
    
     
     
     
    mapping (address => uint256) public sIDxAddr_;           
    mapping (bytes32 => uint256) public sIDxName_;           
    mapping (uint256 => uint256) public sidXnum_;            

    mapping (uint256 => SPBdatasets.Sniper) public spr_;    
    mapping (uint256 => SPBdatasets.Round) public round_;
    mapping (uint256 => mapping (bytes32 => bool)) public sprNames_;  
    
    
    constructor()
        public 
    {
         
    }

     
    modifier isActivated() {
        require(activated_ == true, "its not ready yet.  check our discord"); 
        _;
    }

     
    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }

     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 100000000000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;    
    }
    
     
    modifier isIcoPhase() {
        require(now < round_[1].icoend, "ico end");
        _;
    }
    
     
    modifier isGameStart() {
        require(now > round_[rID_].icoend, "start");
        _;
    }
    
     
    modifier isWithinIcoLimits(uint256 _eth) {
        require(_eth >= 1000000000000000000, "pocket lint: not a valid currency");
        require(_eth <= 200000000000000000000, "ico up to 200 Ether");
        _;    
    }
    
     
    function()
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        isGameStart()
        payable
        external
    {
         
        determineSID();
            
         
        uint256 _sID = sIDxAddr_[msg.sender];
        
         
        buyCore(_sID, spr_[_sID].laff);
    }
    
    function buyXaddr(address _affCode)
        public
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        isGameStart()
        payable
    {
         
        determineSID();
        
         
        uint256 _sID = sIDxAddr_[msg.sender];
        
         
        uint256 _affID;
         
        if (_affCode == address(0) || _affCode == msg.sender)
        {
             
            _affID = spr_[_sID].laff;
        
         
        } else {
             
            _affID = sIDxAddr_[_affCode];
            
             
            if (_affID != spr_[_sID].laff)
            {
                 
                spr_[_sID].laff = _affID;
            }
        }
        

         
        if (_affCode == address(0) || _affCode == msg.sender)
        {
             
            _affID = spr_[_sID].laff;
        
         
        } else {
             
            _affID = sIDxAddr_[_affCode];
            
             
            if (_affID != spr_[_sID].laff)
            {
                 
                spr_[_sID].laff = _affID;
            }
        }

         
        buyCore(_sID, _affID);
    }


    function becomeSniperAngel()
        public
        isActivated()
        isHuman()
        isIcoPhase()
        isWithinIcoLimits(msg.value)
        payable
    {
         
        determineSID();
        
        
         
        uint256 _sID = sIDxAddr_[msg.sender];
        
        spr_[_sID].icoAmt = spr_[_sID].icoAmt.add(msg.value); 
        
        icoSidArr_.push(_sID);
        
         
        round_[1].mpot = round_[1].mpot.add((msg.value / 100).mul(80));
        
         
        icoAmount_ = icoAmount_.add(msg.value);
        
         
        uint256 _icoEth = (msg.value / 100).mul(20);
        
        if(_icoEth > 0)
            comICO_.transfer(_icoEth);
            
        emit onICOAngel(msg.sender, msg.value, block.timestamp);
    }
    

     
    function withdraw()
        public
        isActivated()
        isHuman()
    {
         
        uint256 _now = now;
        
         
        uint256 _sID = sIDxAddr_[msg.sender];
        

         
       uint256 _eth = withdrawEarnings(_sID);
        
         
        if (_eth > 0)
            spr_[_sID].addr.transfer(_eth);
        
         
        emit SPBevents.onWithdraw(_sID, msg.sender, _eth, _now);
        
    }
    

    function withdrawEarnings(uint256 _sID)
        private
        returns(uint256)
    {

         
        uint256 _earnings = (spr_[_sID].win).add(spr_[_sID].gen).add(spr_[_sID].aff).add(spr_[_sID].gems);
        if (_earnings > 0)
        {
            spr_[_sID].win = 0;
            spr_[_sID].gen = 0;
            spr_[_sID].aff = 0;
            spr_[_sID].gems = 0;
        }

        return(_earnings);
    }

    function generateRandom()
        private
        view
        returns(uint256)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
        )));
        seed = seed - ((seed / 100000000) * 100000000) + 1;
        return seed;
    }

    function itemRemove(uint256[] storage self, uint256 index) private {
        if (index >= self.length) return;

        for (uint256 i = index; i < self.length - 1; i++){
            self[i] = self[i+1];
        }
        self.length--;
    }

     
    function buyCore(uint256 _sID, uint256 _affID)
        private
    {
        uint256 _rID = rID_;
 
         
         

        if(_affID == 0 && spr_[_sID].laff == 0) {
            emit onAffiliatePayout(4, _rID, _sID, msg.value, now);
            core(_rID, _sID, msg.value, 4);
        }else{
            emit onAffiliatePayout(_affID, _rID, _sID, msg.value, now);
            core(_rID, _sID, msg.value, _affID);
        }

    }


     
    function core(uint256 _rID, uint256 _sID, uint256 _eth, uint256 _affID)
        private
    {
        uint256 _now = block.timestamp;

        uint256 _value = _eth;
        uint256 _laffRearwd = _value / 10;
        
         
        spr_[_affID].aff = spr_[_affID].aff.add(_laffRearwd);
        
         
        spr_[_sID].laff = _affID;
        spr_[_sID].lplyt = _now;

        _value = _value.sub(_laffRearwd);

        uint256 _rndFireNum = generateRandom();
        
        emit onEndTx(_sID, _eth, _rndFireNum, _affID, _now);
        
        round_[_rID].ltime = _now;

        bool _isBingoLp = false;
        bool _isBingoKp = false;

        if(globalArr_.length != 0){
            if(globalArr_.length == 1)
            {
                globalArrEqualOne(_rID, _sID, _value, _rndFireNum);
            }else{
                globalArrNotEqualOne(_rID, _sID, _value, _rndFireNum);
            }
        }else{

            globalArrEqualZero(_rID, _sID, _value, _rndFireNum);
            
        }
        _isBingoLp = calcBingoLuckyPot(_rndFireNum);
        
         
        if(_isBingoLp){
            spr_[_sID].win = spr_[_sID].win.add(round_[_rID].lpot);
            round_[_rID].lpot = 0;
            emit onCheckLuckypot(_rndFireNum, _rID, spr_[_sID].addr, block.timestamp);
        }

         
        if(_eth >= 500000000000000000){
            _isBingoKp = calcBingoAirdropPot(_rndFireNum);
            
            if(_isBingoKp){
                spr_[_sID].win = spr_[_sID].win.add(round_[_rID].apot);
                round_[_rID].apot = 0;
                emit onCheckKingpot(_rndFireNum, spr_[_sID].addr, _rID, block.timestamp);
            }
        }
        
         
        checkWinMainPot(_rID, _sID, _rndFireNum);
        
         
        autoDrawWithOEZDay();
    }
    
     
    
    function autoDrawWithOEZDay()
        private
    {
        uint256 _oezDay = round_[rID_].strt + 180 days;
        if(!isDrawed_ && now > _oezDay){
            
            totalSum_ = 0;

             
             
             
             
             
             
            
             
             
             
             
             
            
            uint256 _cttBalance = round_[rID_].mpot.add(round_[rID_].lpot).add(round_[rID_].apot);
            
            
            uint256 _communityRewards = (_cttBalance / 100).mul(30);
            
            if(_communityRewards > 0)
                comReward_.transfer(_communityRewards);
                
            uint256 _sniperDividend;
            
        
            if(icoAmount_ > 0){
                 
                _sniperDividend = (_cttBalance / 100).mul(30);
                 
                uint256 _icoValue = (_cttBalance / 100).mul(30);
                distributeICO(_icoValue);
            }else{
                 
                _sniperDividend = (_cttBalance / 100).mul(60);
            }
            
            
             
            uint256 _eachPiece = _sniperDividend / lastSID_;
            
            for(uint256 i = 1; i < lastSID_; i++)
            {
                spr_[i].win = spr_[i].win.add(_eachPiece);
            }
            
            
             
            uint256 _communityMarket = (_cttBalance / 100).mul(5);
            if(_communityMarket > 0){
                comMarket_.transfer(_communityMarket);
                donateAccount_.transfer(_communityMarket);
            }
            
            emit onOEZDay(_cttBalance, now);
            
            round_[rID_].mpot = 0;
            round_[rID_].lpot = 0;
            round_[rID_].apot = 0;
            
            uint256 _icoEndTime = round_[rID_].icoend;
            
            rID_++;
            
            round_[rID_].strt = now;
            round_[rID_].icoend = _icoEndTime;
            
        }
    }
    
    function globalArrEqualZero(uint256 _rID, uint256 _sID, uint256 _value, uint256 _rndFireNum)
        private
    {
        round_[_rID].mpot = round_[_rID].mpot.add(((_value / 2) / 100).mul(90));
        round_[_rID].lpot = round_[_rID].lpot.add(((_value / 2) / 100).mul(5));
        round_[_rID].apot = round_[_rID].apot.add(((_value / 2) / 100).mul(5));
        
        sidXnum_[_rndFireNum] = _sID;
        
        spr_[_sID].numbers.push(_rndFireNum);
        spr_[_sID].snums++;
        spr_[_sID].gen = spr_[_sID].gen.add(_value / 2);
        globalArr_.push(_rndFireNum);
        
        totalSum_ = totalSum_.add(_rndFireNum);
    }

    function globalArrNotEqualOne(uint256 _rID, uint256 _sID, uint256 _value, uint256 _rndFireNum)
        private
    {
        uint256 _opID = sidXnum_[globalArr_[0]];
        bool _found = false;
        uint256 _index = 0;

        (_found, _index) = globalArr_.indexOf(_rndFireNum, false);
        _opID = sidXnum_[_rndFireNum];
        
        

        if(_found){

            (_found, _index) = spr_[_opID].numbers.indexOf(_rndFireNum, false);
            
            itemRemove(spr_[_opID].numbers, _index);

            spr_[_opID].snums--;
            
            sidXnum_[_rndFireNum] = _sID;
            
            spr_[_sID].snums++;
            spr_[_sID].numbers.push(_rndFireNum);
            
            spr_[_opID].win = spr_[_opID].win.add(_value);
            
            emit onCheckHitNumber(_rndFireNum, _opID, spr_[_sID].addr, _rID, block.timestamp);
    
        }else{
            round_[_rID].mpot = round_[_rID].mpot.add(((_value / 2) / 100).mul(90));
            round_[_rID].lpot = round_[_rID].lpot.add(((_value / 2) / 100).mul(5));
            round_[_rID].apot = round_[_rID].apot.add(((_value / 2) / 100).mul(5));

            globalArr_.push(_rndFireNum);
            globalArr_.heapSort();
            (_found, _index) = globalArr_.indexOf(_rndFireNum, true);

            if(_index == 0){
                _opID = sidXnum_[globalArr_[_index + 1]];
                
                spr_[_opID].win = spr_[_opID].win.add(((_value / 2) / 100).mul(50));
            
                
                spr_[_sID].snums++;
                spr_[_sID].numbers.push(_rndFireNum);
                spr_[_sID].gen = spr_[_sID].gen.add(((_value / 2) / 100).mul(50));
                
                sidXnum_[_rndFireNum] = _sID;
                
            }else if(_index == globalArr_.length - 1){
                _opID = sidXnum_[globalArr_[_index -1]];
                
                spr_[_opID].win = spr_[_opID].win.add(((_value / 2) / 100).mul(50));
                
                spr_[_sID].snums++;
                spr_[_sID].numbers.push(_rndFireNum);
                spr_[_sID].gen = spr_[_sID].gen.add(((_value / 2) / 100).mul(50));
                
                sidXnum_[_rndFireNum] = _sID;
                
            }else{
                uint256 _leftSID = sidXnum_[globalArr_[_index - 1]];
                uint256 _rightSID = sidXnum_[globalArr_[_index + 1]];
                
                spr_[_leftSID].win = spr_[_leftSID].win.add(((_value / 2) / 100).mul(50));
                spr_[_rightSID].win = spr_[_rightSID].win.add(((_value / 2) / 100).mul(50));
                
                spr_[_sID].snums++;
                spr_[_sID].numbers.push(_rndFireNum);
                
                
                sidXnum_[_rndFireNum] = _sID;
            }
            
            
                
        }
        
        totalSum_ = totalSum_.add(_rndFireNum);
    }

    function globalArrEqualOne(uint256 _rID, uint256 _sID, uint256 _value, uint256 _rndFireNum)
        private
    {
        uint256 _opID = sidXnum_[globalArr_[0]];
        bool _found = false;
        uint256 _index = 0;
        if(globalArr_[0] != _rndFireNum)
        {
            
            round_[_rID].mpot = round_[_rID].mpot.add(((_value / 2) / 100).mul(90));
            round_[_rID].lpot = round_[_rID].lpot.add(((_value / 2) / 100).mul(5));
            round_[_rID].apot = round_[_rID].apot.add(((_value / 2) / 100).mul(5));
            
            sidXnum_[_rndFireNum] = _sID;
            
            spr_[_opID].win = spr_[_opID].win.add((_value / 4));
            
            spr_[_sID].snums++;
            spr_[_sID].numbers.push(_rndFireNum);
            spr_[_sID].gen = spr_[_sID].gen.add((_value / 4));
    
            globalArr_.push(_rndFireNum);
        }else{
            spr_[_opID].win = spr_[_opID].win.add(_value);
            
            (_found, _index) = spr_[_opID].numbers.indexOf(_rndFireNum, false);
        
            itemRemove(spr_[_opID].numbers, _index);

            sidXnum_[_rndFireNum] = _sID;
            
            spr_[_opID].snums--;

            spr_[_sID].snums++;
            spr_[_sID].numbers.push(_rndFireNum);
            
            emit onCheckHitNumber(_rndFireNum, _opID, spr_[_sID].addr, _rID, block.timestamp);
            
        }
        
        totalSum_ = totalSum_.add(_rndFireNum);
    }
    
    function checkLuckyPot(uint256 _rndFireNum) private returns(uint256){
        delete luckyPotBingoArr_;
        uint256 number = _rndFireNum;
        uint returnNum = number;
        while (number > 0) {
            uint256 digit = uint8(number % 10); 
            number = number / 10;
 
            luckyPotBingoArr_.push(digit);
        }

        return returnNum;
    }
    
    function checkAirdropPot(uint256 _rndFireNum) private returns(uint256){
        delete airdropPotBingoArr_;
        uint256 number = _rndFireNum;
        uint returnNum = number;
        while (number > 0) {
            uint256 digit = uint8(number % 10); 
            number = number / 10;

            airdropPotBingoArr_.push(digit);
        }

        return returnNum;
    }
    
    function getDigit(uint256 x) private view returns (uint256) {
        return luckyPotBingoArr_[x];
    }
    

    function calcBingoLuckyPot(uint256 _rndFireNum)
        private
        returns(bool)
    {
        
        bool _isBingoLucky = false;
        checkLuckyPot(_rndFireNum);
        uint256 _flag;

        if(luckyPotBingoArr_.length > 1) {
            for(uint256 i = 0; i < luckyPotBingoArr_.length; i++){
                if(luckyPotBingoArr_[0] == getDigit(i)){
                    _flag++;
                }
            }
        }

        if(_flag == luckyPotBingoArr_.length && _flag != 0 && luckyPotBingoArr_.length != 0){
            _isBingoLucky = true;
        }

        return(_isBingoLucky);
    }

    function calcBingoAirdropPot(uint256 _rndFireNum) private returns(bool) {
        bool _isBingoAirdrop = false;
        checkAirdropPot(_rndFireNum);
        uint256 _temp;
        
        if(airdropPotBingoArr_.length > 1) {
            
            airdropPotBingoArr_.heapSort();
            
            _temp = airdropPotBingoArr_[0];
            
            for(uint256 i = 0; i < airdropPotBingoArr_.length; i++){
                if(i == 0 || airdropPotBingoArr_[i] == _temp.add(i)){         
                    _isBingoAirdrop = true;
                }else{
                    _isBingoAirdrop = false;
                    break;
                }
                
            }
        }

        return(_isBingoAirdrop);
    }

    function checkWinMainPot(uint256 _rID, uint256 _sID, uint256 _rndFireNum) private {
        if(totalSum_ == maxNumber_){
            
            isDrawed_ = true;
            
            totalSum_ = 0;

            spr_[_sID].snums = 0;
            delete spr_[_sID].numbers;
            
             
             
             
             
             
             
            
            uint256 _nextMpot;
            uint256 _nextLpot = round_[_rID].lpot;
            uint256 _nextApot = round_[_rID].apot;
            uint256 _icoEndTime = round_[_rID].icoend;
   
             
            
            uint256 _communityRewards;
            
            if(icoAmount_ > 0){
                 
                _nextMpot = (round_[_rID].mpot / 100).mul(20);
                 
                _communityRewards = (round_[_rID].mpot / 100).mul(10);
            }else{
                 
                _nextMpot = (round_[_rID].mpot / 100).mul(30);
                 
                _communityRewards = (round_[_rID].mpot / 100).mul(20);
            }
            
            if(_communityRewards > 0)
                comReward_.transfer(_communityRewards);
            
            spr_[_sID].win = spr_[_sID].win.add((round_[rID_].mpot / 100).mul(48));
            
             
            uint256 _communityMarket = (round_[_rID].mpot / 100).mul(1);
            if(_communityMarket > 0){
                comMarket_.transfer(_communityMarket);
                donateAccount_.transfer(_communityMarket);
            }
            
            
            emit onCheckMainpot(_rndFireNum, _rID, spr_[_sID].addr, block.timestamp);
            
             
            if(icoAmount_ > 0){
                uint256 _icoValue = (round_[_rID].mpot / 100).mul(20);
                distributeICO(_icoValue);
            }
            
            round_[rID_].mpot = 0;
            round_[rID_].lpot = 0;
            round_[rID_].apot = 0;
            
            rID_++;

            round_[rID_].strt = now;
            round_[rID_].mpot = _nextMpot;
            round_[rID_].lpot = _nextLpot;
            round_[rID_].apot = _nextApot;
            round_[rID_].icoend = _icoEndTime;
            
        }else{

            if(totalSum_ > maxNumber_){
                uint256 _overNum = totalSum_.sub(maxNumber_);
                totalSum_ = maxNumber_.sub(_overNum);
            }
            
        }
    }

    function distributeICO(uint256 _icoValue)
        private
    {
        for(uint256 i = 0; i < icoSidArr_.length; i++){

            uint256 _ps = percent(spr_[icoSidArr_[i]].icoAmt, icoAmount_, 4);
            uint256 _rs = _ps.mul(_icoValue) / 10000;
            spr_[icoSidArr_[i]].gems = spr_[icoSidArr_[i]].gems.add(_rs);
        }
    }
    
    function percent(uint256 numerator, uint256 denominator, uint256 precision) private pure returns(uint256 quotient) {

          
        uint256 _numerator  = numerator * 10 ** (precision+1);
         
        uint256 _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
   }


     
    function determineSID()
        private
    {
        uint256 _sID = sIDxAddr_[msg.sender];
         
        if (_sID == 0)
        {
             
            _sID = SniperBook.getSniperID(msg.sender);
            lastSID_ = _sID;
            bytes32 _name = SniperBook.getSniperName(_sID);
            uint256 _laff = SniperBook.getSniperLAff(_sID);
            
             
            sIDxAddr_[msg.sender] = _sID;
            spr_[_sID].addr = msg.sender;
            
            if (_name != "")
            {
                sIDxName_[_name] = _sID;
                spr_[_sID].name = _name;
                sprNames_[_sID][_name] = true;
            }
            
            if (_laff != 0 && _laff != _sID)
                spr_[_sID].laff = _laff;
            
        }
    }


     
     
    function getTotalSum()
        public
        isHuman()
        view
        returns(uint256)
    {
        return(totalSum_);
    }
    
    function getCurrentRoundInfo()
        public
        isHuman()
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256[] memory)
    {
        
        return(rID_, totalSum_, round_[rID_].lpot, round_[rID_].mpot, round_[rID_].apot, globalArr_);
    }
    
    function getSniperInfo(address _addr)
        public
        isHuman()
        view
        returns(uint256[] memory, uint256, uint256, uint256, uint256,  uint256)
    {
        
        return(spr_[sIDxAddr_[_addr]].numbers, spr_[sIDxAddr_[_addr]].aff, spr_[sIDxAddr_[_addr]].win, spr_[sIDxAddr_[_addr]].gems, spr_[sIDxAddr_[_addr]].gen, spr_[sIDxAddr_[_addr]].icoAmt);
    }
    
    function getSID(address _addr)
        public
        isHuman()
        view
        returns(uint256)
    {
        
        return(sIDxAddr_[_addr]);
    }
    
    function getGameTime()
        public
        isHuman()
        view
        returns(uint256, uint256, bool)
    {
        bool _icoOff = false;
        if(now > round_[1].icoend && activated_){
            _icoOff = true;
        }
        return(round_[1].icoend, icoAmount_, _icoOff);
    }

     
    bool public activated_ = false;
    function activate()
        public
    {
         
        require(
            msg.sender == 0x461f346C3B3D401A5f9Fef44bAB704e96abC926F ||
            msg.sender == 0x727fE77FFDf8D40F34f641DfB358d9856F9563cA ||
            msg.sender == 0x3b300189AfA703372022Ca97C64FaA27AdA05238 ||
            msg.sender == 0x4b95DE2f5E202b59B22a0EcCf6A7C2aa5578Ee4D ||
			msg.sender == 0x9f01209Fb1FA757cF6025C2aBf17b847408deDE5,
            "only luckyteam can activate"
        );
        
         
        require(address(comReward_) != address(0), "must link to comReward address");
        
         
        require(address(comMarket_) != address(0), "must link to comMarket address");

         
        require(address(comICO_) != address(0), "must link to comICO address");
        
         
        require(address(donateAccount_) != address(0), "must link to donateAccount address");
        
         
        require(activated_ == false, "H1M already activated");
        
         
        activated_ = true;
        
         
		rID_ = 1;
        round_[1].strt = now;
        round_[1].icostrt = now;
        round_[1].icoend = now + icoEndTime_;
    }
    
    function receiveSniperInfo(uint256 _sID, address _addr, bytes32 _name, uint256 _laff)
        external
    {
        require (msg.sender == address(SniperBook), "your not playerNames contract... hmmm..");
        if (sIDxAddr_[_addr] != _sID)
            sIDxAddr_[_addr] = _sID;
        if (sIDxName_[_name] != _sID)
            sIDxName_[_name] = _sID;
        if (spr_[_sID].addr != _addr)
            spr_[_sID].addr = _addr;
        if (spr_[_sID].name != _name)
            spr_[_sID].name = _name;
        if (spr_[_sID].laff != _laff)
            spr_[_sID].laff = _laff;
        if (sprNames_[_sID][_name] == false)
            sprNames_[_sID][_name] = true;
    }
    
     
    function receiveSniperNameList(uint256 _sID, bytes32 _name)
        external
    {
        require (msg.sender == address(SniperBook), "your not playerNames contract... hmmm..");
        if(sprNames_[_sID][_name] == false)
            sprNames_[_sID][_name] = true;
    }   

}

library SPBdatasets {
    
    struct Round {
        uint256 strt;     
        uint256 icostrt;  
        uint256 icoend;   
        uint256 ltime;    
        uint256 apot;     
        uint256 lpot;     
        uint256 mpot;     
    }
    
    struct Sniper {
        address addr;    
        bytes32 name;    
        uint256 win;     
        uint256 gen;     
        uint256 aff;     
        uint256 lplyt;   
        uint256 laff;    
        uint256 snums;
        uint256 icoAmt;  
        uint256 gems;
        uint256[] numbers;  
    }
}


interface RubyFundForwarderInterface {
    function deposit() external payable returns(bool);
    function status() external view returns(address, address, bool);
    function startMigration(address _newCorpBank) external returns(bool);
    function cancelMigration() external returns(bool);
    function finishMigration() external returns(bool);
    function setup(address _firstCorpBank) external;
}

interface SniperBookInterface {
    function getSniperID(address _addr) external returns (uint256);
    function getSniperName(uint256 _sID) external view returns (bytes32);
    function getSniperLAff(uint256 _sID) external view returns (uint256);
    function getSniperAddr(uint256 _sID) external view returns (address);
    function getNameFee() external view returns (uint256);
    function registerNameXIDFromDapp(address _addr, bytes32 _name, uint256 _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXaddrFromDapp(address _addr, bytes32 _name, address _affCode, bool _all) external payable returns(bool, uint256);
    function registerNameXnameFromDapp(address _addr, bytes32 _name, bytes32 _affCode, bool _all) external payable returns(bool, uint256);
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

library Array256Lib {

   
   
   
  function sumElements(uint256[] storage self) public view returns(uint256 sum) {
    assembly {
      mstore(0x60,self_slot)

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        sum := add(sload(add(sha3(0x60,0x20),i)),sum)
      }
    }
  }

   
   
   
  function getMax(uint256[] storage self) public view returns(uint256 maxValue) {
    assembly {
      mstore(0x60,self_slot)
      maxValue := sload(sha3(0x60,0x20))

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        switch gt(sload(add(sha3(0x60,0x20),i)), maxValue)
        case 1 {
          maxValue := sload(add(sha3(0x60,0x20),i))
        }
      }
    }
  }

   
   
   
  function getMin(uint256[] storage self) public view returns(uint256 minValue) {
    assembly {
      mstore(0x60,self_slot)
      minValue := sload(sha3(0x60,0x20))

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        switch gt(sload(add(sha3(0x60,0x20),i)), minValue)
        case 0 {
          minValue := sload(add(sha3(0x60,0x20),i))
        }
      }
    }
  }

   
   
   
   
   
   
  function indexOf(uint256[] storage self, uint256 value, bool isSorted)
           public
           view
           returns(bool found, uint256 index) {
    assembly{
      mstore(0x60,self_slot)
      switch isSorted
      case 1 {
        let high := sub(sload(self_slot),1)
        let mid := 0
        let low := 0
        for { } iszero(gt(low, high)) { } {
          mid := div(add(low,high),2)

          switch lt(sload(add(sha3(0x60,0x20),mid)),value)
          case 1 {
             low := add(mid,1)
          }
          case 0 {
            switch gt(sload(add(sha3(0x60,0x20),mid)),value)
            case 1 {
              high := sub(mid,1)
            }
            case 0 {
              found := 1
              index := mid
              low := add(high,1)
            }
          }
        }
      }
      case 0 {
        for { let low := 0 } lt(low, sload(self_slot)) { low := add(low, 1) } {
          switch eq(sload(add(sha3(0x60,0x20),low)), value)
          case 1 {
            found := 1
            index := low
            low := sload(self_slot)
          }
        }
      }
    }
  }

   
   
   
  function getParentI(uint256 index) private pure returns (uint256 pI) {
    uint256 i = index - 1;
    pI = i/2;
  }

   
   
   
  function getLeftChildI(uint256 index) private pure returns (uint256 lcI) {
    uint256 i = index * 2;
    lcI = i + 1;
  }

   
   
  function heapSort(uint256[] storage self) public {
    uint256 end = self.length - 1;
    uint256 start = getParentI(end);
    uint256 root = start;
    uint256 lChild;
    uint256 rChild;
    uint256 swap;
    uint256 temp;
    while(start >= 0){
      root = start;
      lChild = getLeftChildI(start);
      while(lChild <= end){
        rChild = lChild + 1;
        swap = root;
        if(self[swap] < self[lChild])
          swap = lChild;
        if((rChild <= end) && (self[swap]<self[rChild]))
          swap = rChild;
        if(swap == root)
          lChild = end+1;
        else {
          temp = self[swap];
          self[swap] = self[root];
          self[root] = temp;
          root = swap;
          lChild = getLeftChildI(root);
        }
      }
      if(start == 0)
        break;
      else
        start = start - 1;
    }
    while(end > 0){
      temp = self[end];
      self[end] = self[0];
      self[0] = temp;
      end = end - 1;
      root = 0;
      lChild = getLeftChildI(0);
      while(lChild <= end){
        rChild = lChild + 1;
        swap = root;
        if(self[swap] < self[lChild])
          swap = lChild;
        if((rChild <= end) && (self[swap]<self[rChild]))
          swap = rChild;
        if(swap == root)
          lChild = end + 1;
        else {
          temp = self[swap];
          self[swap] = self[root];
          self[root] = temp;
          root = swap;
          lChild = getLeftChildI(root);
        }
      }
    }
  }

   
   
  function uniq(uint256[] storage self) public returns (uint256 length) {
    bool contains;
    uint256 index;

    for (uint256 i = 0; i < self.length; i++) {
      (contains, index) = indexOf(self, self[i], false);

      if (i > index) {
        for (uint256 j = i; j < self.length - 1; j++){
          self[j] = self[j + 1];
        }

        delete self[self.length - 1];
        self.length--;
        i--;
      }
    }

    length = self.length;
  }
}