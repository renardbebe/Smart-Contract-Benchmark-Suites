 

pragma solidity ^0.4.24;

contract OneEther {

    event onOpenNewBet(
        uint256 indexed bID,
        address owner,
        uint256 check,
        uint256 unit,
        uint256 recordTime
    );
    event onEditBet(
        uint256 indexed bID,
        address owner,
        uint256 check,
        uint256 unit,
        uint256 recordTime
    );
    event onOpenNewRound(
        uint256 indexed bID,
        uint256 indexed rID,
        uint256 total,
        uint256 current,
        uint256 ethAmount,
        uint256 recordTime
    );
    event RoundMask(
        uint256 rID,
        bytes32 hashmask
    );
    event onReveal(
        uint256 indexed rID,
        address winner,
        uint256 reward,
        uint256 teamFee,
        uint256 scretNumber,
        uint256 randomNumber,
        uint256 recordTime
    );
    event onBuyBet(
        uint256 indexed bID,
        uint256 indexed rID,
        address playerAddress,
        uint256 amount,
        uint256 key,
        uint256 playerCode,
        uint256 invator,
        uint256 recordTime
    );

    event onRoundUpdate(
        uint256 indexed bID,
        uint256 indexed rID,
        uint256 totalKey,
        uint256 currentKey,
        uint256 lastUpdate
    );
    event onRoundEnd(
        uint256 indexed bID,
        uint256 indexed rID,
        uint256 lastUpdate
    );
    event onWithdraw
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        uint256 ethOut,
        uint256 recordTime
    );
    event onRegistLink
    (
        uint256 indexed playerID,
        address indexed playerAddress,
        uint256 recordTime
    );
    event onBuyFailed
    (
        uint256 indexed playerID,
        uint256 indexed rID,
        uint256 ethIn,
        uint256 recordTime
    );
    using SafeMath for *;

    address private owner = msg.sender;
    address private admin = msg.sender;
    bytes32 constant public name = "OneEther";
    bytes32 constant public symbol = "OneEther";
    uint256 constant  MIN_BUY = 0.001 ether;
    uint256 constant  MAX_BUY = 30000 ether;
    uint256 public linkPrice_ = 0.01 ether;
    bool public activated_ = false;
    uint256 private teamFee_ = 0;  

    uint256 public bID = 10;
    uint256 public pID = 100;
    uint256 public rID = 1000;

    mapping (address => uint256) public pIDAddr_; 
    mapping(uint256 => OneEtherDatasets.BetInfo) public bIDBet_;
    mapping(uint256 => OneEtherDatasets.stake[]) public betList_;
    mapping(uint256 => OneEtherDatasets.BetState) public rIDBet_;
    mapping(uint256 => OneEtherDatasets.Player) public pIDPlayer_;
    mapping (uint256 => uint256) public bIDrID_;
    uint256[] public bIDList_;

 
 
 
    constructor()payable public{
    }
 
 
 
     
    modifier isbetActivated(uint256 _bID){require(bIDBet_[_bID].bID != 0 && bIDBet_[_bID].isActivated == true,"cant find this bet");_;}
    modifier isActivated() {require(activated_ == true,"its not ready yet. ");_;}
     
    modifier isAdmin(){require(msg.sender == admin,"its can only be call by admin");_;}
     
    modifier isWithinLimits(uint256 _eth){require(_eth >= MIN_BUY,"too small");require(_eth <= MAX_BUY,"too big"); _;}
     
    function activate()isAdmin()public{require(activated_ == false,"the game is running");activated_ = true;}
     
    function close() isAdmin() isActivated() public{activated_ = false;}

 
 
 

     
    function setNewAdmin(address _addr)
    public
    {
        require(msg.sender == owner);
        admin = _addr;
    }

    function openNewBet(address _owner,uint256 _check,uint256 _unit)
    isAdmin()
    isActivated()
    public
    {
        require((_check >= MIN_BUY) && (_check <= MAX_BUY),"out of range");
        require((_unit * 2) <= _check,"unit of payment dennied");
        bID++;
        bIDBet_[bID].bID = bID;
        uint256 _now = now;
        if(_owner == address(0))
        {
            bIDBet_[bID].owner = admin;
        }
        else
        {
            bIDBet_[bID].owner = _owner;
        }
        bIDBet_[bID].check = _check;
        bIDBet_[bID].unit = _unit;
        bIDBet_[bID].isActivated = true;
        bIDList_.push(bID);
         
        emit onOpenNewBet(bID,bIDBet_[bID].owner,_check,_unit,_now);
    }

    function openFirstRound(uint256 _bID,bytes32 _maskHash)
    public
    isbetActivated(_bID)
    {
        address addr = msg.sender;
        require(bIDBet_[bID].bID != 0,"cant find this bet");
        require(bIDBet_[bID].owner == addr || bIDBet_[bID].owner == admin,"Permission denied");
        require(bIDrID_[_bID] == 0,"One Bet can only open one round");
        newRound(_bID,_maskHash);
    }

    function closeBet(uint256 _bID)
    public
    {
        address addr = msg.sender;
        require(bIDBet_[bID].bID != 0,"cant find this bet");
        require(bIDBet_[bID].owner == addr || bIDBet_[bID].owner == admin,"Permission denied");
         
        bIDBet_[_bID].isActivated = false;
         
    }

    function openBet(uint256 _bID)
    public
    {
        address addr = msg.sender;
        require(bIDBet_[bID].bID != 0,"cant find this bet");
        require(bIDBet_[bID].owner == addr || bIDBet_[bID].owner == admin,"Permission denied");
        require(bIDBet_[_bID].isActivated = false,"This bet is opening");
        bIDBet_[_bID].isActivated = true;
    }

    function editBet(uint256 _bID,uint256 _check,uint256 _unit)
    public
    {
        require((_check >= MIN_BUY) && (_check <= MAX_BUY),"out of range");
        address addr = msg.sender;
        require(bIDBet_[_bID].bID != 0,"cant find this bet");
        require(bIDBet_[bID].owner == addr || bIDBet_[bID].owner == admin,"Permission denied");

        bIDBet_[_bID].check = _check;
        bIDBet_[_bID].unit = _unit;
        emit onEditBet(bID,bIDBet_[bID].owner,_check,_unit,now);

    }

    function withdrawFee()
    isAdmin()
    public
    {
        uint256 temp = teamFee_;
        teamFee_ = 0;
        msg.sender.transfer(temp);
    }


 
 
 
    function buySome(uint256 _rID,uint256 _key,uint256 _playerCode,uint256 _linkPID)
    public
    payable
    {
        require(rIDBet_[_rID].rID != 0,"cant find this round");
        uint256 _bID = rIDBet_[_rID].bID;
        require(bIDBet_[_bID].bID != 0,"cant find this bet");
        require(_key <= rIDBet_[_rID].total,"key must not beyond limit");
        require(msg.value >= bIDBet_[_bID].unit,"too small for this bet");
        require(bIDBet_[_bID].unit * _key == msg.value,"not enough payment");
        require(_playerCode < 100000000000000,"your random number is too big");
        uint256 _pID = managePID(_linkPID);

        if(rIDBet_[_rID].current + _key <= rIDBet_[_rID].total)
        {
            uint256 _value = manageLink(_pID,msg.value);
            manageKey(_pID,_rID,_key);
            rIDBet_[_rID].current = rIDBet_[_rID].current.add(_key);
            rIDBet_[_rID].ethAmount = rIDBet_[_rID].ethAmount.add(_value);
            rIDBet_[_rID].playerCode = rIDBet_[_rID].playerCode.add(_playerCode);
            emit onBuyBet(_bID,_rID,pIDPlayer_[_pID].addr,_value,_key,_playerCode,pIDPlayer_[_pID].invator,now);

            if(rIDBet_[_rID].current >= rIDBet_[_rID].total)
            {
                emit onRoundEnd(_bID,_rID,now);
            }
        }
        else{
             
            pIDPlayer_[_pID].balance = pIDPlayer_[_pID].balance.add(msg.value);
            emit onBuyFailed(_pID,_rID,msg.value,now);

        }


    }

    function buyWithBalance(uint256 _rID,uint256 _key,uint256 _playerCode)
    public
    payable
    {
        uint256 _pID = pIDAddr_[msg.sender];
        require(_pID != 0,"player not founded in contract ");
        require(rIDBet_[_rID].rID != 0,"cant find this round");
        uint256 _bID = rIDBet_[_rID].bID;
        require(bIDBet_[_bID].bID != 0,"cant find this bet");

        uint256 _balance = pIDPlayer_[_pID].balance;
        require(_key <= rIDBet_[_rID].total,"key must not beyond limit");
        require(_balance >= bIDBet_[_bID].unit,"too small for this bet");
        require(bIDBet_[_bID].unit * _key <= _balance,"not enough balance");
        require(_playerCode < 100000000000000,"your random number is too big");

        require(rIDBet_[_rID].current + _key <= rIDBet_[_rID].total,"you beyond key");
        pIDPlayer_[_pID].balance = pIDPlayer_[_pID].balance.sub(bIDBet_[_bID].unit * _key);
        uint256 _value = manageLink(_pID,bIDBet_[_bID].unit * _key);
        manageKey(_pID,_rID,_key);
        rIDBet_[_rID].current = rIDBet_[_rID].current.add(_key);
        rIDBet_[_rID].ethAmount = rIDBet_[_rID].ethAmount.add(_value);
        rIDBet_[_rID].playerCode = rIDBet_[_rID].playerCode.add(_playerCode);

        emit onBuyBet(_bID,_rID,pIDPlayer_[_pID].addr,_value,_key,_playerCode,pIDPlayer_[_pID].invator,now);

        if(rIDBet_[_rID].current == rIDBet_[_rID].total)
        {
            emit onRoundEnd(_bID,_rID,now);
        }
    }

    function buyLink()
    public
    payable
    {
        require(msg.value >= linkPrice_,"not enough payment to buy link");
        uint256 _pID = managePID(0);
        pIDPlayer_[_pID].VIP = true;
        teamFee_ = teamFee_.add(msg.value);

         
        emit onRegistLink(_pID,pIDPlayer_[_pID].addr,now);

    }

    function reveal(uint256 _rID,uint256 _scretKey,bytes32 _maskHash)
    public
    {
        require(rIDBet_[_rID].rID != 0,"cant find this round");
        uint256 _bID = rIDBet_[_rID].bID;
        require(bIDBet_[_bID].bID != 0,"cant find this bet");
        require((bIDBet_[_bID].owner == msg.sender) || admin == msg.sender,"can only be revealed by admin or owner");
        bytes32 check = keccak256(abi.encodePacked(_scretKey));
        require(check == rIDBet_[_rID].maskHash,"scretKey is not match maskHash");

        uint256 modulo = rIDBet_[_rID].total;

          
        bytes32 random = keccak256(abi.encodePacked(check,rIDBet_[_rID].playerCode,(block.number + now)));
        uint result = (uint(random) % modulo) + 1;
        uint256 _winPID = 0;

        for(uint i = 0;i < betList_[_rID].length;i++)
        {
            if(result >= betList_[_rID][i].start && result <= betList_[_rID][i].end)
            {
                _winPID = betList_[_rID][i].pID;
                break;
            }
        }
         
        uint256 reward = rIDBet_[_rID].ethAmount;
        uint256 teamFee = (bIDBet_[_bID].check.mul(3))/100;
        pIDPlayer_[_winPID].balance = pIDPlayer_[_winPID].balance.add(reward);
         
        emit onReveal(_rID,pIDPlayer_[_winPID].addr,reward,teamFee,_scretKey,result,now);

         
        delete rIDBet_[_rID];
        delete betList_[_rID];
        bIDrID_[_bID] = 0;

         
        newRound(_bID,_maskHash);
    }

    function getPlayerByAddr(address _addr)
    public
    view
    returns(uint256,uint256,bool)
    {
        uint256 _pID = pIDAddr_[_addr];
        return (_pID,pIDPlayer_[_pID].balance,pIDPlayer_[_pID].VIP);
    }

    function getRoundInfoByID(uint256 _rID)
    public
    view
    returns(uint256,uint256,uint256,uint256,uint256,bytes32,uint256)
    {
        return
        (
            rIDBet_[_rID].rID,                
            rIDBet_[_rID].bID,                
            rIDBet_[_rID].total,              
            rIDBet_[_rID].current,            
            rIDBet_[_rID].ethAmount,          
            rIDBet_[_rID].maskHash,           
            rIDBet_[_rID].playerCode      
            );
    }

    function getBetInfoByID(uint256 _bID)
    public
    view
    returns(uint256,uint256,address,uint256,uint256,bool)
    {
        return
        (
            bIDrID_[_bID],  
            bIDBet_[_bID].bID,
            bIDBet_[_bID].owner,
            bIDBet_[_bID].check,
            bIDBet_[_bID].unit,
            bIDBet_[_bID].isActivated
            );
    }

    function getBIDList()
    public
    view
    returns(uint256[])
    {return(bIDList_);}


    function withdraw()
    isActivated()
    public
    {
        uint256 _now = now;
        uint256 _pID = pIDAddr_[msg.sender];
        uint256 _eth;

        if(_pID != 0)
        {
            _eth = withdrawEarnings(_pID);
            require(_eth > 0,"no any balance left");
            pIDPlayer_[_pID].addr.transfer(_eth);

            emit onWithdraw(_pID,msg.sender,_eth,_now);
        }
    }



 
 
 


    function manageKey(uint256 _pID,uint256 _rID,uint256 _key)
    private
    {
        uint256 _current = rIDBet_[_rID].current;

        OneEtherDatasets.stake memory _playerstake = OneEtherDatasets.stake(0,0,0);
        _playerstake.start = _current + 1;
        _playerstake.end = _current + _key;
        _playerstake.pID = _pID;

        betList_[_rID].push(_playerstake);

    }

    function manageLink(uint256 _pID,uint256 _value)
    private
    returns(uint256)
    {
        uint256 cut = (_value.mul(3))/100; 
        uint256 _value2 = _value.sub(cut);

        uint256 _invator = pIDPlayer_[_pID].invator;
        if(_invator != 0)
        {
            uint256 cut2 = (cut.mul(60))/100;  
            cut = cut.sub(cut2);
            pIDPlayer_[_invator].balance = pIDPlayer_[_invator].balance.add(cut2);
        }

        teamFee_ = teamFee_.add(cut);
        return _value2;
    }

    function managePID(uint256 _linkPID)
    private
    returns (uint256)
    {
        uint256 _pID = pIDAddr_[msg.sender];

        if(_pID == 0)
        {
             
            pID++;
            pIDAddr_[msg.sender] = pID;


             
            pIDPlayer_[pID].addr = msg.sender;
            pIDPlayer_[pID].balance = 0;
            pIDPlayer_[pID].VIP = false;

            if(pIDPlayer_[_linkPID].addr != address(0) && pIDPlayer_[_linkPID].VIP == true)
            {
                pIDPlayer_[pID].invator = _linkPID;
            }

            return (pID);
        }

        else{
            return (_pID);
        }

    }



    function newRound(uint256 _bID,bytes32 _maskHash)
    private
    {
        uint256 _total = bIDBet_[_bID].check / bIDBet_[_bID].unit;
        if(bIDBet_[_bID].isActivated == true)
        {
            rID++;
            rIDBet_[rID].rID = rID;
            rIDBet_[rID].bID = _bID;
            rIDBet_[rID].total = _total;
            rIDBet_[rID].current = 0;
            rIDBet_[rID].ethAmount = 0;
            rIDBet_[rID].maskHash = _maskHash;
            rIDBet_[rID].playerCode = 0;

            bIDrID_[_bID] = rID;
            emit onOpenNewRound(_bID,rID,rIDBet_[rID].total,rIDBet_[rID].current,rIDBet_[rID].ethAmount,now);
            emit RoundMask(rID,_maskHash);
        }
        else
        {
            bIDrID_[_bID] = 0;
        }

    }

    function withdrawEarnings(uint256 _pID)
        private
        returns(uint256)
    {
        uint256 _earnings = pIDPlayer_[_pID].balance;
        if (_earnings > 0)
        {
            pIDPlayer_[_pID].balance = 0;
        }

        return(_earnings);
    }
}

library OneEtherDatasets {

    struct BetInfo {
        uint256 bID;
        address owner;
        uint256 check;
        uint256 unit;
        bool isActivated;
    }

    struct BetState{
        uint256 rID;
        uint256 bID;
        uint256 total;
        uint256 current;
        uint256 ethAmount;
        bytes32 maskHash;
        uint256 playerCode;
    }

    struct Player{
        address addr;
        uint256 balance;
        uint256 invator;
        bool VIP;
    }

    struct stake{
        uint256 start;
        uint256 end;
        uint256 pID;
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
            for (uint256 i = 1;i < y;i++)
                z = mul(z,x);
            return (z);
        }
    }
}