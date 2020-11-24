 
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


contract HashedTimelockGXC is IHashedTimelock {
    struct Htlc {
        address sender;
        address recipient;
        address tokenContract;
        uint amount;
        bytes32 hashlock;
        uint timelock;
        bool withdrawn;
        bool refunded;
        bytes32 preimage;
        bytes32 data;
    }

    struct Config {
        address target;
        uint minAmount;
        uint minDuration;
    }

    mapping(bytes32 => Htlc) internal contracts;
    mapping(address => Config) internal configs;

    event LogHtlcNew(
        bytes32 indexed contractId,
        address sender,
        address recipient,
        address tokenContract,
        uint amount,
        bytes32 hashlock,
        uint timelock,
        bytes32 indexed data
    );
    event LogHtlcWithdraw(bytes32 indexed contractId);
    event LogHtlcRefund(bytes32 indexed contractId);

    modifier configured(address tokenContract) {
        require(configs[tokenContract].target != address(0x0), "not configured");
        _;
    }

    function getConfig(address tokenContract) external view returns (address, uint, uint) {
        if (configs[tokenContract].target == address(0x0))
            return (address(0x0), 0, 0);
        return (configs[tokenContract].target, configs[tokenContract].minAmount, configs[tokenContract].minDuration);
    }

    function setConfig(address tokenContract, address target, uint minAmount, uint minDuration) external {
        require(address(msg.sender) == Ownable(tokenContract).owner(), "msg.sender must be token owner");

        configs[tokenContract].target = target;
        configs[tokenContract].minAmount = minAmount;
        configs[tokenContract].minDuration = minDuration;
    }

    modifier contractExists(bytes32 contractId) {
        require(haveContract(contractId), "contractId does not exist");
        _;
    }

    modifier hashlockMatches(bytes32 contractId, bytes32 preimage) {
        require(contracts[contractId].hashlock == sha256(abi.encodePacked(preimage)), "hashlock does not match");
        _;
    }

    modifier withdrawable(bytes32 contractId) {
        require(contracts[contractId].withdrawn == false, "withdrawable: already withdrawn");
        require(contracts[contractId].timelock > now, "withdrawable: timelock is expired");
        _;
    }

    modifier refundable(bytes32 contractId) {
        require(contracts[contractId].refunded == false, "refundable: already refunded");
        require(contracts[contractId].withdrawn == false, "refundable: already withdrawn");
        require(contracts[contractId].timelock <= now, "refundable: timelock not yet passed");
        _;
    }

    function newContract(
        address recipient,
        address tokenContract,
        uint amount,
        bytes32 hashlock,
        uint timelock,
        bytes32 data
    )
        external
        configured(tokenContract)
        returns (bytes32 contractId)
    {
        Config storage c = configs[tokenContract];

         

         
        require(amount >= c.minAmount, "token amount must be greater than configured minAmount");
        require(IERC20(tokenContract).allowance(msg.sender, address(this)) >= amount, "token allowance must be equal or greater than amount");

         
        uint minDuration = (msg.sender == c.target) ? 0 : c.minDuration;
        require(timelock >= now + minDuration, "timelock expiration is too early");

         
        require(recipient == c.target || msg.sender == c.target, "invalid target");

        contractId = sha256(abi.encodePacked(msg.sender, recipient, tokenContract, amount, hashlock, timelock, data));

        require(!haveContract(contractId), "contractId already exists");
        require(IERC20(tokenContract).transferFrom(msg.sender, address(this), amount), "failed to transfer token from msg.sender");

        contracts[contractId] = Htlc(msg.sender, recipient, tokenContract, amount, hashlock, timelock, false, false, 0x0, data);
        emit LogHtlcNew(contractId, msg.sender, recipient, tokenContract, amount, hashlock, timelock, data);
    }

    function withdraw(bytes32 contractId, bytes32 preimage)
        external
        contractExists(contractId)
        hashlockMatches(contractId, preimage)
        withdrawable(contractId)
        returns (bool)
    {
        Htlc storage c = contracts[contractId];
        c.preimage = preimage;
        c.withdrawn = true;
        IERC20(c.tokenContract).transfer(c.recipient, c.amount);
        emit LogHtlcWithdraw(contractId);
        return true;
    }

    function refund(bytes32 contractId)
        external
        contractExists(contractId)
        refundable(contractId)
        returns (bool)
    {
        Htlc storage c = contracts[contractId];
        c.refunded = true;
        IERC20(c.tokenContract).transfer(c.sender, c.amount);
        emit LogHtlcRefund(contractId);
        return true;
    }

    function getContract(bytes32 contractId)
        public
        view
        returns (
            address sender,
            address recipient,
            address tokenContract,
            uint amount,
            bytes32 hashlock,
            uint timelock,
            bool withdrawn,
            bool refunded,
            bytes32 preimage,
            bytes32 data
        )
    {
        if (haveContract(contractId) == false)
            return (address(0x0), address(0x0), address(0x0), 0, 0, 0, false, false, 0x0, 0x0);
        Htlc storage c = contracts[contractId];
        return (c.sender, c.recipient, c.tokenContract, c.amount, c.hashlock, c.timelock, c.withdrawn, c.refunded, c.preimage, c.data);
    }

    function haveContract(bytes32 contractId) public view returns (bool exists) {
        exists = (contracts[contractId].sender != address(0x0));
    }
}
