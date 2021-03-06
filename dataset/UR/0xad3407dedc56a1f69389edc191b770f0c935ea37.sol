 

 
pragma solidity 0.4.21;
 
 
library AddressUtil {
    function isContract(address addr)
        internal
        view
        returns (bool)
    {
        if (addr == 0x0) {
            return false;
        } else {
            uint size;
            assembly { size := extcodesize(addr) }
            return size > 0;
        }
    }
}
 
 
 
 
 
 
 
contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
     
     
    function Ownable() public {
        owner = msg.sender;
    }
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
     
     
     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != 0x0);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
 
 
 
contract Claimable is Ownable {
    address public pendingOwner;
     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }
     
     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != 0x0 && newOwner != owner);
        pendingOwner = newOwner;
    }
     
    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = 0x0;
    }
}
 
 
 
 
contract TokenRegistry is Claimable {
    using AddressUtil for address;
    address tokenMintAddr;
    address[] public addresses;
    mapping (address => TokenInfo) addressMap;
    mapping (string => address) symbolMap;
     
     
     
    struct TokenInfo {
        uint   pos;       
                          
        string symbol;    
    }
     
     
     
    event TokenRegistered(address addr, string symbol);
    event TokenUnregistered(address addr, string symbol);
     
     
     
     
    function () payable public {
        revert();
    }
    function TokenRegistry(address _tokenMintAddr) public
    {
        require(_tokenMintAddr.isContract());
        tokenMintAddr = _tokenMintAddr;
    }
    function registerToken(
        address addr,
        string  symbol
        )
        external
        onlyOwner
    {
        registerTokenInternal(addr, symbol);
    }
    function registerMintedToken(
        address addr,
        string  symbol
        )
        external
    {
        require(msg.sender == tokenMintAddr);
        registerTokenInternal(addr, symbol);
    }
    function unregisterToken(
        address addr,
        string  symbol
        )
        external
        onlyOwner
    {
        require(addr != 0x0);
        require(symbolMap[symbol] == addr);
        delete symbolMap[symbol];
        uint pos = addressMap[addr].pos;
        require(pos != 0);
        delete addressMap[addr];
         
         
        address lastToken = addresses[addresses.length - 1];
         
        if (addr != lastToken) {
             
            addresses[pos - 1] = lastToken;
            addressMap[lastToken].pos = pos;
        }
        addresses.length--;
        emit TokenUnregistered(addr, symbol);
    }
    function areAllTokensRegistered(address[] addressList)
        external
        view
        returns (bool)
    {
        for (uint i = 0; i < addressList.length; i++) {
            if (addressMap[addressList[i]].pos == 0) {
                return false;
            }
        }
        return true;
    }
    function getAddressBySymbol(string symbol)
        external
        view
        returns (address)
    {
        return symbolMap[symbol];
    }
    function isTokenRegisteredBySymbol(string symbol)
        public
        view
        returns (bool)
    {
        return symbolMap[symbol] != 0x0;
    }
    function isTokenRegistered(address addr)
        public
        view
        returns (bool)
    {
        return addressMap[addr].pos != 0;
    }
    function getTokens(
        uint start,
        uint count
        )
        public
        view
        returns (address[] addressList)
    {
        uint num = addresses.length;
        if (start >= num) {
            return;
        }
        uint end = start + count;
        if (end > num) {
            end = num;
        }
        if (start == num) {
            return;
        }
        addressList = new address[](end - start);
        for (uint i = start; i < end; i++) {
            addressList[i - start] = addresses[i];
        }
    }
    function registerTokenInternal(
        address addr,
        string  symbol
        )
        internal
    {
        require(0x0 != addr);
        require(bytes(symbol).length > 0);
        require(0x0 == symbolMap[symbol]);
        require(0 == addressMap[addr].pos);
        addresses.push(addr);
        symbolMap[symbol] = addr;
        addressMap[addr] = TokenInfo(addresses.length, symbol);
        emit TokenRegistered(addr, symbol);
    }
}