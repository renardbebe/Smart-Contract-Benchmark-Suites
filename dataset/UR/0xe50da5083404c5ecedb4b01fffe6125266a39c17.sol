 

pragma solidity ^0.4.24;


 
 
interface ERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}


 
 
interface ERC677 {

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    function transferAndCall(address to, uint256 value, bytes data) external returns (bool);
}


 
 
interface ERC677Bridgeable {

    event Mint(address indexed receiver, uint256 value);
    event Burn(address indexed burner, uint256 value);

    function mint(address receiver, uint256 value) external returns (bool);
    function burn(uint256 value) external;
    function claimTokens(address token, address to) external;
}


 
 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


 
 
 
contract SafeOwnable {

     

    event OwnershipProposed(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     

     
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
     
    function proposeOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0) && newOwner != _owner);
        _ownerCandidate = newOwner;
        emit OwnershipProposed(_owner, _ownerCandidate);
    }

     
    function acceptOwnership() public onlyOwnerCandidate {
        emit OwnershipTransferred(_owner, _ownerCandidate);
        _owner = _ownerCandidate;
        _ownerCandidate = address(0);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    function ownerCandidate() public view returns (address) {
        return _ownerCandidate;
    }

     

     
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

     
    modifier onlyOwnerCandidate() {
        require(msg.sender == _ownerCandidate);
        _;
    }

     

    address internal _owner;
    address internal _ownerCandidate;
}


 
 
