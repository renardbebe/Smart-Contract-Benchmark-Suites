 

 
pragma solidity 0.4.18;
 
 
 
 
 
 
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
        OwnershipTransferred(owner, newOwner);
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
        OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = 0x0;
    }
}
 
 
 
 
contract TokenRegistry is Claimable {
    address[] public addresses;
    mapping (address => TokenInfo) addressMap;
    mapping (string => address) symbolMap;
    
    uint8 public constant TOKEN_STANDARD_ERC20   = 0;
    uint8 public constant TOKEN_STANDARD_ERC223  = 1;
    
     
     
     
    struct TokenInfo {
        uint   pos;       
                          
        uint8  standard;  
        string symbol;    
    }
    
     
     
     
    event TokenRegistered(address addr, string symbol);
    event TokenUnregistered(address addr, string symbol);
    
     
     
     
     
    function () payable public {
        revert();
    }
    function registerToken(
        address addr,
        string  symbol
        )
        external
        onlyOwner
    {
        registerStandardToken(addr, symbol, TOKEN_STANDARD_ERC20);    
    }
    function registerStandardToken(
        address addr,
        string  symbol,
        uint8   standard
        )
        public
        onlyOwner
    {
        require(0x0 != addr);
        require(bytes(symbol).length > 0);
        require(0x0 == symbolMap[symbol]);
        require(0 == addressMap[addr].pos);
        require(standard <= TOKEN_STANDARD_ERC223);
        addresses.push(addr);
        symbolMap[symbol] = addr;
        addressMap[addr] = TokenInfo(addresses.length, standard, symbol);
        TokenRegistered(addr, symbol);      
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
        TokenUnregistered(addr, symbol);
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
    
    function getTokenStandard(address addr)
        public
        view
        returns (uint8)
    {
        TokenInfo memory info = addressMap[addr];
        require(info.pos != 0);
        return info.standard;
    }
    function getAddressBySymbol(string symbol)
        external
        view
        returns (address)
    {
        return symbolMap[symbol];
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
}