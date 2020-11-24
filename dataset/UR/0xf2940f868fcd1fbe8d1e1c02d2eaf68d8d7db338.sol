 

pragma solidity ^0.4.24;
 

interface PlayerBookReceiverInterface {
    function receivePlayerInfo(uint256 _pID, address _addr) external;
}

contract PlayerBook {
    using SafeMath for uint256;

    address private admin = msg.sender;
     
     
     
     
     
    mapping(uint256 => PlayerBookReceiverInterface) public games_;
    mapping(address => uint256) public gameIDs_;             
    uint256 public gID_;         
    uint256 public pID_;         
    mapping (address => uint256) public pIDxAddr_;           
    mapping (uint256 => Player) public plyr_;                
    mapping (uint256 => uint256) public refIDxpID_;

    struct Player {
        address addr;
    }
     
     
     
     
    constructor()
    public
    {
        plyr_[1].addr = 0x5838463c93100c48324bF56a4Ecd2cD378caCa7D;
        pIDxAddr_[0x5838463c93100c48324bF56a4Ecd2cD378caCa7D] = 1;
         
        plyr_[2].addr = 0x4d20f551f4509BBdb5a3807e9A706b4fC411eD31;
        pIDxAddr_[0x4d20f551f4509BBdb5a3807e9A706b4fC411eD31] = 2;

         
        pID_ = 2;

    }
     
     
     
     
     
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    modifier isRegisteredGame()
    {
        require(gameIDs_[msg.sender] != 0);
        _;
    }
     
     
     
     
     
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

     
     
     
     


     
     
     
     
    function determinePID(address _addr)
    private
    returns (bool)
    {
        if (pIDxAddr_[_addr] == 0)
        {
            pID_++;
            pIDxAddr_[_addr] = pID_;
            plyr_[pID_].addr = _addr;

             
            return (true);
        } else {
            return (false);
        }
    }
     
     
     
     
    function getPlayerID(address _addr)
    isRegisteredGame()
    external
    returns (uint256)
    {
        determinePID(_addr);
        return (pIDxAddr_[_addr]);
    }

    function getPlayerAddr(uint256 _pID)
    external
    view
    returns (address)
    {
        return (plyr_[_pID].addr);
    }

     
     
     
     
     
     
     

     
     
     
     
    function addGame(address _gameAddress)
    public
    {
        require(gameIDs_[_gameAddress] == 0, "derp, that games already been registered");
        gID_++;
        gameIDs_[_gameAddress] = gID_;
        games_[gID_] = PlayerBookReceiverInterface(_gameAddress);

         
        games_[gID_].receivePlayerInfo(1, plyr_[1].addr);
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