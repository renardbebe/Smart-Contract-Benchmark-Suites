 

pragma solidity ^0.5.11;


contract Ownable {
  address payable public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



  constructor() public {
    owner = msg.sender;
  }



  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }



  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Destructible is Ownable {

  constructor() public payable { }


  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address payable _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

interface Conference {

    event AdminGranted(address indexed grantee);
    event AdminRevoked(address indexed grantee);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event RegisterEvent(address addr, uint256 index);
    event FinalizeEvent(uint256[] maps, uint256 payout, uint256 endedAt);
    event WithdrawEvent(address addr, uint256 payout);
    event CancelEvent(uint256 endedAt);
    event ClearEvent(address addr, uint256 leftOver);
    event UpdateParticipantLimit(uint256 limit);



    function owner() view external returns (address);

    function name() view external returns (string memory);
    function deposit() view external returns (uint256);
    function limitOfParticipants() view external returns (uint256);
    function registered() view external returns (uint256);
    function ended() view external returns (bool);
    function cancelled() view external returns (bool);
    function endedAt() view external returns (uint256);
    function totalAttended() view external returns (uint256);
    function coolingPeriod() view external returns (uint256);
    function payoutAmount() view external returns (uint256);
    function participants(address participant) view external returns (
        uint256 index,
        address payable addr,
        bool paid
    );
    function participantsIndex(uint256) view external returns(address);


    function transferOwnership(address payable newOwner) external;

    function grant(address[] calldata newAdmins) external;
    function revoke(address[] calldata oldAdmins) external;
    function getAdmins() external view returns(address[] memory);
    function numOfAdmins() external view returns(uint);
    function isAdmin(address admin) external view returns(bool);


    function register() external payable;
    function withdraw() external;
    function totalBalance() view external returns (uint256);
    function isRegistered(address _addr) view external returns (bool);
    function isAttended(address _addr) external view returns (bool);
    function isPaid(address _addr) external view returns (bool);
    function cancel() external;
    function clear() external;
    function setLimitOfParticipants(uint256 _limitOfParticipants) external;
    function changeName(string calldata _name) external;
    function changeDeposit(uint256 _deposit) external;
    function finalize(uint256[] calldata _maps) external;
    function tokenAddress() external view returns (address);
}

interface DeployerInterface {
    function deploy(
        string calldata _name,
        uint256 _deposit,
        uint _limitOfParticipants,
        uint _coolingPeriod,
        address payable _ownerAddress,
        address _tokenAddress
    )external returns(Conference c);
}

contract Deployer is Destructible {
    DeployerInterface ethDeployer;
    DeployerInterface erc20Deployer;

    constructor(address _ethDeployer, address _erc20Deployer) public {
        ethDeployer = DeployerInterface(_ethDeployer);
        erc20Deployer = DeployerInterface(_erc20Deployer);
    }

    event NewParty(
        address indexed deployedAddress,
        address indexed deployer
    );


    function deploy(
        string calldata _name,
        uint256 _deposit,
        uint _limitOfParticipants,
        uint _coolingPeriod,
        address _tokenAddress
    ) external {
        Conference c;
        if(_tokenAddress != address(0)){
            c = erc20Deployer.deploy(
                _name,
                _deposit,
                _limitOfParticipants,
                _coolingPeriod,
                msg.sender,
                _tokenAddress
            );
        }else{
            c = ethDeployer.deploy(
                _name,
                _deposit,
                _limitOfParticipants,
                _coolingPeriod,
                msg.sender,
                address(0)
            );
        }
        emit NewParty(address(c), msg.sender);
    }
}