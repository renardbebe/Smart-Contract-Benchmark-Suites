 

 

pragma solidity ^0.5.12;


contract Claimable {
    address private _pendingOwner;
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Claimable: caller is not the owner");
        _;
    }

    
    modifier onlyPendingOwner() {
      require(msg.sender == _pendingOwner, "Claimable: caller is not the pending owner");
      _;
    }

    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
      _pendingOwner = newOwner;
    }

    
    function claimOwnership() public onlyPendingOwner {
      emit OwnershipTransferred(_owner, _pendingOwner);
      _owner = _pendingOwner;
      _pendingOwner = address(0);
    }
}

library ECDSA {
    
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        
        if (signature.length != 65) {
            revert("signature's length is invalid");
        }

        
        bytes32 r;
        bytes32 s;
        uint8 v;

        
        
        
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        
        
        
        
        
        
        
        
        
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("signature's s is in the wrong range");
        }

        if (v != 27 && v != 28) {
            revert("signature's v is in the wrong range");
        }

        
        return ecrecover(hash, v, r, s);
    }

    
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        
        
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

library String {

    
    
    function fromUint(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    
    function fromBytes32(bytes32 _value) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_value));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(32 * 2 + 2);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 32; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i] & 0x0f))];
        }
        return string(str);
    }

    
    function fromAddress(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(20 * 2 + 2);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    
    function add4(string memory a, string memory b, string memory c, string memory d) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d));
    }
}

library Compare {

    function bytesEqual(bytes memory a, bytes memory b) internal pure returns (bool) {
        if (a.length != b.length) {
            return false;
        }
        for (uint i = 0; i < a.length; i ++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }
}

library Validate {

    
    
    
    
    function duplicatePropose(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash1,
        uint256 _validRound1,
        bytes memory _signature1,
        bytes memory _blockhash2,
        uint256 _validRound2,
        bytes memory _signature2
    ) internal pure returns (address) {
        require(!Compare.bytesEqual(_signature1, _signature2), "Validate: same signature");
        address signer1 = recoverPropose(_height, _round, _blockhash1, _validRound1, _signature1);
        address signer2 = recoverPropose(_height, _round, _blockhash2, _validRound2, _signature2);
        require(signer1 == signer2, "Validate: different signer");
        return signer1;
    }

    function recoverPropose(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash,
        uint256 _validRound,
        bytes memory _signature
    ) internal pure returns (address) {
        return ECDSA.recover(sha256(proposeMessage(_height, _round, _blockhash, _validRound)), _signature);
    }

    function proposeMessage(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash,
        uint256 _validRound
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "Propose(Height=", String.fromUint(_height),
            ",Round=", String.fromUint(_round),
            ",BlockHash=", string(_blockhash),
            ",ValidRound=", String.fromUint(_validRound),
            ")"
        );
    }

    
    
    
    
    function duplicatePrevote(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash1,
        bytes memory _signature1,
        bytes memory _blockhash2,
        bytes memory _signature2
    ) internal pure returns (address) {
        require(!Compare.bytesEqual(_signature1, _signature2), "Validate: same signature");
        address signer1 = recoverPrevote(_height, _round, _blockhash1, _signature1);
        address signer2 = recoverPrevote(_height, _round, _blockhash2, _signature2);
        require(signer1 == signer2, "Validate: different signer");
        return signer1;
    }

    function recoverPrevote(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash,
        bytes memory _signature
    ) internal pure returns (address) {
        return ECDSA.recover(sha256(prevoteMessage(_height, _round, _blockhash)), _signature);
    }

    function prevoteMessage(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "Prevote(Height=", String.fromUint(_height),
            ",Round=", String.fromUint(_round),
            ",BlockHash=", string(_blockhash),
            ")"
        );
    }

    
    
    
    
    function duplicatePrecommit(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash1,
        bytes memory _signature1,
        bytes memory _blockhash2,
        bytes memory _signature2
    ) internal pure returns (address) {
        require(!Compare.bytesEqual(_signature1, _signature2), "Validate: same signature");
        address signer1 = recoverPrecommit(_height, _round, _blockhash1, _signature1);
        address signer2 = recoverPrecommit(_height, _round, _blockhash2, _signature2);
        require(signer1 == signer2, "Validate: different signer");
        return signer1;
    }

    function recoverPrecommit(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash,
        bytes memory _signature
    ) internal pure returns (address) {
        return ECDSA.recover(sha256(precommitMessage(_height, _round, _blockhash)), _signature);
    }

    function precommitMessage(
        uint256 _height,
        uint256 _round,
        bytes memory _blockhash
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "Precommit(Height=", String.fromUint(_height),
            ",Round=", String.fromUint(_round),
            ",BlockHash=", string(_blockhash),
            ")"
        );
    }

    function recoverSecret(
        uint256 _a,
        uint256 _b,
        uint256 _c,
        uint256 _d,
        uint256 _e,
        uint256 _f,
        bytes memory _signature
    ) internal pure returns (address) {
        return ECDSA.recover(sha256(secretMessage(_a, _b, _c, _d, _e, _f)), _signature);
    }

    function secretMessage(
        uint256 _a,
        uint256 _b,
        uint256 _c,
        uint256 _d,
        uint256 _e,
        uint256 _f
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "Secret(",
            "ShamirShare(",
            String.fromUint(_a),
            ",", String.fromUint(_b),
            ",S256N(", String.fromUint(_c),
            "),",
            "S256PrivKey(",
            "S256N(", String.fromUint(_d),
            "),",
            "S256P(", String.fromUint(_e),
            "),",
            "S256P(", String.fromUint(_f),
            ")",
            ")",
            ")",
            ")"
        );
    }
}

contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    
    function name() public view returns (string memory) {
        return _name;
    }

    
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

contract Pausable is Context, PauserRole {
    
    event Paused(address account);

    
    event Unpaused(address account);

    bool private _paused;

    
    constructor () internal {
        _paused = false;
    }

    
    function paused() public view returns (bool) {
        return _paused;
    }

    
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

contract ERC20Burnable is Context, ERC20 {
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

contract RenToken is Ownable, ERC20Detailed, ERC20Pausable, ERC20Burnable {

    string private constant _name = "Republic Token";
    string private constant _symbol = "REN";
    uint8 private constant _decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 1000000000 * 10**uint256(_decimals);

    
    constructor() ERC20Burnable() ERC20Pausable() ERC20Detailed(_name, _symbol, _decimals) public {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function transferTokens(address beneficiary, uint256 amount) public onlyOwner returns (bool) {
        
        
        require(amount > 0);

        _transfer(msg.sender, beneficiary, amount);
        emit Transfer(msg.sender, beneficiary, amount);

        return true;
    }
}

library LinkedList {

    
    address public constant NULL = address(0);

    
    struct Node {
        bool inList;
        address previous;
        address next;
    }

    
    struct List {
        mapping (address => Node) list;
    }

    
    function insertBefore(List storage self, address target, address newNode) internal {
        require(!isInList(self, newNode), "LinkedList: already in list");
        require(isInList(self, target) || target == NULL, "LinkedList: not in list");

        
        address prev = self.list[target].previous;

        self.list[newNode].next = target;
        self.list[newNode].previous = prev;
        self.list[target].previous = newNode;
        self.list[prev].next = newNode;

        self.list[newNode].inList = true;
    }

    
    function insertAfter(List storage self, address target, address newNode) internal {
        require(!isInList(self, newNode), "LinkedList: already in list");
        require(isInList(self, target) || target == NULL, "LinkedList: not in list");

        
        address n = self.list[target].next;

        self.list[newNode].previous = target;
        self.list[newNode].next = n;
        self.list[target].next = newNode;
        self.list[n].previous = newNode;

        self.list[newNode].inList = true;
    }

    
    function remove(List storage self, address node) internal {
        require(isInList(self, node), "LinkedList: not in list");
        if (node == NULL) {
            return;
        }
        address p = self.list[node].previous;
        address n = self.list[node].next;

        self.list[p].next = n;
        self.list[n].previous = p;

        
        
        self.list[node].inList = false;
        delete self.list[node];
    }

    
    function prepend(List storage self, address node) internal {
        

        insertBefore(self, begin(self), node);
    }

    
    function append(List storage self, address node) internal {
        

        insertAfter(self, end(self), node);
    }

    function swap(List storage self, address left, address right) internal {
        

        address previousRight = self.list[right].previous;
        remove(self, right);
        insertAfter(self, left, right);
        remove(self, left);
        insertAfter(self, previousRight, left);
    }

    function isInList(List storage self, address node) internal view returns (bool) {
        return self.list[node].inList;
    }

    
    function begin(List storage self) internal view returns (address) {
        return self.list[NULL].next;
    }

    
    function end(List storage self) internal view returns (address) {
        return self.list[NULL].previous;
    }

    function next(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "LinkedList: not in list");
        return self.list[node].next;
    }

    function previous(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "LinkedList: not in list");
        return self.list[node].previous;
    }

}

contract DarknodeRegistryStore is Claimable {
    using SafeMath for uint256;

    string public VERSION; 

    
    
    
    
    
    struct Darknode {
        
        
        
        
        address payable owner;

        
        
        
        uint256 bond;

        
        uint256 registeredAt;

        
        uint256 deregisteredAt;

        
        
        
        
        bytes publicKey;
    }

    
    mapping(address => Darknode) private darknodeRegistry;
    LinkedList.List private darknodes;

    
    RenToken public ren;

    
    
    
    
    constructor(
        string memory _VERSION,
        RenToken _ren
    ) public {
        VERSION = _VERSION;
        ren = _ren;
    }

    
    
    
    
    function recoverTokens(address _token) external onlyOwner {
        require(_token != address(ren), "DarknodeRegistryStore: not allowed to recover REN");

        if (_token == address(0x0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(address(this)));
        }
    }

    
    
    
    
    
    
    
    
    
    function appendDarknode(
        address _darknodeID,
        address payable _darknodeOwner,
        uint256 _bond,
        bytes calldata _publicKey,
        uint256 _registeredAt,
        uint256 _deregisteredAt
    ) external onlyOwner {
        Darknode memory darknode = Darknode({
            owner: _darknodeOwner,
            bond: _bond,
            publicKey: _publicKey,
            registeredAt: _registeredAt,
            deregisteredAt: _deregisteredAt
        });
        darknodeRegistry[_darknodeID] = darknode;
        LinkedList.append(darknodes, _darknodeID);
    }

    
    function begin() external view onlyOwner returns(address) {
        return LinkedList.begin(darknodes);
    }

    
    
    function next(address darknodeID) external view onlyOwner returns(address) {
        return LinkedList.next(darknodes, darknodeID);
    }

    
    
    function removeDarknode(address darknodeID) external onlyOwner {
        uint256 bond = darknodeRegistry[darknodeID].bond;
        delete darknodeRegistry[darknodeID];
        LinkedList.remove(darknodes, darknodeID);
        require(ren.transfer(owner(), bond), "DarknodeRegistryStore: bond transfer failed");
    }

    
    
    function updateDarknodeBond(address darknodeID, uint256 decreasedBond) external onlyOwner {
        uint256 previousBond = darknodeRegistry[darknodeID].bond;
        require(decreasedBond < previousBond, "DarknodeRegistryStore: bond not decreased");
        darknodeRegistry[darknodeID].bond = decreasedBond;
        require(ren.transfer(owner(), previousBond.sub(decreasedBond)), "DarknodeRegistryStore: bond transfer failed");
    }

    
    function updateDarknodeDeregisteredAt(address darknodeID, uint256 deregisteredAt) external onlyOwner {
        darknodeRegistry[darknodeID].deregisteredAt = deregisteredAt;
    }

    
    function darknodeOwner(address darknodeID) external view onlyOwner returns (address payable) {
        return darknodeRegistry[darknodeID].owner;
    }

    
    function darknodeBond(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].bond;
    }

    
    function darknodeRegisteredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].registeredAt;
    }

    
    function darknodeDeregisteredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].deregisteredAt;
    }

    
    function darknodePublicKey(address darknodeID) external view onlyOwner returns (bytes memory) {
        return darknodeRegistry[darknodeID].publicKey;
    }
}

