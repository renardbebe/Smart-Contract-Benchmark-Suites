 

pragma solidity ^0.4.24;

contract WorldByEth {
    using SafeMath for *;
    using NameFilter for string;
    

    string constant public name = "ETH world cq";
    string constant public symbol = "ecq";
    uint256 public rID_;
    uint256 public pID_;
    uint256 public com_;
    address public comaddr = 0x9ca974f2c49d68bd5958978e81151e6831290f57;
    mapping(uint256 => uint256) public pot_;
    mapping(uint256 => mapping(uint256 => Ctry)) public ctry_;
    uint public gap = 1 hours;
    uint public timeleft;
    address public lastplayer = 0x9ca974f2c49d68bd5958978e81151e6831290f57;
    address public lastwinner;
    uint[] public validplayers;

    struct Ctry {
        uint256 id;
        uint256 price;
        bytes32 name;
        bytes32 mem;
        address owner;
    }

    mapping(uint256 => uint256) public totalinvest_;

     
    modifier isHuman() {
        address _addr = msg.sender;
        require(_addr == tx.origin);
        
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    constructor()
    public
    {
        pID_++;
        rID_++;
        validplayers.length = 0;
        timeleft = now + 24 hours;
    }

    function getvalid()
    public
    returns(uint[]){
        return validplayers;
    }
    
    function changemem(uint id, bytes32 mem)
    isHuman
    public
    payable
    {
        require(msg.value >= 0.1 ether);
        require(msg.sender == ctry_[rID_][id].owner);
        com_ += msg.value;
        if (mem != ""){
            ctry_[rID_][id].mem = mem;
        }
    }

    function buy(uint id, bytes32 mem)
    isHuman
    public
    payable
    {
        require(msg.value >= 0.01 ether);
        require(msg.value >=ctry_[rID_][id].price);

        if (mem != ""){
            ctry_[rID_][id].mem = mem;
        }

        if (update() == true) {
            uint com = (msg.value).div(100);
            com_ += com;

            uint pot = (msg.value).mul(9).div(100);
            pot_[rID_] += pot;

            uint pre = msg.value - com - pot;
        
            if (ctry_[rID_][id].owner != address(0x0)){
                ctry_[rID_][id].owner.transfer(pre);
            }else{
                validplayers.push(id);
            }    
            ctry_[rID_][id].owner = msg.sender;
            ctry_[rID_][id].price = (msg.value).mul(14).div(10);
        }else{
            rID_++;
            validplayers.length = 0;
            ctry_[rID_][id].owner = msg.sender;
            ctry_[rID_][id].price = (0.01 ether).mul(14).div(10);
            validplayers.push(id);
            (msg.sender).transfer(msg.value - 0.01 ether);
        }

        lastplayer = msg.sender;
        totalinvest_[rID_] += msg.value;
        ctry_[rID_][id].id = id;
    }

    function update()
    private
    returns(bool)
    {
        if (now > timeleft) {
            lastplayer.transfer(pot_[rID_].mul(6).div(10));
            lastwinner = lastplayer;
            com_ += pot_[rID_].div(10);
            pot_[rID_+1] += pot_[rID_].mul(3).div(10);
            timeleft = now + 24 hours;
            return false;
        }

        timeleft += gap;
        if (timeleft > now + 24 hours) {
            timeleft = now + 24 hours;
        }
        return true;
    }

    function()
    public
    payable
    {
        com_ += msg.value;
    }

    modifier onlyDevs() {
        require(
            msg.sender == 0x9ca974f2c49d68bd5958978e81151e6831290f57,
            "only team just can activate"
        );
        _;
    }

     
    function withcom()
    onlyDevs
    public
    {
        if (com_ <= address(this).balance){
            comaddr.transfer(com_);
            com_ = 0;
        }else{
            comaddr.transfer(address(this).balance);
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