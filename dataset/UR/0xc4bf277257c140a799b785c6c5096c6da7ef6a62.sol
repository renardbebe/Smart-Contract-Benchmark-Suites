 

pragma solidity >=0.4.24 <0.5.0;

 
library AddressMap {
    address constant ZERO_ADDRESS = address(0);

    struct Data {
        int256 count;
        mapping(address => int256) indices;
        mapping(int256 => address) items;
    }

     
    function append(Data storage self, address addr)
    internal
    returns (bool) {
        if (addr == ZERO_ADDRESS) {
            return false;
        }

        int256 index = self.indices[addr] - 1;
        if (index >= 0 && index < self.count) {
            return false;
        }

        self.count++;
        self.indices[addr] = self.count;
        self.items[self.count] = addr;
        return true;
    }

     
    function remove(Data storage self, address addr)
    internal
    returns (bool) {
        int256 oneBasedIndex = self.indices[addr];
        if (oneBasedIndex < 1 || oneBasedIndex > self.count) {
            return false;   
        }

         
         
         
         
         
         
         
         
        if (oneBasedIndex < self.count) {
             
            address last = self.items[self.count];   
            self.indices[last] = oneBasedIndex;      
            self.items[oneBasedIndex] = last;        
            delete self.items[self.count];           
        } else {
             
            delete self.items[oneBasedIndex];
        }

        delete self.indices[addr];
        self.count--;
        return true;
    }

     
    function at(Data storage self, int256 index)
    internal
    view
    returns (address) {
        require(index >= 0 && index < self.count, "Index outside of bounds.");
        return self.items[index + 1];
    }

     
    function indexOf(Data storage self, address addr)
    internal
    view
    returns (int256) {
        if (addr == ZERO_ADDRESS) {
            return -1;
        }

        int256 index = self.indices[addr] - 1;
        if (index < 0 || index >= self.count) {
            return -1;
        }
        return index;
    }

     
    function exists(Data storage self, address addr)
    internal
    view
    returns (bool) {
        int256 index = self.indices[addr] - 1;
        return index >= 0 && index < self.count;
    }

     
    function clear(Data storage self)
    internal {
        self.count = 0;
    }

}

 
library AccountMap {
    address constant ZERO_ADDRESS = address(0);

    struct Account {
        address addr;
        uint8 kind;
        bool frozen;
        address parent;
    }

    struct Data {
        int256 count;
        mapping(address => int256) indices;
        mapping(int256 => Account) items;
    }

     
    function append(Data storage self, address addr, uint8 kind, bool isFrozen, address parent)
    internal
    returns (bool) {
        if (addr == ZERO_ADDRESS) {
            return false;
        }

        int256 index = self.indices[addr] - 1;
        if (index >= 0 && index < self.count) {
            return false;
        }

        self.count++;
        self.indices[addr] = self.count;
        self.items[self.count] = Account(addr, kind, isFrozen, parent);
        return true;
    }

     
    function remove(Data storage self, address addr)
    internal
    returns (bool) {
        int256 oneBasedIndex = self.indices[addr];
        if (oneBasedIndex < 1 || oneBasedIndex > self.count) {
            return false;   
        }

         
         
         
         
         
         
         
         
        if (oneBasedIndex < self.count) {
             
            Account storage last = self.items[self.count];   
            self.indices[last.addr] = oneBasedIndex;         
            self.items[oneBasedIndex] = last;                
            delete self.items[self.count];                   
        } else {
             
            delete self.items[oneBasedIndex];
        }

        delete self.indices[addr];
        self.count--;
        return true;
    }

     
    function at(Data storage self, int256 index)
    internal
    view
    returns (Account) {
        require(index >= 0 && index < self.count, "Index outside of bounds.");
        return self.items[index + 1];
    }

     
    function indexOf(Data storage self, address addr)
    internal
    view
    returns (int256) {
        if (addr == ZERO_ADDRESS) {
            return -1;
        }

        int256 index = self.indices[addr] - 1;
        if (index < 0 || index >= self.count) {
            return -1;
        }
        return index;
    }

     
    function get(Data storage self, address addr)
    internal
    view
    returns (Account) {
        return at(self, indexOf(self, addr));
    }

     
    function exists(Data storage self, address addr)
    internal
    view
    returns (bool) {
        int256 index = self.indices[addr] - 1;
        return index >= 0 && index < self.count;
    }

     
    function clear(Data storage self)
    internal {
        self.count = 0;
    }

}

 
contract Ownable {
    address public owner;

    event OwnerTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner account is required");
        _;
    }

     
    function transferOwner(address newOwner)
    public
    onlyOwner {
        require(newOwner != owner, "New Owner cannot be the current owner");
        require(newOwner != address(0), "New Owner cannot be zero address");
        address prevOwner = owner;
        owner = newOwner;
        emit OwnerTransferred(prevOwner, newOwner);
    }
}

 
contract Lockable is Ownable {
    bool public isLocked;

    constructor() public {
        isLocked = false;
    }

    modifier isUnlocked() {
        require(!isLocked, "Contract is currently locked for modification");
        _;
    }

     
    function setLocked(bool locked)
    onlyOwner
    external {
        require(isLocked != locked, "Contract already in requested lock state");

        isLocked = locked;
    }
}

 
contract Destroyable is Ownable {
     
    function kill()
    onlyOwner
    external {
        selfdestruct(owner);
    }
}

 
contract LockableDestroyable is Lockable, Destroyable { }

 
contract Storage is Ownable, LockableDestroyable {
    struct Mapping {
        address key;
        address value;
    }

    using AccountMap for AccountMap.Data;
    using AddressMap for AddressMap.Data;

     
     
    uint8 MAX_DATA = 30;

     
    AccountMap.Data public accounts;

     
     
     
    mapping(address => mapping(uint8 => bytes32)) public data;

     
     
    mapping(uint8 => AddressMap.Data) public permissions;


     
     
    modifier isAllowed(uint8 kind) {
        require(kind > 0, "Invalid, or missing permission");
        if (msg.sender != owner) {
            require(permissions[kind].exists(msg.sender), "Missing permission");
        }
        _;
    }


     
     
    function accountAt(int256 index)
    external
    view
    returns(address, uint8, bool, address) {
        AccountMap.Account memory acct = accounts.at(index);
        return (acct.addr, acct.kind, acct.frozen, acct.parent);
    }

     
    function accountGet(address addr)
    external
    view
    returns(uint8, bool, address) {
        AccountMap.Account memory acct = accounts.get(addr);
        return (acct.kind, acct.frozen, acct.parent);
    }

     
    function accountParent(address addr)
    external
    view
    returns(address) {
        return accounts.get(addr).parent;
    }

     
    function accountKind(address addr)
    external
    view
    returns(uint8) {
        return accounts.get(addr).kind;
    }

     
    function accountFrozen(address addr)
    external
    view
    returns(bool) {
        return accounts.get(addr).frozen;
    }

     
    function accountIndexOf(address addr)
    external
    view
    returns(int256) {
        return accounts.indexOf(addr);
    }

     
    function accountExists(address addr)
    external
    view
    returns(bool) {
        return accounts.exists(addr);
    }

     
    function accountExists(address addr, uint8 kind)
    external
    view
    returns(bool) {
        int256 index = accounts.indexOf(addr);
        if (index < 0) {
            return false;
        }
        return accounts.at(index).kind == kind;
    }


     
     
    function permissionAt(uint8 kind, int256 index)
    external
    view
    returns(address) {
        return permissions[kind].at(index);
    }

     
    function permissionIndexOf(uint8 kind, address addr)
    external
    view
    returns(int256) {
        return permissions[kind].indexOf(addr);
    }

     
    function permissionExists(uint8 kind, address addr)
    external
    view
    returns(bool) {
        return permissions[kind].exists(addr);
    }

     

     
    function addAccount(address addr, uint8 kind, bool isFrozen, address parent)
    isUnlocked
    isAllowed(kind)
    external {
        require(accounts.append(addr, kind, isFrozen, parent), "Account already exists");
    }

     
    function setAccountFrozen(address addr, bool frozen)
    isUnlocked
    isAllowed(accounts.get(addr).kind)
    external {
         
         
        int256 index = accounts.indexOf(addr) + 1;
        accounts.items[index].frozen = frozen;
    }

     
    function removeAccount(address addr)
    isUnlocked
    isAllowed(accounts.get(addr).kind)
    external {
        bytes32 ZERO_BYTES = bytes32(0);
        mapping(uint8 => bytes32) accountData = data[addr];

         
        for (uint8 i = 0; i < MAX_DATA; i++) {
            if (accountData[i] != ZERO_BYTES) {
                delete accountData[i];
            }
        }

         
        accounts.remove(addr);
    }

     
    function setAccountData(address addr, uint8 index, bytes32 customData)
    isUnlocked
    isAllowed(accounts.get(addr).kind)
    external {
        require(index < MAX_DATA, "index outside of bounds");
        data[addr][index] = customData;
    }

     
    function grantPermission(uint8 kind, address addr)
    isUnlocked
    isAllowed(kind)
    external {
        permissions[kind].append(addr);
    }

     
    function revokePermission(uint8 kind, address addr)
    isUnlocked
    isAllowed(kind)
    external {
        permissions[kind].remove(addr);
    }

}