interface IDarknodePaymentStore {
}

interface IDarknodePayment {
    function changeCycle() external returns (uint256);
    function store() external returns (IDarknodePaymentStore);
}

interface IDarknodeSlasher {
}

contract DarknodeRegistry is Claimable {
    using SafeMath for uint256;

    string public VERSION; 

    
    
    
    struct Epoch {
        uint256 epochhash;
        uint256 blocktime;
    }

    uint256 public numDarknodes;
    uint256 public numDarknodesNextEpoch;
    uint256 public numDarknodesPreviousEpoch;

    
    uint256 public minimumBond;
    uint256 public minimumPodSize;
    uint256 public minimumEpochInterval;

    
    
    uint256 public nextMinimumBond;
    uint256 public nextMinimumPodSize;
    uint256 public nextMinimumEpochInterval;

    
    Epoch public currentEpoch;
    Epoch public previousEpoch;

    
    RenToken public ren;

    
    DarknodeRegistryStore public store;

    
    IDarknodePayment public darknodePayment;

    
    IDarknodeSlasher public slasher;
    IDarknodeSlasher public nextSlasher;

    
    
    
    
    event LogDarknodeRegistered(address indexed _operator, address indexed _darknodeID, uint256 _bond);

    
    
    
    event LogDarknodeDeregistered(address indexed _operator, address indexed _darknodeID);

    
    
    
    event LogDarknodeOwnerRefunded(address indexed _operator, uint256 _amount);

    
    
    
    
    
    event LogDarknodeSlashed(address indexed _operator, address indexed _darknodeID, address indexed _challenger, uint256 _percentage);

    
    event LogNewEpoch(uint256 indexed epochhash);

    
    event LogMinimumBondUpdated(uint256 _previousMinimumBond, uint256 _nextMinimumBond);
    event LogMinimumPodSizeUpdated(uint256 _previousMinimumPodSize, uint256 _nextMinimumPodSize);
    event LogMinimumEpochIntervalUpdated(uint256 _previousMinimumEpochInterval, uint256 _nextMinimumEpochInterval);
    event LogSlasherUpdated(address _previousSlasher, address _nextSlasher);
    event LogDarknodePaymentUpdated(IDarknodePayment _previousDarknodePayment, IDarknodePayment _nextDarknodePayment);

    
    modifier onlyDarknodeOwner(address _darknodeID) {
        require(store.darknodeOwner(_darknodeID) == msg.sender, "DarknodeRegistry: must be darknode owner");
        _;
    }

    
    modifier onlyRefunded(address _darknodeID) {
        require(isRefunded(_darknodeID), "DarknodeRegistry: must be refunded or never registered");
        _;
    }

    
    modifier onlyRefundable(address _darknodeID) {
        require(isRefundable(_darknodeID), "DarknodeRegistry: must be deregistered for at least one epoch");
        _;
    }

    
    
    modifier onlyDeregisterable(address _darknodeID) {
        require(isDeregisterable(_darknodeID), "DarknodeRegistry: must be deregisterable");
        _;
    }

    
    modifier onlySlasher() {
        require(address(slasher) == msg.sender, "DarknodeRegistry: must be slasher");
        _;
    }

    
    
    
    
    
    
    
    
    
    constructor(
        string memory _VERSION,
        RenToken _renAddress,
        DarknodeRegistryStore _storeAddress,
        uint256 _minimumBond,
        uint256 _minimumPodSize,
        uint256 _minimumEpochIntervalSeconds
    ) public {
        VERSION = _VERSION;

        store = _storeAddress;
        ren = _renAddress;

        minimumBond = _minimumBond;
        nextMinimumBond = minimumBond;

        minimumPodSize = _minimumPodSize;
        nextMinimumPodSize = minimumPodSize;

        minimumEpochInterval = _minimumEpochIntervalSeconds;
        nextMinimumEpochInterval = minimumEpochInterval;

        currentEpoch = Epoch({
            epochhash: uint256(blockhash(block.number - 1)),
            blocktime: block.timestamp
        });
        numDarknodes = 0;
        numDarknodesNextEpoch = 0;
        numDarknodesPreviousEpoch = 0;
    }

    
    
    function recoverTokens(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(address(this)));
        }
    }

    
    
    
    
    
    
    
    
    
    
    function register(address _darknodeID, bytes calldata _publicKey) external onlyRefunded(_darknodeID) {
        
        uint256 bond = minimumBond;

        
        require(ren.transferFrom(msg.sender, address(store), bond), "DarknodeRegistry: bond transfer failed");

        
        store.appendDarknode(
            _darknodeID,
            msg.sender,
            bond,
            _publicKey,
            currentEpoch.blocktime.add(minimumEpochInterval),
            0
        );

        numDarknodesNextEpoch = numDarknodesNextEpoch.add(1);

        
        emit LogDarknodeRegistered(msg.sender, _darknodeID, bond);
    }

    
    
    
    
    
    
    function deregister(address _darknodeID) external onlyDeregisterable(_darknodeID) onlyDarknodeOwner(_darknodeID) {
        deregisterDarknode(_darknodeID);
    }

    
    
    
    function epoch() external {
        if (previousEpoch.blocktime == 0) {
            
            require(msg.sender == owner(), "DarknodeRegistry: not authorized (first epochs)");
        }

        
        require(block.timestamp >= currentEpoch.blocktime.add(minimumEpochInterval), "DarknodeRegistry: epoch interval has not passed");
        uint256 epochhash = uint256(blockhash(block.number - 1));

        
        previousEpoch = currentEpoch;
        currentEpoch = Epoch({
            epochhash: epochhash,
            blocktime: block.timestamp
        });

        
        numDarknodesPreviousEpoch = numDarknodes;
        numDarknodes = numDarknodesNextEpoch;

        
        if (nextMinimumBond != minimumBond) {
            minimumBond = nextMinimumBond;
            emit LogMinimumBondUpdated(minimumBond, nextMinimumBond);
        }
        if (nextMinimumPodSize != minimumPodSize) {
            minimumPodSize = nextMinimumPodSize;
            emit LogMinimumPodSizeUpdated(minimumPodSize, nextMinimumPodSize);
        }
        if (nextMinimumEpochInterval != minimumEpochInterval) {
            minimumEpochInterval = nextMinimumEpochInterval;
            emit LogMinimumEpochIntervalUpdated(minimumEpochInterval, nextMinimumEpochInterval);
        }
        if (nextSlasher != slasher) {
            slasher = nextSlasher;
            emit LogSlasherUpdated(address(slasher), address(nextSlasher));
        }
        if (address(darknodePayment) != address(0x0)) {
            darknodePayment.changeCycle();
        }

        
        emit LogNewEpoch(epochhash);
    }

    
    
    
    function transferStoreOwnership(DarknodeRegistry _newOwner) external onlyOwner {
        store.transferOwnership(address(_newOwner));
        _newOwner.claimStoreOwnership();
    }

    
    
    
    function claimStoreOwnership() external {
        store.claimOwnership();
    }

    
    
    
    
    function updateDarknodePayment(IDarknodePayment _darknodePayment) external onlyOwner {
        require(address(_darknodePayment) != address(0x0), "DarknodeRegistry: invalid Darknode Payment address");
        IDarknodePayment previousDarknodePayment = darknodePayment;
        darknodePayment = _darknodePayment;
        emit LogDarknodePaymentUpdated(previousDarknodePayment, darknodePayment);
    }

    
    
    
    function updateMinimumBond(uint256 _nextMinimumBond) external onlyOwner {
        
        nextMinimumBond = _nextMinimumBond;
    }

    
    
    function updateMinimumPodSize(uint256 _nextMinimumPodSize) external onlyOwner {
        
        nextMinimumPodSize = _nextMinimumPodSize;
    }

    
    
    function updateMinimumEpochInterval(uint256 _nextMinimumEpochInterval) external onlyOwner {
        
        nextMinimumEpochInterval = _nextMinimumEpochInterval;
    }

    
    
    
    function updateSlasher(IDarknodeSlasher _slasher) external onlyOwner {
        require(address(_slasher) != address(0), "DarknodeRegistry: invalid slasher address");
        nextSlasher = _slasher;
    }

    
    
    
    
    
    function slash(address _guilty, address _challenger, uint256 _percentage)
        external
        onlySlasher
    {
        require(_percentage <= 100, "DarknodeRegistry: invalid percent");

        
        if (isDeregisterable(_guilty)) {
            deregisterDarknode(_guilty);
        }

        uint256 totalBond = store.darknodeBond(_guilty);
        uint256 penalty = totalBond.div(100).mul(_percentage);
        uint256 reward = penalty.div(2);
        if (reward > 0) {
            
            store.updateDarknodeBond(_guilty, totalBond.sub(penalty));

            
            require(address(darknodePayment) != address(0x0), "DarknodeRegistry: invalid payment address");
            require(ren.transfer(address(darknodePayment.store()), reward), "DarknodeRegistry: reward transfer failed");
            require(ren.transfer(_challenger, reward), "DarknodeRegistry: reward transfer failed");
        }

        emit LogDarknodeSlashed(store.darknodeOwner(_guilty), _guilty, _challenger, _percentage);
    }

    
    
    
    
    
    
    function refund(address _darknodeID) external onlyRefundable(_darknodeID) {
        address darknodeOwner = store.darknodeOwner(_darknodeID);

        
        uint256 amount = store.darknodeBond(_darknodeID);

        
        store.removeDarknode(_darknodeID);

        
        require(ren.transfer(darknodeOwner, amount), "DarknodeRegistry: bond transfer failed");

        
        emit LogDarknodeOwnerRefunded(darknodeOwner, amount);
    }

    
    
    function getDarknodeOwner(address _darknodeID) external view returns (address payable) {
        return store.darknodeOwner(_darknodeID);
    }

    
    
    function getDarknodeBond(address _darknodeID) external view returns (uint256) {
        return store.darknodeBond(_darknodeID);
    }

    
    
    function getDarknodePublicKey(address _darknodeID) external view returns (bytes memory) {
        return store.darknodePublicKey(_darknodeID);
    }

    
    
    
    
    
    
    
    
    
    
    function getDarknodes(address _start, uint256 _count) external view returns (address[] memory) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodes;
        }
        return getDarknodesFromEpochs(_start, count, false);
    }

    
    
    function getPreviousDarknodes(address _start, uint256 _count) external view returns (address[] memory) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodesPreviousEpoch;
        }
        return getDarknodesFromEpochs(_start, count, true);
    }

    
    
    
    function isPendingRegistration(address _darknodeID) external view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        return registeredAt != 0 && registeredAt > currentEpoch.blocktime;
    }

    
    
    function isPendingDeregistration(address _darknodeID) external view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return deregisteredAt != 0 && deregisteredAt > currentEpoch.blocktime;
    }

    
    function isDeregistered(address _darknodeID) public view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return deregisteredAt != 0 && deregisteredAt <= currentEpoch.blocktime;
    }

    
    
    
    function isDeregisterable(address _darknodeID) public view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        
        
        return isRegistered(_darknodeID) && deregisteredAt == 0;
    }

    
    
    
    function isRefunded(address _darknodeID) public view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return registeredAt == 0 && deregisteredAt == 0;
    }

    
    
    function isRefundable(address _darknodeID) public view returns (bool) {
        return isDeregistered(_darknodeID) && store.darknodeDeregisteredAt(_darknodeID) <= previousEpoch.blocktime;
    }

    
    function isRegistered(address _darknodeID) public view returns (bool) {
        return isRegisteredInEpoch(_darknodeID, currentEpoch);
    }

    
    function isRegisteredInPreviousEpoch(address _darknodeID) public view returns (bool) {
        return isRegisteredInEpoch(_darknodeID, previousEpoch);
    }

    
    
    
    
    function isRegisteredInEpoch(address _darknodeID, Epoch memory _epoch) private view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        bool registered = registeredAt != 0 && registeredAt <= _epoch.blocktime;
        bool notDeregistered = deregisteredAt == 0 || deregisteredAt > _epoch.blocktime;
        
        
        return registered && notDeregistered;
    }

    
    
    
    
    
    function getDarknodesFromEpochs(address _start, uint256 _count, bool _usePreviousEpoch) private view returns (address[] memory) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodes;
        }

        address[] memory nodes = new address[](count);

        
        uint256 n = 0;
        address next = _start;
        if (next == address(0)) {
            next = store.begin();
        }

        
        while (n < count) {
            if (next == address(0)) {
                break;
            }
            
            bool includeNext;
            if (_usePreviousEpoch) {
                includeNext = isRegisteredInPreviousEpoch(next);
            } else {
                includeNext = isRegistered(next);
            }
            if (!includeNext) {
                next = store.next(next);
                continue;
            }
            nodes[n] = next;
            next = store.next(next);
            n += 1;
        }
        return nodes;
    }

    
    function deregisterDarknode(address _darknodeID) private {
        
        store.updateDarknodeDeregisteredAt(_darknodeID, currentEpoch.blocktime.add(minimumEpochInterval));
        numDarknodesNextEpoch = numDarknodesNextEpoch.sub(1);

        
        emit LogDarknodeDeregistered(msg.sender, _darknodeID);
    }
}

