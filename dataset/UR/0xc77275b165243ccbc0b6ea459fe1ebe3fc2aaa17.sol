 

pragma solidity ^0.4.24;

 

contract GameX {
    using SafeMath for uint256;
    string public name = "GameX";     
    string public symbol = "nox";
    
     
    mapping(address => bool) admins;
    bool public activated = false;
    uint public compot;
    
     
    uint minFee = 0.01 ether;
    uint maxFee = 1 ether;
    uint minLucky = 0.1 ether;
    uint retryfee = 0.1 ether;
    uint16 public luckynum = 2;
    uint16 public fuckynum = 90;
    uint lastnumtime = now;
    
     
    uint public noncex = 1;
    
    uint public timeslucky;
    uint public times6;
    uint public times7;
    uint public times8;
    uint public times9;
    uint public timesno;
    uint public timesfucky;
    uint16 public limit6 = 79;
    uint16 public limit7 = 86;
    uint16 public limit8 = 92;
    uint16 public limit9 = 97;
    uint16 public reward6 = 11;
    uint16 public reward7 = 13;
    uint16 public reward8 = 16;
    uint16 public reward9 = 23;
    uint16 public inmax = 100;
    
     
    uint private lastPlayer;
    
    uint public jackpot = 0;  
    uint public maskpot = 0;  
    uint public gameTotalGen = 0;
    
    uint public _iD;
    mapping(address => player) public player_;
    mapping(uint => address) public addrXid;
    
    struct player {
        uint16[] playerNum;   
        uint16 playerTotal;   
        uint id;
        uint playerWin;       
        uint playerGen;       
        uint playerWinPot;    
        uint RetryTimes;      
        uint lastRetryTime;   
        bool hasRetry;        
        address Aff;          
        uint totalGen;
        bool hasAddTime;
    }
    
    constructor()
    {
        admins[address(msg.sender)] = true;
        admins[0x8f92200dd83e8f25cb1dafba59d5532507998307] = true;
        admins[0x9656DDAB1448B0CFbDbd71fbF9D7BB425D8F3fe6] = true;
    }
    
    modifier isActivated() {
        require(activated, "not ready yet");
        _;
    }
    
    modifier isHuman() {
        address _addr = msg.sender;
        require(_addr == tx.origin);
        
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    modifier validAff(address _addr) {
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    modifier onlyOwner() {
        require(admins[msg.sender], "only admin");
        _;
    }
    
     
    function()
    public
    payable
    {
        compot += msg.value;
    }
    
    function getPlayerNum() constant public returns (uint16[]) {
        return player_[msg.sender].playerNum;
    }
    
    function getPlayerWin(address _addr) public view returns (uint, uint) {
        if (gameTotalGen == 0)
        {
            return (player_[_addr].playerWinPot, 0);
        }
        return (player_[_addr].playerWinPot, maskpot.mul(player_[_addr].totalGen).div(gameTotalGen));
    }
    
    function isLuckyGuy()
    private
    view
    returns (uint8)
    {
        if (player_[msg.sender].playerTotal == luckynum || player_[msg.sender].playerTotal == 100) {
            return 5;
        }
        
        uint8 _retry = 0;
        if (player_[msg.sender].hasRetry){
            _retry = 1;
        }
        if (player_[msg.sender].playerTotal <= 33 && player_[msg.sender].playerNum.length.sub(_retry) >= 3) {
            return 10;
        }
        return 0;
    }
    
    function Card(uint8 _num, bool _retry, address _ref)
    isActivated
    isHuman
    validAff(_ref)
    public
    payable
    {
        require(msg.value > 0);
        uint256 amount = msg.value;
        
        if (player_[msg.sender].playerGen == 0)
        {
            player_[msg.sender].playerNum.length = 0;
        }
        
         
        
        if (player_[msg.sender].id == 0)
        {
            _iD ++;
            player_[msg.sender].id = _iD;
            addrXid[_iD] = msg.sender;
        }
        
         
        if (amount < minFee * _num || amount > maxFee * _num) {
            compot += amount;
            return;
        }
        
        if (player_[msg.sender].playerGen > 0)
        {
             
            require(player_[msg.sender].playerGen.mul(inmax).mul(_num) >= amount);
        }
        
        if (_retry && _num == 1) {
            if (admins[msg.sender]==false){
                require(
                    player_[msg.sender].playerNum.length > 0 &&
                    player_[msg.sender].hasRetry == false &&  
                    player_[msg.sender].RetryTimes > 0 &&  
                    player_[msg.sender].lastRetryTime <= (now - 1 hours),  
                    'retry fee need to be valid'
                );
            }else{
                 
                player_[msg.sender].RetryTimes ++;
            }
            
            player_[msg.sender].hasRetry = true;
            player_[msg.sender].RetryTimes --;
            player_[msg.sender].lastRetryTime = now;
            
            uint16 lastnum = player_[msg.sender].playerNum[player_[msg.sender].playerNum.length - 1];
            player_[msg.sender].playerTotal -= lastnum;
            player_[msg.sender].playerNum.length = player_[msg.sender].playerNum.length - 1;
             
            player_[msg.sender].playerNum.push(100 + lastnum);
        }
        
        compot += amount.div(100);
        
         
        jackpot += amount.sub(amount.div(100));
        
        player_[msg.sender].playerGen += amount.sub(amount.div(100));
        
         
         
         
        if (
            player_[msg.sender].Aff == address(0x0) &&
            _ref != address(0x0) &&
            _ref != msg.sender &&
            player_[_ref].id > 0
        )
        {
            player_[msg.sender].Aff = _ref;
        }
        
         
        for (uint16 i = 1; i <= _num; i++) {
            uint16 x = randomX(i);
             
            player_[msg.sender].playerNum.push(x);
            player_[msg.sender].playerTotal += x;
        }
        
         
        uint16 _case = isLuckyGuy();
        if (_case > 0) {
            timeslucky ++;
             
            player_[msg.sender].playerWin = player_[msg.sender].playerGen.mul(36).div(10);
            if (amount >= minLucky) {
                player_[msg.sender].playerWin += jackpot.mul(_case).div(100);
            }
            endRound();
            return;
        }
        
         
        if (player_[msg.sender].playerTotal > 100 || player_[msg.sender].playerTotal == fuckynum) {
            timesno ++;
             
            uint tocom = player_[msg.sender].playerGen.div(50);
            compot += tocom;
            subJackPot(tocom);
            
            if (player_[msg.sender].playerTotal == fuckynum)
                timesfucky++;
            
            player_[msg.sender].playerWin = 0;
            endRound();
            return;
        }
        
        if (player_[msg.sender].playerTotal > limit9) {
            times9 ++;
            player_[msg.sender].playerWin = player_[msg.sender].playerGen.mul(reward9).div(10);
            return;
        }
        
        if (player_[msg.sender].playerTotal > limit8) {
            times8 ++;
            player_[msg.sender].playerWin = player_[msg.sender].playerGen.mul(reward8).div(10);
            return;
        }
        
        if (player_[msg.sender].playerTotal > limit7) {
            times7 ++;
            player_[msg.sender].playerWin = player_[msg.sender].playerGen.mul(reward7).div(10);
            return;
        }
        
        if (player_[msg.sender].playerTotal > limit6) {
            times6 ++;
            player_[msg.sender].playerWin = player_[msg.sender].playerGen.mul(reward6).div(10);
        }
    }
    
    event resultlog(address indexed user, uint16[] num, uint16 indexed total, uint gen, uint win, uint time, uint16 luckynum, uint16 fuckynum);
    
    function resetPlayer()
    isActivated
    isHuman
    private
    {
        emit resultlog(
            msg.sender,
            player_[msg.sender].playerNum,
            player_[msg.sender].playerTotal,
            player_[msg.sender].playerGen,
            player_[msg.sender].playerWin,
            now,
            luckynum,
            fuckynum
        );
         
        player_[msg.sender].totalGen += player_[msg.sender].playerGen;
        gameTotalGen += player_[msg.sender].playerGen;
        if (
            player_[msg.sender].Aff != address(0x0) &&
            player_[msg.sender].hasAddTime == false &&
            player_[msg.sender].totalGen > retryfee
        ) {
            player_[player_[msg.sender].Aff].RetryTimes++;
            player_[player_[msg.sender].Aff].hasAddTime = true;
        }
        
        player_[msg.sender].playerGen = 0;
        
        player_[msg.sender].playerTotal = 0;
        
         
        
        player_[msg.sender].hasRetry = false;
        
         
        player_[msg.sender].playerWinPot += player_[msg.sender].playerWin;
        
        player_[msg.sender].playerWin = 0;
        
        if (luckynum == 0 || lastnumtime + 1 hours <= now) {
            luckynum = randomX(luckynum);
            lastnumtime = now;
            fuckynum ++;
            if (fuckynum >= 99)
                fuckynum = 85;
        }
    }
    
    function subJackPot(uint _amount)
    private
    {
        if (_amount < jackpot) {
            jackpot = jackpot.sub(_amount);
        } else {
            jackpot = 0;
        }
    }
    
    function endRound()
    isActivated
    isHuman
    public
    {
        if (player_[msg.sender].playerTotal == 0) {
            return;
        }
        
        if (player_[msg.sender].playerTotal <= limit8 && player_[msg.sender].playerWin == 0) {
            player_[msg.sender].playerWin = player_[msg.sender].playerGen.div(3);
        }
        
        subJackPot(player_[msg.sender].playerWin);
        resetPlayer();
    }
    
    function withdraw()
    isActivated
    isHuman
    public
    payable
    {
        (uint pot, uint mask) = getPlayerWin(msg.sender);
        uint amount = pot + mask;
        require(amount > 0, 'sorry not enough eth to withdraw');
        
        if (amount > address(this).balance)
            amount = address(this).balance;
        
        msg.sender.transfer(amount);
        player_[msg.sender].playerWinPot = 0;
        player_[msg.sender].totalGen = 0;
        
        maskpot = maskpot.sub(mask);
    }
    
    
    event randomlog(address addr, uint16 x);
    
    function randomX(uint16 _s)
    private
    returns (uint16)
    {
        uint256 x = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                (block.number).add
                (lastPlayer).add
                (gasleft()).add
                (block.gaslimit).add
                (noncex).add
                (_s)
            )));
         
        
        x = x - ((x / 100) * 100);
        
        if (x > 50) {
            lastPlayer = player_[msg.sender].id;
        } else {
            noncex ++;
            if (noncex > 1000000000)
                noncex = 1;
        }
        
        if (x == 0) {
            x = 1;
        }
        emit randomlog(msg.sender, uint16(x));
        return uint16(x);
    }
    
     
    function active()
    onlyOwner
    public
    {
        activated = true;
    }
    
    function setAdmin(address _addr)
    onlyOwner
    public
    {
        admins[_addr] = true;
    }
    
    function withCom(address _addr)
    onlyOwner
    public
    {
        uint _com = compot;
        if (address(this).balance < _com)
            _com = address(this).balance;
        
        compot = 0;
        _addr.transfer(_com);
    }
    
    function openJackPot(uint amount)
    onlyOwner
    public
    {
        require(amount <= jackpot);
        
        maskpot += amount;
        jackpot -= amount;
    }
    
     
    function resetTime(uint16 r6,uint16 r7,uint16 r8, uint16 r9, uint16 l6,uint16 l7,uint16 l8, uint16 l9,uint max,uint16 _inmax)
    onlyOwner
    public {
        times6 = 0;
        times7 = 0;
        times8 = 0;
        times9 = 0;
        timeslucky = 0;
        timesfucky = 0;
        timesno = 0;
        if (r6 > 0)
            reward6 = r6;
        if (r7 > 0)
            reward7 = r7;
        if (r8 > 0)
            reward8 = r8;
        if (r9 > 0)
            reward9 = r9;
        if (l6 > 0)
            limit6 = l6;
        if (l7 > 0)
            limit7 = l7;
        if (l8 > 0)
            limit8 = l8;
        if (l9 > 0)
            limit9 = l9;
        if (max > 1)
            maxFee = max;
        if (inmax >= 3)
            inmax =_inmax;
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
    
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
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
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }
    
     
    function sq(uint256 x)
    internal
    pure
    returns (uint256)
    {
        return (mul(x, x));
    }
    
     
    function pwr(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
    {
        if (x == 0)
            return (0);
        else if (y == 0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i = 1; i < y; i++)
                z = mul(z, x);
            return (z);
        }
    }
}