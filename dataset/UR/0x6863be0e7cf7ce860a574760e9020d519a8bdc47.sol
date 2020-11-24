 

 

pragma solidity 0.4.18;


 
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


 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) internal balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}


 
contract BurnableToken is BasicToken {

    using SafeMath for uint256;

     
    address public constant BURN_ADDRESS = address(0x0);

     
    event Burned(address indexed from, uint256 amount);

    modifier onlyHolder(uint256 amount) {
        require(balances[msg.sender] >= amount);
        _;
    }

     
    function burn(uint256 amount)
        public
        onlyHolder(amount)
    {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);

        Burned(msg.sender, amount);
        Transfer(msg.sender, BURN_ADDRESS, amount);
    }
}


 
contract DescriptiveToken is BasicToken, Ownable {

    string public name;
    string public symbol;
    bool public isDescriptionFinalized;
    uint256 public decimals = 18;

    function DescriptiveToken(
        string _name,
        string _symbol
    )
        public
        onlyNotEmpty(_name)
        onlyNotEmpty(_symbol)
    {
        name = _name;
        symbol = _symbol;
    }

     
    event DescriptionChanged(string name, string symbol);

     
    event DescriptionFinalized();

    modifier onlyNotEmpty(string str) {
        require(bytes(str).length > 0);
        _;
    }

    modifier onlyDescriptionNotFinalized() {
        require(!isDescriptionFinalized);
        _;
    }

     
    function changeDescription(string _name, string _symbol)
        public
        onlyOwner
        onlyDescriptionNotFinalized
        onlyNotEmpty(_name)
        onlyNotEmpty(_symbol)
    {
        name = _name;
        symbol = _symbol;

        DescriptionChanged(name, symbol);
    }

     
    function finalizeDescription()
        public
        onlyOwner
        onlyDescriptionNotFinalized
    {
        isDescriptionFinalized = true;

        DescriptionFinalized();
    }
}


 
contract MintableToken is BasicToken, Ownable {

    using SafeMath for uint256;

     
    address public constant MINT_ADDRESS = address(0x0);

     
    bool public mintingFinished;

     
    mapping (address => bool) public isMintingManager;

     
    event Minted(address indexed to, uint256 amount);

     
    event MintingManagerApproved(address addr);

     
    event MintingManagerRevoked(address addr);

     
    event MintingFinished();

    modifier onlyMintingManager(address addr) {
        require(isMintingManager[addr]);
        _;
    }

    modifier onlyMintingNotFinished {
        require(!mintingFinished);
        _;
    }

     
    function approveMintingManager(address addr)
        public
        onlyOwner
        onlyMintingNotFinished
    {
        isMintingManager[addr] = true;

        MintingManagerApproved(addr);
    }

     
    function revokeMintingManager(address addr)
        public
        onlyOwner
        onlyMintingManager(addr)
        onlyMintingNotFinished
    {
        delete isMintingManager[addr];

        MintingManagerRevoked(addr);
    }

     
    function mint(address to, uint256 amount)
        public
        onlyMintingManager(msg.sender)
        onlyMintingNotFinished
    {
        totalSupply = totalSupply.add(amount);
        balances[to] = balances[to].add(amount);

        Minted(to, amount);
        Transfer(MINT_ADDRESS, to, amount);
    }

     
    function finishMinting()
        public
        onlyOwner
        onlyMintingNotFinished
    {
        mintingFinished = true;

        MintingFinished();
    }
}


 
contract CappedMintableToken is MintableToken {

     
    uint256 public maxSupply;

    function CappedMintableToken(uint256 _maxSupply)
        public
        onlyNotZero(_maxSupply)
    {
        maxSupply = _maxSupply;
    }

    modifier onlyNotZero(uint256 value) {
        require(value != 0);
        _;
    }

    modifier onlyNotExceedingMaxSupply(uint256 supply) {
        require(supply <= maxSupply);
        _;
    }

     
    function mint(address to, uint256 amount)
        public
        onlyNotExceedingMaxSupply(totalSupply.add(amount))
    {
        return MintableToken.mint(to, amount);
    }
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


 
contract ReleasableToken is StandardToken, Ownable {

     
    bool public released;

     
    address public releaseManager;

     
    mapping (address => bool) public isTransferManager;

     
    event ReleaseManagerSet(address addr);

     
    event TransferManagerApproved(address addr);

     
    event TransferManagerRevoked(address addr);

     
    event Released();

     
    modifier onlyTransferableFrom(address from) {
        if (!released) {
            require(isTransferManager[from]);
        }

        _;
    }

     
    modifier onlyTransferManager(address addr) {
        require(isTransferManager[addr]);
        _;
    }

     
    modifier onlyReleaseManager() {
        require(msg.sender == releaseManager);
        _;
    }

     
    modifier onlyReleased() {
        require(released);
        _;
    }

     
    modifier onlyNotReleased() {
        require(!released);
        _;
    }

     
    function setReleaseManager(address addr)
        public
        onlyOwner
        onlyNotReleased
    {
        releaseManager = addr;

        ReleaseManagerSet(addr);
    }

     
    function approveTransferManager(address addr)
        public
        onlyOwner
        onlyNotReleased
    {
        isTransferManager[addr] = true;

        TransferManagerApproved(addr);
    }

     
    function revokeTransferManager(address addr)
        public
        onlyOwner
        onlyTransferManager(addr)
        onlyNotReleased
    {
        delete isTransferManager[addr];

        TransferManagerRevoked(addr);
    }

     
    function release()
        public
        onlyReleaseManager
        onlyNotReleased
    {
        released = true;

        Released();
    }

     
    function transfer(
        address to,
        uint256 amount
    )
        public
        onlyTransferableFrom(msg.sender)
        returns (bool)
    {
        return super.transfer(to, amount);
    }

     
    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        public
        onlyTransferableFrom(from)
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }
}


 
contract OnLiveToken is DescriptiveToken, ReleasableToken, CappedMintableToken, BurnableToken {

    function OnLiveToken(
        string _name,
        string _symbol,
        uint256 _maxSupply
    )
        public
        DescriptiveToken(_name, _symbol)
        CappedMintableToken(_maxSupply)
    {
        owner = msg.sender;
    }
}