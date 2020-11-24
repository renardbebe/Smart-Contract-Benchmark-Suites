 

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


 
contract Schedulable is Ownable {

     
    uint256 public startBlock;

     
    uint256 public endBlock;

     
    event Scheduled(uint256 startBlock, uint256 endBlock);

    modifier onlyNotZero(uint256 value) {
        require(value != 0);
        _;
    }

    modifier onlyScheduled() {
        require(isScheduled());
        _;
    }

    modifier onlyNotScheduled() {
        require(!isScheduled());
        _;
    }

    modifier onlyActive() {
        require(isActive());
        _;
    }

    modifier onlyNotActive() {
        require(!isActive());
        _;
    }

     
    function schedule(uint256 _startBlock, uint256 _endBlock)
        public
        onlyOwner
        onlyNotScheduled
        onlyNotZero(_startBlock)
        onlyNotZero(_endBlock)
    {
        require(_startBlock < _endBlock);

        startBlock = _startBlock;
        endBlock = _endBlock;

        Scheduled(_startBlock, _endBlock);
    }

     
    function isScheduled() public view returns (bool) {
        return startBlock > 0 && endBlock > 0;
    }

     
    function isActive() public view returns (bool) {
        return block.number >= startBlock && block.number <= endBlock;
    }
}


 
contract Mintable {
    uint256 public decimals;

    function mint(address to, uint256 amount) public;
}


 
contract PreIcoCrowdsale is Schedulable {

    using SafeMath for uint256;

     
    address public wallet;

     
    Mintable public token;

     
    uint256 public availableAmount;

     
    uint256 public price;

     
    uint256 public minValue;

     
    mapping (bytes32 => bool) public isContributionRegistered;

    function PreIcoCrowdsale(
        address _wallet,
        Mintable _token,
        uint256 _availableAmount,
        uint256 _price,
        uint256 _minValue
    )
        public
        onlyValid(_wallet)
        onlyValid(_token)
        onlyNotZero(_availableAmount)
        onlyNotZero(_price)
    {
        wallet = _wallet;
        token = _token;
        availableAmount = _availableAmount;
        price = _price;
        minValue = _minValue;
    }

     
    event ContributionAccepted(address indexed contributor, uint256 value, uint256 amount);

     
    event ContributionRegistered(bytes32 indexed id, address indexed contributor, uint256 amount);

    modifier onlyValid(address addr) {
        require(addr != address(0));
        _;
    }

    modifier onlySufficientValue(uint256 value) {
        require(value >= minValue);
        _;
    }

    modifier onlySufficientAvailableTokens(uint256 amount) {
        require(availableAmount >= amount);
        _;
    }

    modifier onlyUniqueContribution(bytes32 id) {
        require(!isContributionRegistered[id]);
        _;
    }

     
    function () public payable {
        acceptContribution(msg.sender, msg.value);
    }

     
    function contribute(address contributor) public payable returns (uint256) {
        return acceptContribution(contributor, msg.value);
    }

     
    function registerContribution(bytes32 id, address contributor, uint256 amount)
        public
        onlyOwner
        onlyActive
        onlyValid(contributor)
        onlyNotZero(amount)
        onlyUniqueContribution(id)
    {
        isContributionRegistered[id] = true;
        mintTokens(contributor, amount);

        ContributionRegistered(id, contributor, amount);
    }

     
    function calculateContribution(uint256 value) public view returns (uint256) {
        return value.mul(10 ** token.decimals()).div(price);
    }

    function acceptContribution(address contributor, uint256 value)
        private
        onlyActive
        onlyValid(contributor)
        onlySufficientValue(value)
        returns (uint256)
    {
        uint256 amount = calculateContribution(value);
        mintTokens(contributor, amount);

        wallet.transfer(value);

        ContributionAccepted(contributor, value, amount);

        return amount;
    }

    function mintTokens(address to, uint256 amount)
        private
        onlySufficientAvailableTokens(amount)
    {
        availableAmount = availableAmount.sub(amount);
        token.mint(to, amount);
    }
}