 

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

contract Draw {
    using SafeMath for *;

    event JoinRet(bool ret, uint256 inviteCode, address addr);
    event InviteEvent(address origin, address player);
    event Result(uint256 roundId, uint256 ts, uint256 amount, address winnerPid, uint256 winnerValue, address mostInvitePid, 
    uint256 mostInviteValue, address laffPid, uint256 laffValue);
    event RoundStop(uint256 roundId);

    struct Player {
        address addr;    
        uint256 vault;     
        uint256 totalVault;
        uint256 laff;    
        uint256 joinTime;  
        uint256 drawCount;  
        uint256 remainInviteCount; 
        uint256 inviteDraw;   
        bool selfDraw;  
        uint256 inviteCode; 
        uint256 inviteCount;  
        uint256 newInviteCount;  
        uint256 inviteTs;  
         
    }
    
    mapping (address => uint256) public pIDxAddr_;  
    mapping (uint256 => uint256) public pIDxCount_;  

    uint256 public totalPot_ = 0;
    uint256 public beginTime_ = 0;
    uint256 public endTime_ = 0;
    uint256 public pIdIter_ = 0;   
    uint256 public fund_  = 0;   

     
    uint64 public times_ = 0;   
    uint256 public drawNum_ = 0;  

    mapping (uint256 => uint256) pInvitexID_;   
    
    mapping (bytes32 => address) pNamexAddr_;   
    mapping (uint256 => Player) public plyr_;  
    
    mapping (address => uint256) pAddrxFund_;  

    uint256[3] public winners_;   

    uint256 public dayLimit_;  

    uint256[] public joinPlys_;

    uint256 public inviteIter_;  

    uint256 public roundId_ = 0; 

     
    uint256 public constant gapTime_ = 24 hours;

    address private owner_;
    
    constructor () public {
        beginTime_ = now;
        endTime_ = beginTime_ + gapTime_;
        roundId_ = 1;
        owner_ = msg.sender;
    }

     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    uint256 public newMostInviter_ = 0;
    uint256 public newMostInviteTimes_ = 0;
    function determineNewRoundMostInviter (uint256 pid, uint256 times) 
        private
    {
        if (times > newMostInviteTimes_) {
            newMostInviter_ = pid;
            newMostInviteTimes_ = times;
        }
    }

    function joinDraw(uint256 _affCode) 
        public
        isHuman() 
    {
        uint256 _pID = determinePID();
        Player storage player = plyr_[_pID];

          
        if (_affCode != 0 && _affCode != plyr_[_pID].inviteCode && player.joinTime == 0) {
            uint256 _affPID = pInvitexID_[_affCode];
            if (_affPID != 0) {
                Player storage laffPlayer = plyr_[_affPID];
                laffPlayer.inviteCount = laffPlayer.inviteCount + 1;
                laffPlayer.remainInviteCount = laffPlayer.remainInviteCount + 1;

                if (laffPlayer.inviteTs < beginTime_) {
                    laffPlayer.newInviteCount = 0;
                }
                laffPlayer.newInviteCount += 1;
                laffPlayer.inviteTs = now;
                player.laff = _affCode;
                determineNewRoundMostInviter(_affPID, laffPlayer.newInviteCount);

                emit InviteEvent(laffPlayer.addr, player.addr);
            }
        }

        if (player.joinTime <= beginTime_) {
            player.drawCount = 0;
            player.selfDraw = false;
        } 

        bool joinRet = false;
        if (player.drawCount < 5) {
             
            require((player.selfDraw == false || player.remainInviteCount > 0), "have no chance times");
             

            uint256 remainCount = 5 - player.drawCount;
             
            require(remainCount > 0, "have no chance times 2");
             

            uint256 times = 0;
            if (player.selfDraw == true) {
                if (player.remainInviteCount >= remainCount) {
                    player.remainInviteCount = player.remainInviteCount - remainCount;
                    times = remainCount;
                    player.inviteDraw = player.inviteDraw + remainCount;
                } else {
                    times = player.remainInviteCount;
                    player.remainInviteCount = 0;
                    player.inviteDraw = player.inviteDraw + player.remainInviteCount;
                }
            } else {
                if (player.remainInviteCount + 1 >= remainCount) {
                    player.remainInviteCount = player.remainInviteCount - remainCount + 1;
                    times = remainCount;
                    player.selfDraw = true;
                    player.inviteDraw = player.inviteDraw + remainCount - 1;
                } else {
                    times = 1 + player.remainInviteCount;
                    player.remainInviteCount = 0;
                    player.selfDraw = true;
                    player.inviteDraw = player.inviteDraw + player.remainInviteCount;
                }
            }

            joinRet = true;
            player.joinTime = now;

            player.drawCount += times;
            times = times > 5 ? 5 : times;
            while(times > 0) {
                joinPlys_.push(_pID);
                times--;
            } 
            emit JoinRet(true, player.inviteCode, player.addr);
        } else {
            emit JoinRet(false, player.inviteCode, player.addr);
        }
         
    }

    function roundEnd() private {
        emit RoundStop(roundId_);
    }

    function charge()
        public
        isHuman() 
        payable
    {
        uint256 _eth = msg.value;
        fund_ = fund_.add(_eth);
    }

    function setParam(uint256 dayLimit) public {
         
        require (
            msg.sender == 0xf8636155ab3bda8035b02fc92b334f3758b5e1f3 ||
            msg.sender == 0x0421b755b2c7813df34f8d9b81065f81b5a28d80 || 
            msg.sender == 0xf6eac1c72616c4fd2d389a8836af4c3345d79d92,
            "only amdin can do this"
        );

        dayLimit_ = dayLimit;
    }

    modifier havePlay() {
        require (joinPlys_.length > 0, "must have at least 1 player");
        _;
    } 

    function random() 
        private
        havePlay()
        view
        returns(uint256)
    {
        uint256 _seed = uint256(keccak256(abi.encodePacked(
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));

        require(joinPlys_.length != 0, "no one join draw");

        uint256 _rand = _seed % joinPlys_.length;
        return _rand;
    }

    function joinCount() 
        public 
        view 
        returns (uint256)
    {
        return joinPlys_.length;
    }

    modifier haveFund() {
        require (fund_ > 0, "fund must more than 0");
        _;
    }
    
     
    function onDraw() 
        public
        haveFund() 
    {
         
        require (
            msg.sender == 0xf8636155ab3bda8035b02fc92b334f3758b5e1f3 ||
            msg.sender == 0x0421b755b2c7813df34f8d9b81065f81b5a28d80 || 
            msg.sender == 0xf6eac1c72616c4fd2d389a8836af4c3345d79d92,
            "only amdin can do this"
        );

        require(joinPlys_.length > 0, "no one join draw");
        require (fund_ > 0, "fund must more than zero");

        if (dayLimit_ == 0) {
            dayLimit_ = 0.1 ether;
        }
        
        winners_[0] = 0;
        winners_[1] = 0;
        winners_[2] = 0;

        uint256 _rand = random();
        uint256 _winner =  joinPlys_[_rand];

        winners_[0] = _winner;
        winners_[1] = newMostInviter_;
        winners_[2] = plyr_[_winner].laff;

        uint256 _tempValue = 0;
        uint256 _winnerValue = 0;
        uint256 _mostInviteValue = 0;
        uint256 _laffValue = 0;
        uint256 _amount = 0;
        address _winAddr;
        address _mostAddr;
        address _laffAddr;
         
        if (fund_ >= dayLimit_) {
            _amount = dayLimit_;
            fund_ = fund_.sub(dayLimit_);
            _winnerValue = dayLimit_.mul(7).div(10);
            _mostInviteValue = dayLimit_.mul(2).div(10);
            _laffValue = dayLimit_.div(10);
            plyr_[winners_[0]].vault = plyr_[winners_[0]].vault.add(_winnerValue);
            plyr_[winners_[0]].totalVault = plyr_[winners_[0]].totalVault.add(_winnerValue);
            _winAddr = plyr_[winners_[0]].addr;
            if (winners_[1] == 0) {
                _mostInviteValue = 0;
            } else {
                _mostAddr = plyr_[winners_[1]].addr;
                plyr_[winners_[1]].vault = plyr_[winners_[1]].vault.add(_mostInviteValue);
                plyr_[winners_[1]].totalVault = plyr_[winners_[1]].totalVault.add(_mostInviteValue);
            }
            if (winners_[2] == 0) { 
                _laffValue = 0;
            } else {
                _laffAddr = plyr_[winners_[2]].addr;
                plyr_[winners_[2]].vault = plyr_[winners_[2]].vault.add(_laffValue);
                plyr_[winners_[2]].totalVault = plyr_[winners_[2]].totalVault.add(_laffValue);
            
            }
        } else {
            _amount = fund_;
            _tempValue = fund_;
            fund_ = 0;
            _winnerValue = _tempValue.mul(7).div(10);
            _mostInviteValue = _tempValue.mul(2).div(10);
            _laffValue = _tempValue.div(10);
            plyr_[winners_[0]].vault = plyr_[winners_[0]].vault.add(_winnerValue);
            plyr_[winners_[0]].totalVault = plyr_[winners_[0]].totalVault.add(_winnerValue);
            _winAddr = plyr_[winners_[0]].addr;
            if (winners_[1] == 0) {
                _mostInviteValue = 0;
            } else {
                _mostAddr = plyr_[winners_[1]].addr;
                plyr_[winners_[1]].vault = plyr_[winners_[1]].vault.add(_mostInviteValue);
                plyr_[winners_[1]].totalVault = plyr_[winners_[1]].totalVault.add(_mostInviteValue);
           
            }
            if (winners_[2] == 0) {
                _laffValue = 0;
            } else {
                plyr_[winners_[2]].vault = plyr_[winners_[2]].vault.add(_laffValue);
                plyr_[winners_[2]].totalVault = plyr_[winners_[2]].totalVault.add(_laffValue);
                _laffAddr = plyr_[winners_[2]].addr;
            }
        }

        emit Result(roundId_, endTime_, _amount, _winAddr, _winnerValue, _mostAddr, _mostInviteValue, _laffAddr, _laffValue);

        nextRound();
    }

    function nextRound() 
        private 
    {
        beginTime_ = now;
        endTime_ = now + gapTime_;

        delete joinPlys_;
        
        newMostInviteTimes_ = 0;
        newMostInviter_ = 0;

        roundId_++;
        beginTime_ = now;
        endTime_ = beginTime_ + gapTime_;
    }

    function withDraw()
        public 
        isHuman()
        returns(bool) 
    {
        uint256 _now = now;
        uint256 _pID = determinePID();
        
        if (_pID == 0) {
            return;
        }
        
        if (endTime_ > _now && fund_ > 0) {
            roundEnd();
        }

        if (plyr_[_pID].vault != 0) {
            uint256 vault = plyr_[_pID].vault;
            plyr_[_pID].vault = 0;
            msg.sender.transfer(vault);
        }

        return true;
    }

    function getRemainCount(address addr) 
        public
        view
        returns(uint256)  
    {
        uint256 pID = pIDxAddr_[addr];
        if (pID == 0) {
            return 1;
        }
        
        uint256 remainCount = 0;

        if (plyr_[pID].joinTime <= beginTime_) {
            remainCount = plyr_[pID].remainInviteCount < 4 ? plyr_[pID].remainInviteCount + 1 : 5;
        } else {
            if (plyr_[pID].remainInviteCount == 0) {
                remainCount = (plyr_[pID].drawCount == 0 ? 1 : 0);
            } else {
                if (plyr_[pID].drawCount >= 5) {
                    remainCount = 0;
                } else {
                    uint256 temp = (5 - plyr_[pID].drawCount);
                    remainCount = (plyr_[pID].remainInviteCount > temp ? temp :  plyr_[pID].remainInviteCount);
                }
            }  
        } 

        return remainCount;
    }

      
    function determinePID()
        private
        returns(uint256)
    {
        uint256 _pID = pIDxAddr_[msg.sender];

        if (_pID == 0) {
            pIdIter_ = pIdIter_ + 1;
            _pID = pIdIter_;
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;
            inviteIter_ = inviteIter_.add(1);
            plyr_[_pID].inviteCode = inviteIter_;
            pInvitexID_[inviteIter_] = _pID;
        }

        return _pID;
    }
}