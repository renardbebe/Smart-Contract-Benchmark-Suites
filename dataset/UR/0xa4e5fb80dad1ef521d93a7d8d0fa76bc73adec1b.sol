 

pragma solidity ^0.4.24;


contract FoMoInsurance {
    using SafeMath for *;
    using NameFilter for string;
    using F3DKeysCalcLong for uint256;


     
     
     
    struct Player {
        uint256 id;      
        bytes32 name;    
        uint256 gen;     
        uint256 aff;     
        bool isAgent;    
        uint256 eth;     
        uint256 keys;    
        uint256 units;   
        uint256 plyrLastSeen;  
        uint256 mask;    
        uint256 level;
        uint256 accumulatedAff;
    }


     
     
     
    FoMo3Dlong constant private FoMoLong = FoMo3Dlong(0xA62142888ABa8370742bE823c1782D17A0389Da1);
    DiviesInterface constant private Divies = DiviesInterface(0x93B2dbDd3F242EED7D7c7180c5A4Eddc4BaAE3E7);
    address constant private community = address(0xe853A139b87dD816f052A60Ef646Fd89f7964545);
    uint256 public end;
    bool public ended;


     
     
     
    mapping(address => mapping(uint256 => uint256)) public unitToExpirePlayer;
    mapping(uint256 => uint256) public unitToExpire;  

    uint256 public issuedInsurance;  
    uint256 public ethOfKey;         
    uint256 public keys;             
    uint256 public pot;              
    uint256 public today;            
    uint256 public _now;             
    uint256 public mask;             
    uint256 public agents;           

     
    mapping(address => Player) public player;  
    mapping(uint256 => address) public agentxID_;  
    mapping(bytes32 => address) public agentxName_;  

     
    uint256 constant maxInsurePeriod = 100;
    uint256 constant thisRoundIndex = 2;
    uint256 constant maxLevel = 10;

     
    uint256[101] public rate =
    [0,
    1000000000000000000,
    1990000000000000000,
    2970100000000000000,
    3940399000000000000,
    4900995010000000000,
    5851985059900000000,
    6793465209301000000,
    7725530557207990000,
    8648275251635910100,
    9561792499119550999,
    10466174574128355489,
    11361512828387071934,
    12247897700103201215,
    13125418723102169203,
    13994164535871147511,
    14854222890512436036,
    15705680661607311676,
    16548623854991238559,
    17383137616441326173,
    18209306240276912911,
    19027213177874143782,
    19836941046095402344,
    20638571635634448321,
    21432185919278103838,
    22217864060085322800,
    22995685419484469572,
    23765728565289624876,
    24528071279636728627,
    25282790566840361341,
    26029962661171957728,
    26769663034560238151,
    27501966404214635769,
    28226946740172489411,
    28944677272770764517,
    29655230500043056872,
    30358678195042626303,
    31055091413092200040,
    31744540498961278040,
    32427095093971665260,
    33102824143031948607,
    33771795901601629121,
    34434077942585612830,
    35089737163159756702,
    35738839791528159135,
    36381451393612877544,
    37017636879676748769,
    37647460510879981281,
    38270985905771181468,
    38888276046713469653,
    39499393286246334956,
    40104399353383871606,
    40703355359850032890,
    41296321806251532561,
    41883358588189017235,
    42464525002307127063,
    43039879752284055792,
    43609480954761215234,
    44173386145213603082,
    44731652283761467051,
    45284335760923852380,
    45831492403314613856,
    46373177479281467717,
    46909445704488653040,
    47440351247443766510,
    47965947734969328845,
    48486288257619635557,
    49001425375043439201,
    49511411121293004809,
    50016297010080074761,
    50516134039979274013,
    51010972699579481273,
    51500862972583686460,
    51985854342857849595,
    52465995799429271099,
    52941335841434978388,
    53411922483020628604,
    53877803258190422318,
    54339025225608518095,
    54795634973352432914,
    55247678623618908585,
    55695201837382719499,
    56138249819008892304,
    56576867320818803381,
    57011098647610615347,
    57440987661134509194,
    57866577784523164102,
    58287912006677932461,
    58705032886611153136,
    59117982557745041605,
    59526802732167591189,
    59931534704845915277,
    60332219357797456124,
    60728897164219481563,
    61121608192577286747,
    61510392110651513880,
    61895288189544998741,
    62276335307649548754,
    62653571954573053266,
    63027036235027322733,
    63396765872677049506];

     
    uint256[10] public requirement =
    [0,
    73890560989306501,
    200855369231876674,
    545981500331442382,
    1484131591025766010,
    4034287934927351160,
    10966331584284585813,
    29809579870417282259,
    81030839275753838749,
    220264657948067161559];


     
     
     
    event UPGRADE (address indexed agent, uint256 level);
    event BUYINSURANCE(address indexed buyer, uint256 indexed start, uint256 unit,  uint256 date);


     
     
     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }


     
    constructor() public {
        _now = now;
        today = _now / 1 days;
    }

     
    function tick() internal returns(bool) {
        if (_now != now) {
            _now = now;
            uint256 _today;  

             
            (,,end, ended,,,,,,,,) = FoMoLong.round_(thisRoundIndex);
            if (!ended) {
                _today = _now / 1 days;
            }
            else {
                _today = end / 1 days;
            }

             
            while (today < _today) {
                issuedInsurance = issuedInsurance.sub(unitToExpire[today]);
                today += 1;
            }
        }
        return ended;
    }

     
    function register(string _nameString) external payable isHuman() {
        bytes32 _name = _nameString.nameFilter();
        address _agent = msg.sender;
        require(msg.value >= 10000000000000000);
        require(agentxName_[_name] == address(0));

        if(!player[_agent].isAgent){
            agents += 1;
            player[_agent].isAgent = true;
            player[_agent].id = agents;
            player[_agent].level = 1;
            agentxID_[agents] = _agent;
        }
         
        player[_agent].name = _name;
        agentxName_[_name] = _agent;

        if(!community.send(msg.value)){
            pot = pot.add(msg.value);
        }
    }

     
    function upgrade() external isHuman(){
        address _agent = msg.sender;
        require(player[_agent].isAgent);
        require(player[_agent].level < maxLevel);

        if(player[_agent].accumulatedAff >= requirement[player[_agent].level]){
            player[_agent].level = (1).add(player[_agent].level);
            emit UPGRADE(_agent,player[_agent].level);
        }
    }

     
    function buyXaddr(address _agent, uint256 _date)
        isHuman()
        public
        payable
    {
         
        if(tick()){
            msg.sender.transfer(msg.value);
            return;
        }

         
        if(!player[_agent].isAgent){
            _agent = address(0);
        }

        buyCore(msg.sender, msg.value, _date, _agent);
    }

    function buyXid(uint256 _agentId, uint256 _date)
        isHuman()
        public
        payable
    {
         
        if(tick()){
            msg.sender.transfer(msg.value);
            return;
        }

        address _agent = agentxID_[_agentId];

         
        if(!player[_agent].isAgent){
            _agent = address(0);
        }

        buyCore(msg.sender, msg.value, _date, _agent);
    }

    function buyXname(bytes32 _agentName, uint256 _date)
        isHuman()
        public
        payable
    {
         
        if(tick()){
            msg.sender.transfer(msg.value);
            return;
        }

        address _agent = agentxName_[_agentName];

         
        if(!player[_agent].isAgent){
            _agent = address(0);
        }

        buyCore(msg.sender, msg.value, _date, _agent);
    }

     
    function buyCore(address _buyer, uint256 _eth, uint256 _date, address _agent) internal {

        updatePlayerUnit(_buyer);
        
        require(_eth >= 1000000000, "pocket lint: not a valid currency");

        if(_date > maxInsurePeriod){
            _date = maxInsurePeriod;
        }
        uint256 _rate = rate[_date] + 1000000000000000000;
        uint256 ethToBuyKey = _eth.mul(1000000000000000000) / _rate;
         

         
        uint256 _key = ethOfKey.keysRec(ethToBuyKey);
        uint256 _unit = (_date == 0)? 0: _key;
        uint256 newDate = today + _date - 1;


         
        ethOfKey = ethOfKey.add(ethToBuyKey);
        keys = keys.add(_key);
        unitToExpire[newDate] = unitToExpire[newDate].add(_unit);
        issuedInsurance = issuedInsurance.add(_unit);

         
        player[_buyer].eth = player[_buyer].eth.add(_eth);
        player[_buyer].keys = player[_buyer].keys.add(_key);
        player[_buyer].units = player[_buyer].units.add(_unit);
        unitToExpirePlayer[_buyer][newDate] = unitToExpirePlayer[_buyer][newDate].add(_unit);

        distributeEx(_eth, _agent);
        distributeIn(_buyer, _eth, _key);
        emit BUYINSURANCE(_buyer, today, _unit, _date);
    }

     
    function updatePlayerUnit(address _player) internal {
        uint256 _today = player[_player].plyrLastSeen;
        uint256 expiredUnit = 0;
        if(_today != 0){
            while(_today < today){
                expiredUnit = expiredUnit.add(unitToExpirePlayer[_player][_today]);
                _today += 1;
            }
            player[_player].units = player[_player].units.sub(expiredUnit);
        }
        player[_player].plyrLastSeen = today;
    }

     
    function distributeEx(uint256 _eth, address _agent) internal {
        uint256 ex = _eth / 4 ;
        uint256 affRate;
        if(player[_agent].isAgent){
            affRate = player[_agent].level.add(6);
        }
        uint256 _aff = _eth.mul(affRate) / 100;
        if (_aff > 0) {
            player[_agent].aff = player[_agent].aff.add(_aff);
            player[_agent].accumulatedAff = player[_agent].accumulatedAff.add(_aff);
        }
        ex = ex.sub(_aff);
        uint256 _com = ex / 3;
        uint256 _p3d = ex.sub(_com);

        if(!community.send(_com)){
            pot = pot.add(_com);
        }
        Divies.deposit.value(_p3d)();
    }

     
    function distributeIn(address _buyer, uint256 _eth, uint256 _keys) internal {
        uint256 _gen = _eth.mul(3) / 20;

         
        _eth = _eth.sub(_eth / 4);

         
        uint256 _pot = _eth.sub(_gen);

         
         
        uint256 _dust = updateMasks(_buyer, _gen, _keys);
        if (_dust > 0)
            _gen = _gen.sub(_dust);

         
        pot = pot.add(_dust).add(_pot);
    }

    function updateMasks(address  _player, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {
         

         
        uint256 _ppt = _gen.mul(1000000000000000000) / keys;
        mask = mask.add(_ppt);

         
         
        uint256 _pearn = (_ppt.mul(_keys)) / 1000000000000000000;
        player[_player].mask = (((mask.mul(_keys)) / 1000000000000000000).sub(_pearn)).add(player[_player].mask);

         
        return(_gen.sub( _ppt.mul(keys) / 1000000000000000000));
    }

     
    function claim() isHuman() public {
        require(tick());
        address beneficiary = msg.sender;
        updatePlayerUnit(beneficiary);
        uint256 amount = pot.mul(player[beneficiary].units) / issuedInsurance;
        player[beneficiary].units = 0;
        beneficiary.transfer(amount);
    }

     
    function withdraw() isHuman() public {
         
        uint256 _eth;

         
        _eth = withdrawEarnings(msg.sender);

         
        if (_eth > 0)
            msg.sender.transfer(_eth);
    }

    function withdrawEarnings(address _player)
        private
        returns(uint256)
    {
         
        updateGenVault(_player);

         
        uint256 _earnings = player[_player].gen.add(player[_player].aff);
        if (_earnings > 0) {
            player[_player].gen = 0;
            player[_player].aff = 0;
        }

        return(_earnings);
    }

    function updateGenVault(address _player)
        private
    {
        uint256 _earnings = calcUnMaskedEarnings(_player);
        if (_earnings > 0) {
             
            player[_player].gen = _earnings.add(player[_player].gen);
             
            player[_player].mask = _earnings.add(player[_player].mask);
        }
    }

    function calcUnMaskedEarnings(address _player)
        private
        view
        returns(uint256)
    {
        return(  (mask.mul(player[_player].keys) / 1000000000000000000).sub(player[_player].mask)  );
    }

     
    function getBuyPrice() public view returns(uint256) {
        return(keys.add(1000000000000000000).ethRec(1000000000000000000));
    }

     
    function getCurrentUnit(address _player) public view returns(uint256) {
        uint256 _unit = player[_player].units;
        uint256 _today = player[_player].plyrLastSeen;
        uint256 expiredUnit = 0;
        if(_today != 0){
            while(_today < today){
                expiredUnit = expiredUnit.add(unitToExpirePlayer[_player][_today]);
                _today += 1;
            }

        }
        return( _unit == 0 ? 0 : _unit.sub(expiredUnit));
    }

     
    function getExpiringUnitListPlayer(address _player)
        public
        view
        returns(uint256[maxInsurePeriod] expiringUnitList)
    {
        for(uint256 i=0; i<maxInsurePeriod; i++) {
            expiringUnitList[i] = unitToExpirePlayer[_player][today+i];
        }
        return(expiringUnitList);
    }

     
    function getExpiringUnitList()
        public
        view
        returns(uint256[maxInsurePeriod] expiringUnitList)
    {
        for(uint256 i=0; i<maxInsurePeriod; i++){
            expiringUnitList[i] = unitToExpire[today+i];
        }
        return(expiringUnitList);
    }
}

contract FoMo3Dlong {
 
 
 
 
    uint256 public rID_;     
 
 
 
    mapping (uint256 => F3Ddatasets.Round) public round_;
}

interface DiviesInterface {
    function deposit() external payable;
}

library F3DKeysCalcLong {
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

library F3Ddatasets {
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