contract DarknodeSlasher is Claimable {

    DarknodeRegistry public darknodeRegistry;

    uint256 public blacklistSlashPercent;
    uint256 public maliciousSlashPercent;
    uint256 public secretRevealSlashPercent;

    
    
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public slashed;

    
    mapping(address => bool) public secretRevealed;

    
    mapping(address => bool) public blacklisted;

    
    
    
    event LogDarknodeRegistryUpdated(DarknodeRegistry _previousDarknodeRegistry, DarknodeRegistry _nextDarknodeRegistry);

    
    modifier validPercent(uint256 _percent) {
        require(_percent <= 100, "DarknodeSlasher: invalid percentage");
        _;
    }

    constructor(
        DarknodeRegistry _darknodeRegistry
    ) public {
        darknodeRegistry = _darknodeRegistry;
    }

    
    
    
    
    function updateDarknodeRegistry(DarknodeRegistry _darknodeRegistry) external onlyOwner {
        require(address(_darknodeRegistry) != address(0x0), "DarknodeSlasher: invalid Darknode Registry address");
        DarknodeRegistry previousDarknodeRegistry = darknodeRegistry;
        darknodeRegistry = _darknodeRegistry;
        emit LogDarknodeRegistryUpdated(previousDarknodeRegistry, darknodeRegistry);
    }

    function setBlacklistSlashPercent(uint256 _percentage) public validPercent(_percentage) onlyOwner {
        blacklistSlashPercent = _percentage;
    }

    function setMaliciousSlashPercent(uint256 _percentage) public validPercent(_percentage) onlyOwner {
        maliciousSlashPercent = _percentage;
    }

    function setSecretRevealSlashPercent(uint256 _percentage) public validPercent(_percentage) onlyOwner {
        secretRevealSlashPercent = _percentage;
    }

    function slash(address _guilty, address _challenger, uint256 _percentage)
        external
        onlyOwner
    {
        darknodeRegistry.slash(_guilty, _challenger, _percentage);
    }

    function blacklist(address _guilty) external onlyOwner {
        require(!blacklisted[_guilty], "DarknodeSlasher: already blacklisted");
        blacklisted[_guilty] = true;
        darknodeRegistry.slash(_guilty, owner(), blacklistSlashPercent);
    }

    function slashDuplicatePropose(
        uint256 _height,
        uint256 _round,
        bytes calldata _blockhash1,
        uint256 _validRound1,
        bytes calldata _signature1,
        bytes calldata _blockhash2,
        uint256 _validRound2,
        bytes calldata _signature2
    ) external {
        address signer = Validate.duplicatePropose(
            _height,
            _round,
            _blockhash1,
            _validRound1,
            _signature1,
            _blockhash2,
            _validRound2,
            _signature2
        );
        require(!slashed[_height][_round][signer], "DarknodeSlasher: already slashed");
        slashed[_height][_round][signer] = true;
        darknodeRegistry.slash(signer, msg.sender, maliciousSlashPercent);
    }

    function slashDuplicatePrevote(
        uint256 _height,
        uint256 _round,
        bytes calldata _blockhash1,
        bytes calldata _signature1,
        bytes calldata _blockhash2,
        bytes calldata _signature2
    ) external {
        address signer = Validate.duplicatePrevote(
            _height,
            _round,
            _blockhash1,
            _signature1,
            _blockhash2,
            _signature2
        );
        require(!slashed[_height][_round][signer], "DarknodeSlasher: already slashed");
        slashed[_height][_round][signer] = true;
        darknodeRegistry.slash(signer, msg.sender, maliciousSlashPercent);
    }

    function slashDuplicatePrecommit(
        uint256 _height,
        uint256 _round,
        bytes calldata _blockhash1,
        bytes calldata _signature1,
        bytes calldata _blockhash2,
        bytes calldata _signature2
    ) external {
        address signer = Validate.duplicatePrecommit(
            _height,
            _round,
            _blockhash1,
            _signature1,
            _blockhash2,
            _signature2
        );
        require(!slashed[_height][_round][signer], "DarknodeSlasher: already slashed");
        slashed[_height][_round][signer] = true;
        darknodeRegistry.slash(signer, msg.sender, maliciousSlashPercent);
    }

    function slashSecretReveal(
        uint256 _a,
        uint256 _b,
        uint256 _c,
        uint256 _d,
        uint256 _e,
        uint256 _f,
        bytes calldata _signature
    ) external {
        address signer = Validate.recoverSecret(
            _a,
            _b,
            _c,
            _d,
            _e,
            _f,
            _signature
        );
        require(!secretRevealed[signer], "DarknodeSlasher: already slashed");
        secretRevealed[signer] = true;
        darknodeRegistry.slash(signer, msg.sender, secretRevealSlashPercent);
    }
}