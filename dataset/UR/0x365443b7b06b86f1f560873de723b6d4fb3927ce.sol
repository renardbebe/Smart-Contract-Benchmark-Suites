 

pragma solidity ^0.4.24;


 
contract Version {
    string public semanticVersion;

     
     
    constructor(string _version) internal {
        semanticVersion = _version;
    }
}


 
contract Factory is Version {
    event FactoryAddedContract(address indexed _contract);

    modifier contractHasntDeployed(address _contract) {
        require(contracts[_contract] == false);
        _;
    }

    mapping(address => bool) public contracts;

    constructor(string _version) internal Version(_version) {}

    function hasBeenDeployed(address _contract) public constant returns (bool) {
        return contracts[_contract];
    }

    function addContract(address _contract)
        internal
        contractHasntDeployed(_contract)
        returns (bool)
    {
        contracts[_contract] = true;
        emit FactoryAddedContract(_contract);
        return true;
    }
}


 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


 
interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract SpendableWallet is Ownable {
    ERC20 public token;

    event ClaimedTokens(
        address indexed _token,
        address indexed _controller,
        uint256 _amount
    );

    constructor(address _token, address _owner) public {
        token = ERC20(_token);
        owner = _owner;
    }

    function spend(address _to, uint256 _amount) public onlyOwner {
        token.transfer(_to, _amount);
    }

     
     
     
     
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }
}


contract SpendableWalletFactory is Factory {
     
    address[] public spendableWallets;

    constructor() public Factory("1.0.3") {}

     
    function newPaymentAddress(address _token, address _owner)
        public
        returns(address newContract)
    {
        SpendableWallet spendableWallet = new SpendableWallet(_token, _owner);
        spendableWallets.push(spendableWallet);
        addContract(spendableWallet);
        return spendableWallet;
    }
}