interface ERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

library AdditiveMath {
     
    function add(uint256 x, uint256 y)
    internal
    pure
    returns (uint256) {
        uint256 sum = x + y;
        require(sum >= x, "Results in overflow");
        return sum;
    }

     
    function subtract(uint256 x, uint256 y)
    internal
    pure
    returns (uint256) {
        require(y <= x, "Results in underflow");
        return x - y;
    }
}

interface ComplianceRule {

     
    function canTransfer(address from, address to, uint8 toKind, Storage store)
    external
    view
    returns(bool);
}

interface Compliance {

     
    event AddressFrozen(
        address indexed addr,
        bool indexed isFrozen,
        address indexed owner
    );

     
    function setAddressFrozen(address addr, bool freeze)
    external;

     
    function getRules(uint8 kind)
    view
    external
    returns(ComplianceRule[]);

     
    function setRules(uint8 kind, ComplianceRule[] rules)
    external;

     
    function canTransfer(address from, address to)
    view
    external
    returns(bool);

}

contract T0ken is ERC20, Ownable, LockableDestroyable {
     
    using AdditiveMath for uint256;

    using AddressMap for AddressMap.Data;
    AddressMap.Data public shareholders;

    mapping(address => address) public cancellations;
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) private allowed;

    address public issuer;
    bool public issuingFinished = false;
    uint256 internal totalSupplyTokens;
    address constant internal ZERO_ADDRESS = address(0);
    Compliance public compliance;
    Storage public store;

     
    string public constant name = "TZERO PREFERRED";
    string public constant symbol = "TZROP";
    uint8 public constant decimals = 0;

     
    modifier transferCheck(uint256 value, address fromAddr) {
        require(value <= balances[fromAddr], "Balance is more than from address has");
        _;
    }

    modifier isNotCancelled(address addr) {
        require(cancellations[addr] == ZERO_ADDRESS, "Address has been cancelled");
        _;
    }

    modifier onlyIssuer() {
        require(msg.sender == issuer, "Only issuer allowed");
        _;
    }

    modifier canIssue() {
        require(!issuingFinished, "Issuing is already finished");
        _;
    }

    modifier canTransfer(address fromAddress, address toAddress) {
        if(fromAddress == issuer) {
            require(store.accountExists(toAddress), "The to address does not exist");
        }
        else {
            require(compliance.canTransfer(fromAddress, toAddress), "Address cannot transfer");
        }
        _;
    }

    modifier canTransferFrom(address fromAddress, address toAddress) {
        if(msg.sender == owner) {
            require(store.accountExists(toAddress), "The to address does not exist");
        }
        else {
            require(compliance.canTransfer(fromAddress, toAddress), "Address cannot transfer");
        }
        _;
    }

     

     
    event VerifiedAddressSuperseded(address indexed original, address indexed replacement, address indexed sender);
    event IssuerSet(address indexed previousIssuer, address indexed newIssuer);
    event Issue(address indexed to, uint256 amount);
    event IssueFinished();


     

     
    function totalSupply()
    external
    view
    returns (uint256) {
        return totalSupplyTokens;
    }

     
    function balanceOf(address addr)
    external
    view
    returns (uint256) {
        return balances[addr];
    }

     
    function allowance(address addrOwner, address spender)
    isUnlocked
    external
    view
    returns (uint256) {
        return allowed[addrOwner][spender];
    }

     
    function holderAt(int256 index)
    external
    view
    returns (address){
        return shareholders.at(index);
    }

     
    function isHolder(address addr)
    external
    view
    returns (bool) {
        return shareholders.exists(addr);
    }

     
    function isSuperseded(address addr)
    onlyOwner
    external
    view
    returns (bool) {
        return cancellations[addr] != ZERO_ADDRESS;
    }

     
    function getSuperseded(address addr)
    onlyOwner
    public
    view
    returns (address) {
        require(addr != ZERO_ADDRESS, "Non-zero address required");
        address candidate = cancellations[addr];
        if (candidate == ZERO_ADDRESS) {
            return ZERO_ADDRESS;
        }
        return candidate;
    }

     

    function setCompliance(address newComplianceAddress)
    isUnlocked
    onlyOwner
    external {
        compliance = Compliance(newComplianceAddress);
    }

    function setStorage(Storage s)
    isUnlocked
    onlyOwner
    external {
        store = s;
    }

     
    function transfer(address to, uint256 value)
    isUnlocked
    isNotCancelled(to)
    transferCheck(value, msg.sender)
    canTransfer(msg.sender, to)
    public
    returns (bool) {
        balances[msg.sender] = balances[msg.sender].subtract(value);
        balances[to] = balances[to].add(value);

         
        shareholders.append(to);

         
        if (balances[msg.sender] == 0) {
            shareholders.remove(msg.sender);
        }

        emit Transfer(msg.sender, to, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value)
    public
    transferCheck(value, from)
    isNotCancelled(to)
    canTransferFrom(from, to)
    isUnlocked
    returns (bool) {
        if(msg.sender != owner) {
            require(value <= allowed[from][msg.sender], "Value exceeds what is allowed to transfer");
            allowed[from][msg.sender] = allowed[from][msg.sender].subtract(value);
        }

        balances[from] = balances[from].subtract(value);
        balances[to] = balances[to].add(value);

         
        shareholders.append(to);

         
        if (balances[msg.sender] == 0) {
            shareholders.remove(from);
        }

        emit Transfer(from, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value)
    isUnlocked
    external
    returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function setIssuer(address newIssuer)
    isUnlocked
    onlyOwner
    external {
        issuer = newIssuer;
        emit IssuerSet(issuer, newIssuer);
    }

     
    function issueTokens(uint256 quantity)
    isUnlocked
    onlyIssuer
    canIssue
    public
    returns (bool) {
        address issuer = msg.sender;
        totalSupplyTokens = totalSupplyTokens.add(quantity);
        balances[issuer] = balances[issuer].add(quantity);
        shareholders.append(issuer);
        emit Issue(issuer, quantity);
        return true;
    }

    function finishIssuing()
    isUnlocked
    onlyIssuer
    canIssue
    public
    returns (bool) {
        issuingFinished = true;
        emit IssueFinished();
        return issuingFinished;
    }

     
    function cancelAndReissue(address original, address replacement)
    isUnlocked
    onlyOwner
    isNotCancelled(replacement)
    external {
         
         
        require(shareholders.exists(original) && !shareholders.exists(replacement), "Original doesn't exist or replacement does");
        shareholders.remove(original);
        shareholders.append(replacement);
        cancellations[original] = replacement;
        balances[replacement] = balances[original];
        balances[original] = 0;
        emit VerifiedAddressSuperseded(original, replacement, msg.sender);
    }

}