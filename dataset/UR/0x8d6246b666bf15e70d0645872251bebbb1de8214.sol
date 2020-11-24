 

pragma solidity ^0.4.24;

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

 
library SafeMath {

     
    function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256 c)
    {
        if (a == 0 || b == 0) {
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

    function div(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256 c) 
    {
         
        if(b <= 0) return 0;
        else return a / b;
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

     
    function nameFilter(string  _input)
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

 
 
 
 

 
 
 
 
contract F3Devents {
     

     
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

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    event onBuyAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 pCosd,
        uint256 pCosc,
        uint256 comCosd,
        uint256 comCosc,
        uint256 affVltCosd,
        uint256 affVltCosc,
        uint256 keyNums
    );

     
     
     
     
     
     
    event onRecHldVltCosd
    (
        address playerAddress,
        bytes32 playerName, 
        uint256 hldVltCosd
    );

     
     
     
     
     
     
     
     
    event onSellAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 pCosd,
        uint256 pCosc,
        uint256 keyNums
    );

   
    event onWithdrawHoldVault
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 plyr_cosd,
        uint256 plyr_hldVltCosd
    );
    
    event onWithdrawAffVault
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 plyr_cosd,
        uint256 plyr_cosc,
        uint256 plyr_affVltCosd,
        uint256 plyr_affVltCosc
    );
    
    event onWithdrawWonCosFromGame
    (
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 plyr_cosd,
        uint256 plyr_cosc,
        uint256 plyr_affVltCosd
    );
}

contract modularLong is F3Devents {}

