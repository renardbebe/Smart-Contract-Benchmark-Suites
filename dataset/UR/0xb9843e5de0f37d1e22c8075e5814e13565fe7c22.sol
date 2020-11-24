 

 

pragma solidity 0.5.7;

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

contract MultiOwnable {

    mapping (address => bool) _owner;

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    function isOwner(address addr) public view returns (bool) {
        return _owner[addr];
    }

}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

}

 
contract Pausable {
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
        require(!_paused);
        _;
    }

    modifier whenPaused() {
        require(_paused);
        _;
    }

    function pause() public whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
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

 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external;
}

 
contract LBNToken is ERC20Pausable, MultiOwnable {

     
    string private _name = "Lucky Block Network";
     
    string private _symbol = "LBN";
     
    uint8 private _decimals = 18;

     
    uint256 public constant INITIAL_SUPPLY = 99990000 * (10 ** 18);

     
    uint8 public consensusValue = 1;

     
    struct Proposal {
         
        uint8 votes;
         
        uint256 count;
         
        mapping (uint256 => mapping (address => bool)) voted;
    }

     
    mapping (address => bool) _owner;

     
    bool public mintingIsFinished;

     
    modifier isNotFinished {
        require(!mintingIsFinished);
        _;
    }

     
    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

     
    event LogProposal(string indexed method, address param1, address param2, uint256 param3, string param4, address indexed voter, uint8 votes, uint8 consensusValue);
    event LogAction(string indexed method, address param1, address param2, uint256 param3, string param4);

     
    constructor(address[] memory owners, address recipient) public {

        for (uint8 i = 0; i < 5; i++) {
            _owner[owners[i]] = true;
        }

        _mint(recipient, INITIAL_SUPPLY);

    }

     
    function _vote(Proposal storage props, string memory method, address param1, address param2, uint256 param3, string memory param4) internal returns(bool) {

         
        if (props.votes == 0) {
            props.count++;
        }

         
        if (!props.voted[props.count][msg.sender]) {
            props.votes++;
            props.voted[props.count][msg.sender] = true;
            emit LogProposal(method, param1, param2, param3, param4, msg.sender, props.votes, consensusValue);
        }

         
        if (props.votes >= consensusValue) {
            props.votes = 0;
            emit LogAction(method, param1, param2, param3, param4);
            return true;
        }

    }

     
    mapping (address => mapping(address => Proposal)) public ownerProp;

     
    function changeOwner(address previousOwner, address newOwner) public onlyOwner {
        require(isOwner(previousOwner) && !isOwner(newOwner));

        if (_vote(ownerProp[previousOwner][newOwner], "changeOwner", previousOwner, newOwner, 0, "")) {
            _owner[previousOwner] = false;
            _owner[newOwner] = true;
        }

    }

     
    mapping (uint8 => Proposal) public consProp;

     
    function setConsensusValue(uint8 newConsensusValue) public onlyOwner {

        if (_vote(consProp[newConsensusValue], "setConsensusValue", address(0), address(0), newConsensusValue, "")) {
            consensusValue = newConsensusValue;
        }

    }

     
    Proposal public finMintProp;

     
    function finalizeMinting() public onlyOwner {

        if (_vote(finMintProp, "finalizeMinting", address(0), address(0), 0, "")) {
            mintingIsFinished = true;
        }

    }

     
    mapping (address => mapping (uint256 => mapping (string => Proposal))) public mintProp;

     
    function mint(address to, uint256 value) public isNotFinished onlyOwner returns (bool) {

        if (_vote(mintProp[to][value]["mint"], "mint", to, address(0), value, "")) {
            _mint(to, value);
        }

    }

     
    mapping (address => mapping (uint256 => mapping (string => Proposal))) public burnProp;


     
    function burnFrom(address from, uint256 value) public onlyOwner {

        if (_vote(burnProp[from][value]["burnFrom"], "burnFrom", from, address(0), value, "")) {
            _burn(from, value);
        }

    }

     
    Proposal public pauseProp;

     
    function pause() public onlyOwner {

        if (_vote(pauseProp, "pause", address(0), address(0), 0, "")) {
            super.pause();
        }

    }

     
    Proposal public unpauseProp;

     
    function unpause() public onlyOwner {

        if (_vote(unpauseProp, "unpause", address(0), address(0), 0, "")) {
            super.unpause();
        }

    }

     
    mapping (string => mapping (string => Proposal)) public nameProp;

     
    function changeName(string memory newName) public onlyOwner {

        if (_vote(nameProp[newName]["name"], "changeName", address(0), address(0), 0, newName)) {
            _name = newName;
        }

    }

     
    mapping (string => mapping (string => Proposal)) public symbolProp;

     
    function changeSymbol(string memory newSymbol) public onlyOwner {

        if (_vote(symbolProp[newSymbol]["symbol"], "changeSymbol", address(0), address(0), 0, newSymbol)) {
            _symbol = newSymbol;
        }

    }

     
    function approveAndCall(address spender, uint256 amount, bytes calldata extraData) external returns (bool) {
        require(approve(spender, amount));

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

     
    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {

        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);

    }

     
    function isOwner(address addr) public view returns (bool) {
        return _owner[addr];
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