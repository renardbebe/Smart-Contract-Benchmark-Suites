 

pragma solidity 0.4.20;

contract nistTokenBase {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    
    event Transfer( address indexed from, address indexed to, uint256 value);

    function nistTokenBase() public {    }
    
    function totalSupply() public view returns (uint256) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }
    
    
    function transfer(address dst, uint256 wad) public returns (bool) {
        require(_balances[msg.sender] >= wad);
        
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);
        
        Transfer(msg.sender, dst, wad);
        
        return true;
    }
    
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x && z>=y);
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x - y;
        require(x >= y && z <= x);
        return z;
    }
}

contract nistToken is nistTokenBase {
    string  public  symbol = "nist";
    string  public name = "NIST";
    uint256  public  decimals = 18; 
    uint256 public freezedValue = 640000000*(10**18);
    uint256 public eachUnfreezeValue = 160000000*(10**18);
    uint256 public releaseTime = 1543800600; 
    uint256 public latestReleaseTime = 1543800600;  
    address public owner;

    struct FreezeStruct {
        uint256 unfreezeTime;
        bool freezed;
    }

    FreezeStruct[] public unfreezeTimeMap;
    
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function nistToken() public {
        _supply = 20*(10**8)*(10**18);
        _balances[0x01] = freezedValue;
        _balances[msg.sender] = sub(_supply,freezedValue);
        owner = msg.sender;

        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1543804200, freezed: true}));  
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1543805300, freezed: true}));  
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1543806400, freezed: true}));  
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1543807500, freezed: true}));  
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        require (now >= releaseTime || now >= latestReleaseTime);

        return super.transfer(dst, wad);
    }

    function distribute(address dst, uint256 wad) public returns (bool) {
        require(msg.sender == owner);

        return super.transfer(dst, wad);
    }

    function setRelease(uint256 _release) public {
        require(msg.sender == owner);
        require(_release <= latestReleaseTime);

        releaseTime = _release;
    }

    function unfreeze(uint256 i) public {
        require(msg.sender == owner);
        require(i>=0 && i<unfreezeTimeMap.length);
        require(now >= unfreezeTimeMap[i].unfreezeTime && unfreezeTimeMap[i].freezed);
        require(_balances[0x01] >= eachUnfreezeValue);

        _balances[0x01] = sub(_balances[0x01], eachUnfreezeValue);
        _balances[owner] = add(_balances[owner], eachUnfreezeValue);

        freezedValue = sub(freezedValue, eachUnfreezeValue);
        unfreezeTimeMap[i].freezed = false;

        Transfer(0x01, owner, eachUnfreezeValue);
    }
}