contract FoMo3DLong is modularLong, Ownable {
    using SafeMath for *;
    using NameFilter for *;
    using F3DKeysCalcLong for *;

     
    PlayerBookInterface constant private PlayerBook = PlayerBookInterface(0x82cFeBf0F80B9617b8D13368eFC9B76C48F096d4);

      
     
     
     
    string constant public name = "FoMo3D World";
    string constant public symbol = "F3DW";
     
     
     
     
     
     

     

     

    uint256 public rID_;     
    uint256 public plyNum_ = 2;
     
    uint256 public cosdNum_ = 0;
    uint256 public coscNum_ = 0;
    uint256 public totalVolume_ = 0;
    uint256 public totalVltCosd_ = 0;
    uint256 public result_ = 0;
    uint256 public price_ = 10**16;
    uint256 public priceCntThreshould_ = 100000; 

    uint256 constant public pIDCom_ = 1;
     
     
     
    mapping (address => uint256) public pIDxAddr_;           
    mapping (bytes32 => uint256) public pIDxName_;           
    mapping (uint256 => F3Ddatasets.Player) public plyr_;    
     
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;  
     
     
     
     
     
     
     
    
     
     
     

     
     
     
    
     
    
     
     
     
     

    constructor()
    public
    {
         
         
         
         
         
         
         
         
         
         
         
         
         
         
    }

     
     
     
     
     
     
     
     

     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
         
        _;
    }
    
    function()
     
    public
     
    {
         
    }

    function buyXaddr(address _pAddr, address _affCode, uint256 _eth, string _keyType) 
     
     
    onlyOwner()
     
    public
     
     
    {
         
         
         
        determinePID(_pAddr);

         
        uint256 _pID = pIDxAddr_[_pAddr];

         
        uint256 _affID;
         
        if (_affCode == address(0) || _affCode == _pAddr)
        {
             
            _affID = plyr_[_pID].laff;

             
        } else {
             
            _affID = pIDxAddr_[_affCode];

             
            if (_affID != plyr_[_pID].laff)
            {
                 
                plyr_[_pID].laff = _affID;
            }
        }

         
         

         
        buyCore(_pID, _affID, _eth, _keyType);
    }

    function registerNameXaddr(string   memory  _nameString, address _affCode, bool _all) 
     
     
    public
    payable
    {
        bytes32 _name = _nameString.nameFilter();
        address _addr = msg.sender;
        uint256 _paid = msg.value;
        (bool _isNewPlayer, uint256 _affID) = PlayerBook.registerNameXaddrFromDapp.value(msg.value)(msg.sender, _name, _affCode, _all);

        if(_isNewPlayer) plyNum_++;

        uint256 _pID = pIDxAddr_[_addr];

         
        emit F3Devents.onNewName(_pID, _addr, _name, _isNewPlayer, _affID, plyr_[_affID].addr, plyr_[_affID].name, _paid, now);
    }

    function totalSupplys()
    public
    view
    returns(uint256, uint256, uint256, uint256)
    {
        return (cosdNum_, coscNum_, totalVolume_, totalVltCosd_);
    }
   
    function getBuyPrice()
    public
    view
    returns(uint256)
    {
        return price_;
    }
  
    function getPlayerInfoByAddress(address _addr)
    public
    view
    returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
         
         
         

         
         
         
         
        uint256 _pID = pIDxAddr_[_addr];

        return
        (
            _pID,
            plyr_[_pID].name,
            plyr_[_pID].laff,    
            plyr_[_pID].eth,
            plyr_[_pID].cosd,       
            plyr_[_pID].cosc,
            plyr_[_pID].hldVltCosd,
            plyr_[_pID].affCosd,
            plyr_[_pID].affCosc,
            plyr_[_pID].totalHldVltCosd,
            plyr_[_pID].totalAffCos,
            plyr_[_pID].totalWinCos
        );
    }

   
    function buyCore(uint256 _pID, uint256 _affID, uint256 _eth, string _keyType)
    private
     
    {
        uint256 _keys;
         
        if (_eth >= 0)
        {
            require(_eth >= getBuyPrice());
             
            _keys = keysRec(_eth);
             
            uint256 _aff;
            uint256 _com;
            uint256 _holders;
            uint256 _self;

             
             
             
             
             
             
             
             
             
             
             

             
             
             
             
             
             
             
             
             
             
            if(isCosd(_keyType) == true){
                
                _aff        = _keys * 5/100;
                _com        = _keys * 2/100;
                _holders    = _keys * 3/100;
                _self       = _keys.sub(_aff).sub(_com).sub(_holders);

                uint256 _hldCosd;
                for (uint256 i = 1; i <= plyNum_; i++) {
                    if(plyr_[i].cosd>0) _hldCosd = _hldCosd.add(plyr_[i].cosd);
                }

                 
                plyr_[_pID].cosd = plyr_[_pID].cosd.add(_self);
                plyr_[pIDCom_].cosd = plyr_[pIDCom_].cosd.add(_com);
                plyr_[_affID].affCosd = plyr_[_affID].affCosd.add(_aff);
                
                 

                for (uint256 j = 1; j <= plyNum_; j++) {
                    if(plyr_[j].cosd>0) {
                         
                        plyr_[j].hldVltCosd = plyr_[j].hldVltCosd.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        
                         
                         
                        emit F3Devents.onRecHldVltCosd
                        (
                            plyr_[j].addr,
                            plyr_[j].name,
                            plyr_[j].hldVltCosd
                        );
                    }
                }
                 
                 
                cosdNum_ = cosdNum_.add(_keys);
                totalVolume_ = totalVolume_.add(_keys);
            }
            else{ 
                _aff        = _keys *4/100;
                _com        = _keys *1/100;
                 
                _self       = _keys.sub(_aff).sub(_com);
                 
                plyr_[_pID].cosc = plyr_[_pID].cosc.add(_self);
                plyr_[pIDCom_].cosc = plyr_[pIDCom_].cosc.add(_com);
                plyr_[_affID].affCosc = plyr_[_affID].affCosc.add(_aff);
                
                 
                 
                coscNum_ = coscNum_.add(_keys);
                totalVolume_ = totalVolume_.add(_keys);
            }

             
        }

         
    }  

   
    function sellKeys(uint256 _pID, uint256 _keys, string _keyType) 
     
     
    onlyOwner()
     
    public
     
    returns(uint256)
    {
         
         
        require(_keys>0);
        uint256 _eth;

         
         
        uint256 _holders;
        uint256 _self;
         
         
         
         
         
         
         
         
         
         
         
         
         
         
       if(isCosd(_keyType) == true){
                require(plyr_[_pID].cosd >= _keys,"Do not have cosd!");
                
                 
                 
                _holders    = _keys * 20/100;
                 
                _self       = _keys.sub(_holders);

                uint256 _hldCosd;
                for (uint256 i = 1; i <= plyNum_; i++) {
                    if(plyr_[i].cosd>0) _hldCosd = _hldCosd.add(plyr_[i].cosd);
                }

                plyr_[_pID].cosd = plyr_[_pID].cosd.sub(_keys);

                _eth = ethRec(_self);
                plyr_[_pID].eth = plyr_[_pID].eth.add(_eth);

                for (uint256 j = 1; j <= plyNum_; j++) {
                    if( plyr_[j].cosd>0) {                    
                        plyr_[j].hldVltCosd = plyr_[j].hldVltCosd.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        
                         
                         
                        emit F3Devents.onRecHldVltCosd
                        (
                            plyr_[j].addr,
                            plyr_[j].name,
                            plyr_[j].hldVltCosd
                        );
                    }
                }
                cosdNum_ = cosdNum_.sub(_self);
                totalVolume_ = totalVolume_.add(_keys);
       }
       else{
            require(plyr_[_pID].cosc >= _keys,"Do not have cosc!");           

            plyr_[_pID].cosc = plyr_[_pID].cosc.sub(_keys);

            _eth = ethRec(_keys);
            plyr_[_pID].eth = plyr_[_pID].eth.add(_eth);
            
            coscNum_ = coscNum_.sub(_keys);
            totalVolume_ = totalVolume_.add(_keys);
       }

     
        

       return _eth;
    }

    function addCosToGame(uint256 _pID, uint256 _keys, string _keyType) 
    onlyOwner()
    public
     
    {
             
             

            uint256 _aff;
            uint256 _com;
            uint256 _holders;
             
            uint256 _affID = plyr_[_pID].laff;

             
            if(isCosd(_keyType) == true){          

                require(plyr_[_pID].cosd >= _keys);

                _aff        = _keys *1/100;
                _com        = _keys *3/100;
                _holders    = _keys *5/100;
                 
                 
                plyr_[_pID].cosd = plyr_[_pID].cosd.sub(_keys);

                uint256 _hldCosd;
                for (uint256 i = 1; i <= plyNum_; i++) {
                    if(plyr_[i].cosd>0) _hldCosd = _hldCosd.add(plyr_[i].cosd);
                }

                 
                 
                plyr_[pIDCom_].cosd = plyr_[pIDCom_].cosd.add(_com);
                plyr_[_affID].affCosd = plyr_[_affID].affCosd.add(_aff);
            
                 

                for (uint256 j = 1; j <= plyNum_; j++) {
                    if(plyr_[j].cosd>0) {
                         
                        plyr_[j].hldVltCosd = plyr_[j].hldVltCosd.add(_holders.mul(plyr_[j].cosd).div(_hldCosd));
                        
                         
                         
                        emit F3Devents.onRecHldVltCosd
                        (
                            plyr_[j].addr,
                            plyr_[j].name,
                            plyr_[j].hldVltCosd
                        );
                    }
                }
            }
            else{ 
                require(plyr_[_pID].cosc >= _keys);
                 
                plyr_[_pID].cosc = plyr_[_pID].cosc.sub(_keys);
            }
        
             
    }

    function winCosFromGame(uint256 _pID, uint256 _keys, string _keyType) 
    onlyOwner()
    public
     
    {
             
             

             
            if(isCosd(_keyType) == true){
                 
                 
                plyr_[_pID].cosd = plyr_[_pID].cosd.add(_keys);
            }
            else{ 
                 
                 
                plyr_[_pID].cosc = plyr_[_pID].cosc.add(_keys);
            }
            
            plyr_[_pID].totalWinCos = plyr_[_pID].totalWinCos.add(_keys);
        
             
    }    
   
    function iWantXKeys(uint256 _keys)
    public
    view
    returns(uint256)
    {
        return eth(_keys);
    }
    
    function howManyKeysCanBuy(uint256 _eth)
    public
    view
    returns(uint256)
    {
        return keys(_eth);
    }
     
     
     
     
     
     
     
    function receivePlayerInfo(uint256 _pID, address _addr, bytes32 _name, uint256 _laff)
    external
    {
        require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
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
        require (msg.sender == address(PlayerBook), "your not playerNames contract... hmmm..");
        if(plyrNames_[_pID][_name] == false)
            plyrNames_[_pID][_name] = true;
    }

     
     
     
     
    function determinePID(address _pAddr)
    private
    {
        uint256 _pID = pIDxAddr_[_pAddr];
         
        if (_pID == 0)
        {
             
            _pID = PlayerBook.getPlayerID(_pAddr);
            bytes32 _name = PlayerBook.getPlayerName(_pID);
            uint256 _laff = PlayerBook.getPlayerLAff(_pID);

             
            pIDxAddr_[_pAddr] = _pID;
            plyr_[_pID].addr = _pAddr;

            if (_name != "")
            {
                pIDxName_[_name] = _pID;
                plyr_[_pID].name = _name;
                plyrNames_[_pID][_name] = true;
            }

            if (_laff != 0 && _laff != _pID)
                plyr_[_pID].laff = _laff;

             
             
             
        }
         
    }
    
    function withdrawETH(uint256 _pID) 
     
    onlyOwner()
    public
    returns(bool)
    {
        if (plyr_[_pID].eth>0) {
            plyr_[_pID].eth = 0;
        }
        return true;
    }

    function withdrawHoldVault(uint256 _pID) 
     
    onlyOwner()
    public
    returns(bool)
    {
        if (plyr_[_pID].hldVltCosd>0) {
            plyr_[_pID].cosd = plyr_[_pID].cosd.add(plyr_[_pID].hldVltCosd);
            
            plyr_[_pID].totalHldVltCosd = plyr_[_pID].totalHldVltCosd.add(plyr_[_pID].hldVltCosd);
            totalVltCosd_ = totalVltCosd_.add(plyr_[_pID].hldVltCosd);
                        
            plyr_[_pID].hldVltCosd = 0;
        }

        emit F3Devents.onWithdrawHoldVault
                    (
                        _pID,
                        plyr_[_pID].addr,
                        plyr_[_pID].name,
                        plyr_[_pID].cosd,
                        plyr_[_pID].hldVltCosd
                    );

        return true;
    }

    function withdrawAffVault(uint256 _pID, string _keyType) 
     
    onlyOwner()
    public
    returns(bool)
    {

        if(isCosd(_keyType) == true){

            if (plyr_[_pID].affCosd>0) {
                plyr_[_pID].cosd = plyr_[_pID].cosd.add(plyr_[_pID].affCosd);
                plyr_[_pID].totalAffCos = plyr_[_pID].totalAffCos.add(plyr_[_pID].affCosd);
                plyr_[_pID].affCosd = 0;
            }
        }
        else{
            if (plyr_[_pID].affCosc>0) {
                plyr_[_pID].cosc = plyr_[_pID].cosc.add(plyr_[_pID].affCosc);
                plyr_[_pID].totalAffCos = plyr_[_pID].totalAffCos.add(plyr_[_pID].affCosc);
                plyr_[_pID].affCosc = 0;
            }
        }

        emit F3Devents.onWithdrawAffVault
        (
                        _pID,
                        plyr_[_pID].addr,
                        plyr_[_pID].name,
                        plyr_[_pID].cosd,
                        plyr_[_pID].cosc,
                        plyr_[_pID].affCosd,
                        plyr_[_pID].affCosc
        );

        return true;
    }

    function transferToAnotherAddr(address _from, address _to, uint256 _keys, string _keyType)  
     
    onlyOwner()
    public
     
    {
         
         
         
         

         
         
        uint256 _pID = pIDxAddr_[_from];
        uint256 _tID = pIDxAddr_[_to];

        require(_tID > 0);
    
        if (isCosd(_keyType) == true) {

                require(plyr_[_pID].cosd >= _keys);

                 
                 
                 
                 

                 
                 
                 

                plyr_[_tID].cosd = plyr_[_tID].cosd.add(_keys);
                plyr_[_pID].cosd = plyr_[_pID].cosd.sub(_keys);

                 
                 
                 
        }

        else{
            require(plyr_[_pID].cosc >= _keys);

            plyr_[_tID].cosc = plyr_[_tID].cosc.add(_keys);
            plyr_[_pID].cosc = plyr_[_pID].cosc.sub(_keys);
        }

         
         
         
         
         
         
         
         
         

         
    }
    
    function isCosd(string _keyType)
    public
    pure
    returns(bool)
    {
        if( bytes(_keyType).length == 8 )
        {
            return true;
        }
        else 
        {
            return false;
        }
    }
    
     
     
     
     
     
     
        
     
     
    
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    
    function keysRec(uint256 _eth)
    internal
    returns (uint256)
    {
         
        
        uint256 _rstAmount = 0;
        uint256 _price = price_;
         
         

        while(_eth >= _price){
            _eth = _eth - _price;
            _price = _price + 5 *10**11;
            
            if(_price >= 2 *10**17){ 
                _price = 2 *10**17;
                 
            }
            
            _rstAmount++;
        }
        
        price_ = _price;

        return _rstAmount;
    }

    function ethRec(uint256 _keys)
    internal
    returns (uint256)
    {
         
        
        uint256 _eth = 0;
        uint256 _price = price_;
        uint256 _keyNum = cosdNum_.add(coscNum_);
         

        for(uint256 i=0;i < _keys;i++){
            if(_price < 10**16) _price = 10**16;
            
            _eth = _eth + _price;
            _price = _price - 5 *10**11;
            
            if(_price < 10**16) _price = 10**16;
            if(_keyNum - i >= priceCntThreshould_) _price = 2 *10**17; 
        }
        
        price_ = _price;

        return _eth;
    }

    function keys(uint256 _eth)
    internal
    view
    returns(uint256)
    {
          
        
        uint256 _rstAmount = 0;
        uint256 _price = price_;
         
         

        while(_eth >= _price){
            _eth = _eth - _price;
            _price = _price + 5 *10**11;
            
            if(_price >= 2 *10**17){ 
                _price = 2 *10**17;
                 
            }
            
            _rstAmount++;
        }
        
         

        return _rstAmount;
    }

    function eth(uint256 _keys)
    internal
    view
    returns(uint256)
    {
         
        
        uint256 _eth = 0;
        uint256 _price = price_;
        uint256 _keyNum = cosdNum_.add(coscNum_);
         

        for(uint256 i=0;i < _keys;i++){
            if(_price < 10**16) _price = 10**16;
            
            _eth = _eth + _price;
            _price = _price - 5 *10**11;
            
            if(_price < 10**16) _price = 10**16;
            if(_keyNum - i >= priceCntThreshould_) _price = 2 *10**17; 
        }
        
         

        return _eth;
    }
    
     
     
     
     
     
     
     
     
     
     
     
     
     

     
     

     
     

     
     
     
     
     
}

library F3Ddatasets {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    struct Player {
        address addr;    
        bytes32 name;    
        uint256 laff;    
        uint256 eth;
        uint256 cosd;     
        uint256 cosc;     
         
         
         
         
         
        uint256 hldVltCosd;
        uint256 affCosd;
        uint256 affCosc;
        uint256 totalHldVltCosd;
        uint256 totalAffCos;
        uint256 totalWinCos;
    }
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
}

library F3DKeysCalcLong {
    using SafeMath for *;

    function random() internal pure returns (uint256) {
       uint ranNum = uint(keccak256(msg.data)) % 100;
       return ranNum;
   }
}