contract TokenERC20 is ERC20 {
    using SafeMath for uint256;

     

     
     
     
     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _decreaseAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

     
     
     
     
     
     
     
     
    function approve(address spender, uint256 value) public returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
     
     
     
     
     
    function increaseAllowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _increaseAllowance(msg.sender, spender, value);
        return true;
    }

     
     
     
     
     
     
    function decreaseAllowance(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _decreaseAllowance(msg.sender, spender, value);
        return true;
    }

     
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
     
     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
     
     
     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     

     
     
     
     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(value <= _balances[from]);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
     
     
     
     
     
    function _increaseAllowance(address owner, address spender, uint256 value) internal {
        require(value > 0);
        _allowances[owner][spender] = _allowances[owner][spender].add(value);
        emit Approval(owner, spender, _allowances[owner][spender]);
    }

     
     
     
     
     
     
    function _decreaseAllowance(address owner, address spender, uint256 value) internal {
        require(value > 0 && value <= _allowances[owner][spender]);
        _allowances[owner][spender] = _allowances[owner][spender].sub(value);
        emit Approval(owner, spender, _allowances[owner][spender]);
    }

     
     
     
     
    function _mint(address receiver, uint256 value) internal {
        require(receiver != address(0));
        require(value > 0);
        _balances[receiver] = _balances[receiver].add(value);
        _totalSupply = _totalSupply.add(value);
         
        emit Transfer(address(0), receiver, value);
    }

     
     
     
    function _burn(address burner, uint256 value) internal {
        require(burner != address(0));
        require(value > 0 && value <= _balances[burner]);
        _balances[burner] = _balances[burner].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(burner, address(0), value);
    }

     
     
     
     
    function _burnFrom(address burner, uint256 value) internal {
        _decreaseAllowance(burner, msg.sender, value);
        _burn(burner, value);
    }

     

    uint256 internal _totalSupply;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping(address => uint256)) internal _allowances;
}


 
contract PapyrusToken is SafeOwnable, TokenERC20, ERC677, ERC677Bridgeable {

     

    event ControlByOwnerRevoked();
    event MintableChanged(bool mintable);
    event TransferableChanged(bool transferable);
    event ContractFallbackCallFailed(address from, address to, uint256 value);
    event BridgeContractChanged(address indexed previousBridgeContract, address indexed newBridgeContract);

     

    constructor() public {
        _totalSupply = PPR_INITIAL_SUPPLY;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

     
     
     
     
     
    function transferAndCall(address to, uint256 value, bytes data) external canTransfer returns (bool) {
        require(to != address(this));
        require(super.transfer(to, value));
        emit Transfer(msg.sender, to, value, data);
        if (isContract(to)) {
            require(contractFallback(msg.sender, to, value, data));
        }
        return true;
    }

     
     
     
     
    function transfer(address to, uint256 value) public canTransfer returns (bool) {
        require(super.transfer(to, value));
        if (isContract(to) && !contractFallback(msg.sender, to, value, new bytes(0))) {
            if (to == _bridgeContract) {
                revert();
            }
            emit ContractFallbackCallFailed(msg.sender, to, value);
        }
        return true;
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public canTransfer returns (bool) {
        require(super.transferFrom(from, to, value));
        if (isContract(to) && !contractFallback(from, to, value, new bytes(0))) {
            if (to == _bridgeContract) {
                revert();
            }
            emit ContractFallbackCallFailed(from, to, value);
        }
        return true;
    }

     
     
     
     
    function airdrop(address[] recipients, uint256[] values) public canTransfer returns (bool) {
        require(recipients.length == values.length);
        uint256 senderBalance = _balances[msg.sender];
        for (uint256 i = 0; i < values.length; i++) {
            uint256 value = values[i];
            address to = recipients[i];
            require(senderBalance >= value);
            if (msg.sender != recipients[i]) {
                senderBalance = senderBalance - value;
                _balances[to] += value;
            }
            emit Transfer(msg.sender, to, value);
        }
        _balances[msg.sender] = senderBalance;
        return true;
    }

     
     
     
    function mint(address receiver, uint256 value) public canMint returns (bool) {
        _mint(receiver, value);
        _totalMinted = _totalMinted.add(value);
        emit Mint(receiver, value);
        return true;
    }

     
     
    function burn(uint256 value) public canBurn {
        _burn(msg.sender, value);
        _totalBurnt = _totalBurnt.add(value);
        emit Burn(msg.sender, value);
    }

     
     
     
    function burnByOwner(address burner, uint256 value) public canBurnByOwner {
        _burn(burner, value);
        _totalBurnt = _totalBurnt.add(value);
        emit Burn(burner, value);
    }

     
    function claimTokens(address token, address to) public onlyOwnerOrBridgeContract {
        require(to != address(0));
        if (token == address(0)) {
            to.transfer(address(this).balance);
        } else {
            ERC20 erc20 = ERC20(token);
            uint256 balance = erc20.balanceOf(address(this));
            require(erc20.transfer(to, balance));
        }
    }

     
    function revokeControlByOwner() public onlyOwner {
        require(_controllable);
        _controllable = false;
        emit ControlByOwnerRevoked();
    }

     
    function setMintable(bool mintable) public onlyOwner {
        require(_mintable != mintable);
        _mintable = mintable;
        emit MintableChanged(_mintable);
    }

     
    function setTransferable(bool transferable) public onlyOwner {
        require(_transferable != transferable);
        _transferable = transferable;
        emit TransferableChanged(_transferable);
    }

     
    function setBridgeContract(address bridgeContract) public onlyOwner {
        require(_controllable);
        require(bridgeContract != address(0) && bridgeContract != _bridgeContract && isContract(bridgeContract));
        emit BridgeContractChanged(_bridgeContract, bridgeContract);
        _bridgeContract = bridgeContract;
    }

     
    function renounceOwnership() public pure {
        revert();
    }

     
     
    function controllableByOwner() public view returns (bool) {
        return _controllable;
    }

     
     
    function mintable() public view returns (bool) {
        return _mintable;
    }

     
     
    function transferable() public view returns (bool) {
        return _transferable;
    }

     
     
    function bridgeContract() public view returns (address) {
        return _bridgeContract;
    }

     
     
    function totalMinted() public view returns (uint256) {
        return _totalMinted;
    }

     
     
    function totalBurnt() public view returns (uint256) {
        return _totalBurnt;
    }

     
    function getTokenInterfacesVersion() public pure returns (uint64, uint64, uint64) {
        uint64 major = 2;
        uint64 minor = 0;
        uint64 patch = 0;
        return (major, minor, patch);
    }

     

     
     
    function contractFallback(address from, address receiver, uint256 value, bytes data) private returns (bool) {
        return receiver.call(abi.encodeWithSignature("onTokenTransfer(address,uint256,bytes)", from, value, data));
    }

     
     
    function isContract(address account) private view returns (bool) {
        uint256 codeSize;
        assembly { codeSize := extcodesize(account) }
        return codeSize > 0;
    }

     

    modifier onlyOwnerOrBridgeContract() {
        require(msg.sender == _owner || msg.sender == _bridgeContract);
        _;
    }

    modifier canMint() {
        require(_mintable);
        require(msg.sender == _owner || msg.sender == _bridgeContract);
        _;
    }

    modifier canBurn() {
        require(msg.sender == _owner || msg.sender == _bridgeContract);
        _;
    }

    modifier canBurnByOwner() {
        require(msg.sender == _owner && _controllable);
        _;
    }

    modifier canTransfer() {
        require(_transferable || msg.sender == _owner);
        _;
    }

     

     
    string public constant name = "Papyrus Token";
    string public constant symbol = "PPR";
    uint8 public constant decimals = 18;

     
    bool private _controllable = true;

     
    bool private _mintable = true;

     
    bool private _transferable = false;

     
    address private _bridgeContract;

     
    uint256 private _totalMinted;
     
    uint256 private _totalBurnt;

     
    uint256 private constant PPR_INITIAL_SUPPLY = 10**27;
}