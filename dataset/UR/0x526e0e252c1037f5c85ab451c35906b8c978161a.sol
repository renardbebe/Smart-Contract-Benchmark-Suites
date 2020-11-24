 

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


 
contract IcoToken {
    uint256 public decimals;

    function transfer(address to, uint256 amount) public;
    function mint(address to, uint256 amount) public;
    function burn(uint256 amount) public;

    function balanceOf(address who) public view returns (uint256);
}


 
contract IcoCrowdsale is Ownable {

    using SafeMath for uint256;

     
    struct Tier {
         
        uint256 startBlock;
         
        uint256 price;
    }

     
    address public wallet;

     
    IcoToken public token;

     
    uint256 public minValue;

     
    mapping (bytes32 => bool) public isContributionRegistered;

     
    Tier[] private tiers;

     
    uint256 public endBlock;

    modifier onlySufficientValue(uint256 value) {
        require(value >= minValue);
        _;
    }

    modifier onlyUniqueContribution(bytes32 id) {
        require(!isContributionRegistered[id]);
        _;
    }

    modifier onlyActive() {
        require(isActive());
        _;
    }

    modifier onlyFinished() {
        require(isFinished());
        _;
    }

    modifier onlyScheduledTiers() {
        require(tiers.length > 0);
        _;
    }

    modifier onlyNotFinalized() {
        require(!isFinalized());
        _;
    }

    modifier onlySubsequentBlock(uint256 startBlock) {
        if (tiers.length > 0) {
            require(startBlock > tiers[tiers.length - 1].startBlock);
        }
        _;
    }

    modifier onlyNotZero(uint256 value) {
        require(value != 0);
        _;
    }

    modifier onlyValid(address addr) {
        require(addr != address(0));
        _;
    }

    function IcoCrowdsale(
        address _wallet,
        IcoToken _token,
        uint256 _minValue
    )
        public
        onlyValid(_wallet)
        onlyValid(_token)
    {
        wallet = _wallet;
        token = _token;
        minValue = _minValue;
    }

     
    event ContributionAccepted(address indexed contributor, uint256 value, uint256 amount);

     
    event ContributionRegistered(bytes32 indexed id, address indexed contributor, uint256 amount);

     
    event TierScheduled(uint256 startBlock, uint256 price);

     
    event Finalized(uint256 endBlock, uint256 availableAmount);

     
    event RemainsBurned(uint256 burnedAmount);

     
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

        token.transfer(contributor, amount);

        ContributionRegistered(id, contributor, amount);
    }

     
    function scheduleTier(uint256 _startBlock, uint256 _price)
        public
        onlyOwner
        onlyNotFinalized
        onlySubsequentBlock(_startBlock)
        onlyNotZero(_startBlock)
        onlyNotZero(_price)
    {
        tiers.push(
            Tier({
                startBlock: _startBlock,
                price: _price
            })
        );

        TierScheduled(_startBlock, _price);
    }

     
    function finalize(uint256 _endBlock, uint256 _availableAmount)
        public
        onlyOwner
        onlyNotFinalized
        onlyScheduledTiers
        onlySubsequentBlock(_endBlock)
        onlyNotZero(_availableAmount)
    {
        endBlock = _endBlock;

        token.mint(this, _availableAmount);

        Finalized(_endBlock, _availableAmount);
    }

     
    function burnRemains()
        public
        onlyOwner
        onlyFinished
    {
        uint256 amount = availableAmount();

        token.burn(amount);

        RemainsBurned(amount);
    }

     
    function calculateContribution(uint256 value) public view returns (uint256) {
        uint256 price = currentPrice();
        if (price > 0) {
            return value.mul(10 ** token.decimals()).div(price);
        }

        return 0;
    }

     
    function getTierId(uint256 blockNumber) public view returns (uint256) {
        for (uint256 i = tiers.length - 1; i >= 0; i--) {
            if (blockNumber >= tiers[i].startBlock) {
                return i;
            }
        }

        return 0;
    }

     
    function currentPrice() public view returns (uint256) {
        if (tiers.length > 0) {
            uint256 id = getTierId(block.number);
            return tiers[id].price;
        }

        return 0;
    }

     
    function currentTierId() public view returns (uint256) {
        return getTierId(block.number);
    }

     
    function availableAmount() public view returns (uint256) {
        return token.balanceOf(this);
    }

     
    function listTiers()
        public
        view
        returns (uint256[] startBlocks, uint256[] endBlocks, uint256[] prices)
    {
        startBlocks = new uint256[](tiers.length);
        endBlocks = new uint256[](tiers.length);
        prices = new uint256[](tiers.length);

        for (uint256 i = 0; i < tiers.length; i++) {
            startBlocks[i] = tiers[i].startBlock;
            prices[i] = tiers[i].price;

            if (i + 1 < tiers.length) {
                endBlocks[i] = tiers[i + 1].startBlock - 1;
            } else {
                endBlocks[i] = endBlock;
            }
        }
    }

     
    function isActive() public view returns (bool) {
        return
            tiers.length > 0 &&
            block.number >= tiers[0].startBlock &&
            block.number <= endBlock;
    }

     
    function isFinalized() public view returns (bool) {
        return endBlock > 0;
    }

     
    function isFinished() public view returns (bool) {
        return endBlock > 0 && block.number > endBlock;
    }

    function acceptContribution(address contributor, uint256 value)
        private
        onlyActive
        onlyValid(contributor)
        onlySufficientValue(value)
        returns (uint256)
    {
        uint256 amount = calculateContribution(value);
        token.transfer(contributor, amount);

        wallet.transfer(value);

        ContributionAccepted(contributor, value, amount);

        return amount;
    }
}