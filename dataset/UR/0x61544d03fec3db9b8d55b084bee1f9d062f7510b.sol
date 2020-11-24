 

pragma solidity ^0.4.24;
 

 
 
 
 
contract LuckyEvents {
     
    event onEndTx
    (
        address player,
        uint256 playerID,
        uint256 ethIn,
        address wonAddress,
        uint256 wonAmount,           
        uint256 genAmount,           
        uint256 airAmount           
    );
    
	 
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        uint256 ethOut,
        uint256 timeStamp
    );
}

 
 
 
 
library LuckyDatasets {
    struct EventReturns {
        address player;
        uint256 playerID;
        uint256 ethIn;
        address wonAddress;          
        uint256 wonAmount;           
        uint256 genAmount;           
        uint256 airAmount;           
    }
}


 
contract Ownable {
  address public owner;

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract LuckyETH is LuckyEvents, Ownable  {
    using SafeMath for *;
    
 
 
 
 
    string constant public name = "Lucky ETH";
    string constant public symbol = "L";
 
 
 
    uint256 public pIndex;  
 
 
 
 
	uint256 public genPot_;              
 
 
 
 
	uint256 public airDropPot_;              
    uint256 public airDropTracker_ = 0;      
 
 
 
    mapping (address => uint256) public pIDxAddr_;           
    mapping (address => address) public pAff_;               
 
 
 
     
    address public teamV;
 
 
 
 
    constructor()
        public
    {
         
        pIndex = 1;
	}

 
 
 
 
     
    modifier isHuman() {
        address _addr = msg.sender;
        require (_addr == tx.origin);
        
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");  
        require(_eth <= 100000000000000000000000, "no vitalik, no");     
		_;    
	}
	
 
 
 
 

    function ()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        address _affAddr = address(0);
        if (pAff_[msg.sender] != address(0)) {
            _affAddr = pAff_[msg.sender];
        }
        core(msg.sender, msg.value, _affAddr);
    }
    
     
    function buy(address _affAddr)
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        if (_affAddr == address(0)) {
            _affAddr = pAff_[msg.sender];
        } else {
            pAff_[msg.sender] = _affAddr;
        }
        core(msg.sender, msg.value, _affAddr);
    }
    
     
    function withdraw()
        isHuman()
        public
    {
       playerWithdraw(msg.sender);
    }
    
     
    function updateTeamV(address _team)
        onlyOwner()
        public
    {
        if (teamV != address(0)) {
           playerWithdraw(teamV);
        }
        core(_team, 0, address(0));
        teamV = _team;
    }
    
     
    function core(address _pAddr, uint256 _eth, address _affAddr)
        private
    {
         
        LuckyDatasets.EventReturns memory _eventData_;
        _eventData_.player = _pAddr;
        
        uint256 _pID =  pIDxAddr_[_pAddr];
        if (_pID == 0) {
            _pID = pIndex;
            pIndex = pIndex.add(1);
            pIDxAddr_[_pAddr] = _pID;
        }
         _eventData_.playerID = _pID;
         _eventData_.ethIn = _eth;
        
         
        if (_eth >= 100000000000000000)
        {
            airDropTracker_++;
            if (airdrop() == true)
            {
                 
                uint256 _prize = 0;
                if (_eth >= 10000000000000000000)
                {
                     
                    _prize = ((airDropPot_).mul(75)) / 100;
                } else if (_eth >= 1000000000000000000 && _eth < 10000000000000000000) {
                     
                    _prize = ((airDropPot_).mul(50)) / 100;
                } else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) {
                     
                    _prize = ((airDropPot_).mul(25)) / 100;
                }
                
                 
                airDropPot_ = (airDropPot_).sub(_prize);
                    
                 
                _pAddr.transfer(_prize);
                    
                 
                _eventData_.wonAddress = _pAddr;
                 
                _eventData_.wonAmount = _prize;
                
                
                 
                airDropTracker_ = 0;
            }
        }
        
         
        uint256 _aff = _eth / 5;
         
        uint256 _gen = _eth.mul(30) / 100;
         
        uint256 _airDrop = _eth.sub(_aff.add(_gen));
       
         
        uint256 _affID = pIDxAddr_[_affAddr];
        if (_affID != 0 && _affID != _pID) {
            _affAddr.transfer(_aff);
        } else {
            _airDrop = _airDrop.add(_aff);
        }

        airDropPot_ = airDropPot_.add(_airDrop);
        genPot_ = genPot_.add(_gen);

         
        _eventData_.genAmount = _gen;
        _eventData_.airAmount = _airDrop;

         
        endTx(_eventData_);
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
        if((seed - ((seed / 1000) * 1000)) <= airDropTracker_)
            return(true);
        else
            return(false);
    }
    
     
    function endTx(LuckyDatasets.EventReturns memory _eventData_)
        private
    {
        emit LuckyEvents.onEndTx
        (
            _eventData_.player,
            _eventData_.playerID,
            _eventData_.ethIn,
            _eventData_.wonAddress,
            _eventData_.wonAmount,
            _eventData_.genAmount,
            _eventData_.airAmount
        );
    }
    
       
    function playerWithdraw(address _pAddr)
        private
    {
         
        uint256 _now = now;
        
         
        uint256 _pID =  pIDxAddr_[_pAddr];
        require(_pID != 0, "no, no, no...");
        delete(pIDxAddr_[_pAddr]);
        delete(pAff_[_pAddr]);
        pIDxAddr_[_pAddr] = 0;  
        
          
        LuckyDatasets.EventReturns memory _eventData_;
        _eventData_.player = _pAddr;
        
         
        uint256 _pIndex = pIndex;
        uint256 _gen = genPot_;
        uint256 _sum = _pIndex.mul(_pIndex.sub(1)) / 2;
        uint256 _percent = _pIndex.sub(1).sub(_pID);
        assert(_percent < _pIndex);
        _percent = _gen.mul(_percent) / _sum;
        
        genPot_ = genPot_.sub(_percent);
        _pAddr.transfer(_percent);
        
        
         
        emit LuckyEvents.onWithdraw(_pID, _pAddr, _percent, _now);
        
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